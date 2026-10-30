import { Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import type { PaymentStatusResponse } from "./payment.type";

type PaymentDatabase = Pick<PrismaClient, "$transaction">;
type Clock = () => Date;

const paymentStatusSelect = {
  id: true,
  invoiceId: true,
  provider: true,
  paymentCode: true,
  amount: true,
  status: true,
  paidAt: true,
} satisfies Prisma.PaymentSelect;

export class PaymentService {
  constructor(
    private readonly db: PaymentDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async getStatus(
    userId: string,
    paymentId: string
  ): Promise<PaymentStatusResponse> {
    const currentTime = this.now();
    const payment = await this.db.$transaction(async (tx) => {
      await tx.payment.updateMany({
        where: {
          id: paymentId,
          status: "PENDING",
          expiresAt: { lte: currentTime },
          invoice: { userId },
        },
        data: { status: "EXPIRED" },
      });

      return tx.payment.findFirst({
        where: { id: paymentId, invoice: { userId } },
        select: paymentStatusSelect,
      });
    });

    if (!payment) {
      throw new AppError(
        404,
        ErrorCodes.PAYMENT_NOT_FOUND,
        "Không tìm thấy thanh toán này."
      );
    }

    return {
      id: payment.id,
      invoiceId: payment.invoiceId,
      provider: payment.provider,
      paymentCode: payment.paymentCode,
      amount: Number(payment.amount.toString()),
      status: payment.status,
      paidAt: payment.paidAt,
    };
  }
}

export const paymentService = new PaymentService();
