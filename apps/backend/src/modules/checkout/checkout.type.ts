import type { InvoiceStatus, OrderStatus, PaymentStatus } from "@prisma/client";

export interface CheckoutResponse {
  order: {
    id: string;
    orderCode: string;
    status: OrderStatus;
  };
  invoice: {
    id: string;
    invoiceNumber: string;
    status: InvoiceStatus;
    subtotalAmount: number;
    taxAmount: number;
    shippingFee: number;
    grandTotal: number;
  };
  payment: {
    id: string;
    paymentCode: string | null;
    qrUrl: string | null;
    status: PaymentStatus;
  } | null;
}
