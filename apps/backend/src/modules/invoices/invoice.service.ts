import { InvoiceStatus, PaymentStatus, Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { toNumber } from "../../common/utils/decimal";
import { toPageMeta, toSkipTake } from "../../common/utils/pagination";
import { prisma } from "../../lib/prisma";
import type {
  AdminListInvoicesQuery,
  ListMyInvoicesQuery,
} from "./invoice.schema";

type InvoiceDatabase = Pick<PrismaClient, "$transaction" | "invoice">;

const invoiceSummarySelect = {
  id: true,
  invoiceNo: true,
  orderId: true,
  status: true,
  customerName: true,
  customerPhone: true,
  customerAddress: true,
  subtotalAmount: true,
  discountAmount: true,
  taxAmount: true,
  shippingFee: true,
  grandTotal: true,
  issuedAt: true,
  paidAt: true,
  order: { select: { orderNumber: true, paymentMethod: true } },
  user: { select: { email: true } },
  payments: {
    orderBy: { createdAt: "desc" as const },
    take: 1,
    select: { id: true, status: true },
  },
} satisfies Prisma.InvoiceSelect;

const invoiceDetailSelect = {
  ...invoiceSummarySelect,
  items: {
    orderBy: { name: "asc" as const },
    select: {
      id: true,
      productId: true,
      name: true,
      sku: true,
      unitPrice: true,
      quantity: true,
      discountAmount: true,
      taxableAmount: true,
      taxRate: true,
      taxAmount: true,
      lineTotal: true,
    },
  },
} satisfies Prisma.InvoiceSelect;

type InvoiceSummaryRow = Prisma.InvoiceGetPayload<{ select: typeof invoiceSummarySelect }>;
type InvoiceDetailRow = Prisma.InvoiceGetPayload<{ select: typeof invoiceDetailSelect }>;

const notFound = () =>
  new AppError(404, ErrorCodes.INVOICE_NOT_FOUND, "Không tìm thấy hóa đơn.");

const paymentStatusOf = (invoice: InvoiceSummaryRow): PaymentStatus => {
  if (invoice.status === InvoiceStatus.PAID) return PaymentStatus.PAID;
  const latest = invoice.payments[0];
  if (latest) return latest.status;
  return invoice.status === InvoiceStatus.CANCELLED
    ? PaymentStatus.FAILED
    : PaymentStatus.PENDING;
};

// Trả cả tên field theo spec lẫn alias admin app đang đọc (orderCode, subtotal, totalAmount).
const mapSummary = (invoice: InvoiceSummaryRow) => {
  const subtotalAmount = toNumber(invoice.subtotalAmount);
  const grandTotal = toNumber(invoice.grandTotal);
  return {
    id: invoice.id,
    invoiceNumber: invoice.invoiceNo,
    orderId: invoice.orderId,
    orderCode: invoice.order.orderNumber,
    status: invoice.status,
    paymentStatus: paymentStatusOf(invoice),
    paymentMethod: invoice.order.paymentMethod,
    paymentId: invoice.payments[0]?.id ?? null,
    customerName: invoice.customerName,
    customerPhone: invoice.customerPhone,
    customerAddress: invoice.customerAddress,
    customerEmail: invoice.user.email,
    subtotalAmount,
    subtotal: subtotalAmount,
    discountAmount: toNumber(invoice.discountAmount),
    taxAmount: toNumber(invoice.taxAmount),
    shippingFee: toNumber(invoice.shippingFee),
    grandTotal,
    totalAmount: grandTotal,
    issuedAt: invoice.issuedAt,
    paidAt: invoice.paidAt,
  };
};

const mapDetail = (invoice: InvoiceDetailRow) => ({
  ...mapSummary(invoice),
  items: invoice.items.map((item) => {
    const lineTotal = toNumber(item.lineTotal);
    return {
      id: item.id,
      productId: item.productId,
      productName: item.name,
      sku: item.sku,
      unitPrice: toNumber(item.unitPrice),
      quantity: item.quantity,
      discountAmount: toNumber(item.discountAmount),
      taxableAmount: toNumber(item.taxableAmount),
      taxRate: toNumber(item.taxRate),
      taxAmount: toNumber(item.taxAmount),
      lineTotal,
      totalPrice: lineTotal,
    };
  }),
});

export class InvoiceService {
  constructor(private readonly db: InvoiceDatabase = prisma) {}

  async listMine(userId: string, query: ListMyInvoicesQuery) {
    return this.list(
      { userId, ...(query.status && { status: query.status }) },
      query
    );
  }

  async getMine(userId: string, invoiceId: string) {
    const invoice = await this.db.invoice.findFirst({
      where: { id: invoiceId, userId },
      select: invoiceDetailSelect,
    });
    if (!invoice) throw notFound();
    return mapDetail(invoice);
  }

  async adminList(query: AdminListInvoicesQuery) {
    const contains = query.search
      ? { contains: query.search, mode: "insensitive" as const }
      : undefined;
    return this.list(
      {
        ...(query.status && { status: query.status }),
        ...(contains && {
          OR: [
            { invoiceNo: contains },
            { customerName: contains },
            { customerPhone: contains },
            { order: { orderNumber: contains } },
          ],
        }),
      },
      query
    );
  }

  async adminGet(invoiceId: string) {
    const invoice = await this.db.invoice.findUnique({
      where: { id: invoiceId },
      select: invoiceDetailSelect,
    });
    if (!invoice) throw notFound();
    return mapDetail(invoice);
  }

  private async list(
    where: Prisma.InvoiceWhereInput,
    query: { page: number; limit: number }
  ) {
    const [invoices, total] = await this.db.$transaction([
      this.db.invoice.findMany({
        where,
        orderBy: [{ issuedAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: invoiceSummarySelect,
      }),
      this.db.invoice.count({ where }),
    ]);
    return { items: invoices.map(mapSummary), meta: toPageMeta(query, total) };
  }
}

export const invoiceService = new InvoiceService();
