import type { PaymentMethod, PaymentStatus } from "@prisma/client";

export interface PaymentStatusResponse {
  id: string;
  invoiceId: string;
  provider: PaymentMethod;
  paymentCode: string | null;
  amount: number;
  status: PaymentStatus;
  paidAt: Date | null;
}
