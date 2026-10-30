import {
  PaymentStatus,
  Prisma,
  PrismaClient,
  TransferType,
} from "@prisma/client";
import { prisma } from "../../lib/prisma";
import type { SepayWebhookInput } from "./sepay-webhook.schema";

type WebhookDatabase = Pick<PrismaClient, "$transaction">;
type Clock = () => Date;

const MAX_TRANSACTION_ATTEMPTS = 3;
const PAYMENT_CODE_PATTERN = /\bPAY\d{8}[A-F0-9]{12}\b/i;

const paymentMatchSelect = {
  id: true,
  invoiceId: true,
  paymentCode: true,
  amount: true,
  status: true,
  expiresAt: true,
  invoice: {
    select: {
      userId: true,
      orderId: true,
      invoiceNo: true,
      status: true,
    },
  },
} satisfies Prisma.PaymentSelect;

type MatchedPayment = Prisma.PaymentGetPayload<{
  select: typeof paymentMatchSelect;
}>;

interface ReviewReason {
  isIncoming: boolean;
  hasExactAmount: boolean;
  isExpired: boolean;
  invoicePayable: boolean;
  receivedAmount: number;
}

export interface SepayWebhookResponse {
  accepted: true;
  transactionId: string;
}

const isRetryableTransactionError = (error: unknown): boolean =>
  error instanceof Prisma.PrismaClientKnownRequestError &&
  (error.code === "P2002" || error.code === "P2034");

const extractPaymentCode = (input: SepayWebhookInput): string | null => {
  for (const candidate of [input.code, input.content]) {
    const match = candidate?.match(PAYMENT_CODE_PATTERN);
    if (match) return match[0].toUpperCase();
  }
  return null;
};

const parseTransactionDate = (value: string | undefined): Date | null => {
  if (!value) return null;
  const normalized = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(value)
    ? `${value.replace(" ", "T")}+07:00`
    : value;
  return new Date(normalized);
};

const toJson = (value: unknown): Prisma.InputJsonValue =>
  JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;

export class SepayWebhookService {
  constructor(
    private readonly db: WebhookDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async process(
    input: SepayWebhookInput,
    rawPayload: unknown = input
  ): Promise<SepayWebhookResponse> {
    for (let attempt = 1; attempt <= MAX_TRANSACTION_ATTEMPTS; attempt += 1) {
      try {
        return await this.db.$transaction(
          async (tx) => this.processTransaction(tx, input, rawPayload),
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable }
        );
      } catch (error) {
        if (
          !isRetryableTransactionError(error) ||
          attempt === MAX_TRANSACTION_ATTEMPTS
        ) {
          throw error;
        }
      }
    }

    throw new Error("Không thể xử lý webhook SePay sau nhiều lần thử.");
  }

  private async processTransaction(
    tx: Prisma.TransactionClient,
    input: SepayWebhookInput,
    rawPayload: unknown
  ): Promise<SepayWebhookResponse> {
    const existing = await tx.sepayTransaction.findUnique({
      where: { sepayTransactionId: input.id },
      select: { sepayTransactionId: true },
    });
    if (existing) return this.accepted(input.id);

    const paymentCode = extractPaymentCode(input);
    const payment = paymentCode
      ? await tx.payment.findUnique({
          where: { paymentCode },
          select: paymentMatchSelect,
        })
      : null;

    await tx.sepayTransaction.create({
      data: {
        sepayTransactionId: input.id,
        paymentId: payment?.id ?? null,
        gateway: input.gateway ?? null,
        transactionDate: parseTransactionDate(input.transactionDate),
        accountNumber: input.accountNumber ?? null,
        transferType: input.transferType as TransferType,
        transferAmount: new Prisma.Decimal(input.transferAmount.toString()),
        paymentCode,
        content: input.content ?? null,
        referenceCode: input.referenceCode ?? null,
        rawPayload: toJson(rawPayload),
      },
      select: { sepayTransactionId: true },
    });

    if (!payment) return this.accepted(input.id);

    const receivedAmount = new Prisma.Decimal(input.transferAmount.toString());
    const isIncoming = input.transferType === TransferType.IN;
    const hasExactAmount = payment.amount.equals(receivedAmount);
    const isExpired =
      payment.status === PaymentStatus.EXPIRED ||
      (payment.expiresAt !== null && payment.expiresAt <= this.now());
    const invoicePayable = payment.invoice.status === "ISSUED";
    const reviewReason: ReviewReason = {
      isIncoming,
      hasExactAmount,
      isExpired,
      invoicePayable,
      receivedAmount: input.transferAmount,
    };

    if (payment.status === PaymentStatus.PENDING) {
      if (isIncoming && hasExactAmount && !isExpired && invoicePayable) {
        await this.markPaid(tx, payment, reviewReason);
      } else {
        await this.markForReview(
          tx,
          payment,
          PaymentStatus.PENDING,
          reviewReason
        );
      }
    } else if (
      payment.status === PaymentStatus.EXPIRED &&
      isIncoming
    ) {
      await this.markForReview(
        tx,
        payment,
        PaymentStatus.EXPIRED,
        reviewReason
      );
    }

    return this.accepted(input.id);
  }

