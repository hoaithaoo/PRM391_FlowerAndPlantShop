import {
  InvoiceStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
  PrismaClient,
  TransferType,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { toNumber } from "../../common/utils/decimal";
import { toPageMeta, toSkipTake } from "../../common/utils/pagination";
import { prisma } from "../../lib/prisma";
import type {
  AdminListPaymentsQuery,
  AdminListSepayTransactionsQuery,
  AdminMatchSepayTransactionInput,
} from "./payment.schema";

type PaymentAdminDatabase = Pick<
  PrismaClient,
  "$transaction" | "payment" | "sepayTransaction"
>;
type Clock = () => Date;

const MATCHABLE_PAYMENT_STATUSES: PaymentStatus[] = [
  PaymentStatus.PENDING,
  PaymentStatus.EXPIRED,
  PaymentStatus.REVIEW,
];

const paymentSelect = {
  id: true,
  invoiceId: true,
  paymentCode: true,
  provider: true,
  amount: true,
  status: true,
  qrUrl: true,
  paidAt: true,
  expiresAt: true,
  createdAt: true,
  invoice: {
    select: {
      invoiceNo: true,
      customerName: true,
      order: { select: { id: true, orderNumber: true } },
    },
  },
} satisfies Prisma.PaymentSelect;

const transactionSelect = {
  id: true,
  sepayTransactionId: true,
  paymentId: true,
  gateway: true,
  accountNumber: true,
  transferType: true,
  transferAmount: true,
  paymentCode: true,
  content: true,
  referenceCode: true,
  transactionDate: true,
  receivedAt: true,
  payment: {
    select: {
      invoice: {
        select: { order: { select: { id: true, orderNumber: true } } },
      },
    },
  },
} satisfies Prisma.SepayTransactionSelect;

type PaymentRow = Prisma.PaymentGetPayload<{ select: typeof paymentSelect }>;
type TransactionRow = Prisma.SepayTransactionGetPayload<{
  select: typeof transactionSelect;
}>;

const mapPayment = (payment: PaymentRow) => ({
  id: payment.id,
  invoiceId: payment.invoiceId,
  invoiceNumber: payment.invoice.invoiceNo,
  orderId: payment.invoice.order.id,
  orderCode: payment.invoice.order.orderNumber,
  customerName: payment.invoice.customerName,
  paymentCode: payment.paymentCode,
  amount: toNumber(payment.amount),
  provider: payment.provider,
  status: payment.status,
  qrUrl: payment.qrUrl,
  paidAt: payment.paidAt,
  expiresAt: payment.expiresAt,
  createdAt: payment.createdAt,
});

// Trả cả field theo spec lẫn alias admin app đang đọc (bankName, amountIn, isMatched...).
const mapTransaction = (transaction: TransactionRow) => {
  const transferAmount = toNumber(transaction.transferAmount);
  const order = transaction.payment?.invoice.order ?? null;
  return {
    id: transaction.id,
    sepayTransactionId: transaction.sepayTransactionId,
    paymentId: transaction.paymentId,
    gateway: transaction.gateway,
    bankName: transaction.gateway,
    accountNumber: transaction.accountNumber,
    transferType: transaction.transferType,
    transferAmount,
    amountIn: transaction.transferType === TransferType.IN ? transferAmount : 0,
    paymentCode: transaction.paymentCode,
    content: transaction.content,
    referenceCode: transaction.referenceCode,
    transactionDate: transaction.transactionDate ?? transaction.receivedAt,
    receivedAt: transaction.receivedAt,
    isMatched: transaction.paymentId !== null,
    matchedOrderId: order?.id ?? null,
    matchedOrderCode: order?.orderNumber ?? null,
  };
};

export class PaymentAdminService {
  constructor(
    private readonly db: PaymentAdminDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async listPayments(query: AdminListPaymentsQuery) {
    // Đồng bộ payment quá hạn trước khi liệt kê để admin không thấy PENDING giả.
    await this.db.payment.updateMany({
      where: { status: PaymentStatus.PENDING, expiresAt: { lte: this.now() } },
      data: { status: PaymentStatus.EXPIRED },
    });

    const contains = query.search
      ? { contains: query.search, mode: "insensitive" as const }
      : undefined;
    const where: Prisma.PaymentWhereInput = {
      ...(query.status && { status: query.status }),
      ...(query.provider && { provider: query.provider }),
      ...(contains && {
        OR: [
          { paymentCode: contains },
          { invoice: { invoiceNo: contains } },
          { invoice: { order: { orderNumber: contains } } },
        ],
      }),
    };

    const [payments, total] = await this.db.$transaction([
      this.db.payment.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: paymentSelect,
      }),
      this.db.payment.count({ where }),
    ]);
    return { items: payments.map(mapPayment), meta: toPageMeta(query, total) };
  }

  async listTransactions(query: AdminListSepayTransactionsQuery) {
    const contains = query.search
      ? { contains: query.search, mode: "insensitive" as const }
      : undefined;
    const where: Prisma.SepayTransactionWhereInput = {
      ...(query.matched !== undefined && {
        paymentId: query.matched ? { not: null } : null,
      }),
      ...(contains && {
        OR: [
          { referenceCode: contains },
          { content: contains },
          { paymentCode: contains },
          { sepayTransactionId: contains },
        ],
      }),
    };

    const [transactions, total] = await this.db.$transaction([
      this.db.sepayTransaction.findMany({
        where,
        orderBy: [{ receivedAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: transactionSelect,
      }),
      this.db.sepayTransaction.count({ where }),
    ]);
    return {
      items: transactions.map(mapTransaction),
      meta: toPageMeta(query, total),
    };
  }

  /**
   * Admin ghép thủ công giao dịch SePay chưa khớp (ví dụ khách ghi sai nội dung CK)
   * vào payment SEPAY của một order. Số tiền phải khớp chính xác.
   */
  async matchTransaction(
    transactionId: string,
    input: AdminMatchSepayTransactionInput
  ) {
    await this.db.$transaction(
      async (tx) => {
        const transaction = await tx.sepayTransaction.findUnique({
          where: { id: transactionId },
          select: {
            id: true,
            paymentId: true,
            transferType: true,
            transferAmount: true,
            paymentCode: true,
          },
        });
        if (!transaction) {
          throw new AppError(
            404,
            ErrorCodes.SEPAY_TRANSACTION_NOT_FOUND,
            "Không tìm thấy giao dịch SePay."
          );
        }
        if (transaction.paymentId) {
          throw new AppError(
            409,
            ErrorCodes.SEPAY_TRANSACTION_ALREADY_MATCHED,
            "Giao dịch này đã được ghép với một thanh toán."
          );
        }
        if (transaction.transferType !== TransferType.IN) {
          throw new AppError(
            409,
            ErrorCodes.PAYMENT_AMOUNT_MISMATCH,
            "Chỉ có thể ghép giao dịch tiền vào."
          );
        }

        const order = await tx.order.findUnique({
          where: { orderNumber: input.orderCode },
          select: {
            id: true,
            userId: true,
            paymentMethod: true,
            invoice: {
              select: {
                id: true,
                invoiceNo: true,
                status: true,
                payments: {
                  where: { provider: PaymentMethod.SEPAY },
                  orderBy: { createdAt: "desc" },
                  take: 1,
                  select: { id: true, amount: true, status: true, paymentCode: true },
                },
              },
            },
          },
        });
        if (!order) {
          throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
        }
        const invoice = order.invoice;
        const payment = invoice?.payments[0];
        if (!invoice || !payment) {
          throw new AppError(
            404,
            ErrorCodes.PAYMENT_NOT_FOUND,
            "Đơn hàng này không có thanh toán SePay."
          );
        }
        if (
          invoice.status !== InvoiceStatus.ISSUED ||
          !MATCHABLE_PAYMENT_STATUSES.includes(payment.status)
        ) {
          throw new AppError(
            409,
            ErrorCodes.TRANSACTION_CONFLICT,
            `Hóa đơn đang ở trạng thái ${invoice.status}, thanh toán ở trạng thái ${payment.status}; không thể ghép.`
          );
        }
        if (!payment.amount.equals(transaction.transferAmount)) {
          throw new AppError(
            409,
            ErrorCodes.PAYMENT_AMOUNT_MISMATCH,
            "Số tiền giao dịch không khớp với số tiền cần thanh toán.",
            {
              expectedAmount: toNumber(payment.amount),
              receivedAmount: toNumber(transaction.transferAmount),
            }
          );
        }

        const paidAt = this.now();
        await tx.sepayTransaction.update({
          where: { id: transaction.id },
          data: {
            paymentId: payment.id,
            paymentCode: transaction.paymentCode ?? payment.paymentCode,
          },
        });
        await tx.payment.update({
          where: { id: payment.id },
          data: { status: PaymentStatus.PAID, paidAt },
        });
        await tx.invoice.update({
          where: { id: invoice.id },
          data: { status: InvoiceStatus.PAID, paidAt },
        });
        await tx.notification.create({
          data: {
            userId: order.userId,
            type: "PAYMENT",
            title: "Thanh toán thành công",
            message: `Thanh toán cho hóa đơn ${invoice.invoiceNo} đã được xác nhận.`,
            data: {
              paymentId: payment.id,
              invoiceId: invoice.id,
              orderId: order.id,
              status: PaymentStatus.PAID,
            },
          },
        });
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable }
    );

    const transaction = await this.db.sepayTransaction.findUniqueOrThrow({
      where: { id: transactionId },
      select: transactionSelect,
    });
    return mapTransaction(transaction);
  }
}

export const paymentAdminService = new PaymentAdminService();