  private async markPaid(
    tx: Prisma.TransactionClient,
    payment: MatchedPayment,
    reviewReason: ReviewReason
  ): Promise<void> {
    const paidAt = this.now();
    const updated = await tx.payment.updateMany({
      where: { id: payment.id, status: PaymentStatus.PENDING },
      data: { status: PaymentStatus.PAID, paidAt },
    });
    if (updated.count === 0) return;

    const invoiceUpdated = await tx.invoice.updateMany({
      where: { id: payment.invoiceId, status: "ISSUED" },
      data: { status: "PAID", paidAt },
    });
    if (invoiceUpdated.count === 0) {
      const downgraded = await tx.payment.updateMany({
        where: { id: payment.id, status: PaymentStatus.PAID, paidAt },
        data: { status: PaymentStatus.REVIEW, paidAt: null },
      });
      if (downgraded.count > 0) {
        await this.createReviewNotification(tx, payment, {
          ...reviewReason,
          invoicePayable: false,
        });
      }
      return;
    }

    await tx.notification.create({
      data: {
        userId: payment.invoice.userId,
        type: "PAYMENT",
        title: "Thanh toán thành công",
        message: `Thanh toán cho hóa đơn ${payment.invoice.invoiceNo} đã được xác nhận.`,
        data: {
          paymentId: payment.id,
          invoiceId: payment.invoiceId,
          orderId: payment.invoice.orderId,
          status: PaymentStatus.PAID,
        },
      },
    });
  }

  private async markForReview(
    tx: Prisma.TransactionClient,
    payment: MatchedPayment,
    currentStatus: "PENDING" | "EXPIRED",
    reason: ReviewReason
  ): Promise<void> {
    const updated = await tx.payment.updateMany({
      where: { id: payment.id, status: currentStatus },
      data: { status: PaymentStatus.REVIEW },
    });
    if (updated.count === 0) return;

    await this.createReviewNotification(tx, payment, reason);
  }

  private async createReviewNotification(
    tx: Prisma.TransactionClient,
    payment: MatchedPayment,
    reason: ReviewReason
  ): Promise<void> {
    await tx.notification.create({
      data: {
        userId: payment.invoice.userId,
        type: "PAYMENT",
        title: "Thanh toán cần kiểm tra",
        message: `Thanh toán cho hóa đơn ${payment.invoice.invoiceNo} đang được kiểm tra.`,
        data: {
          paymentId: payment.id,
          invoiceId: payment.invoiceId,
          orderId: payment.invoice.orderId,
          status: PaymentStatus.REVIEW,
          receivedAmount: reason.receivedAmount,
          expectedAmount: Number(payment.amount.toString()),
          transferType: reason.isIncoming ? "IN" : "OUT",
          amountMatched: reason.hasExactAmount,
          expired: reason.isExpired,
          invoicePayable: reason.invoicePayable,
        },
      },
    });
  }

  private accepted(transactionId: string): SepayWebhookResponse {
    return { accepted: true, transactionId };
  }
}

export const sepayWebhookService = new SepayWebhookService();
