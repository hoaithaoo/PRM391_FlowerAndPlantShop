import { randomUUID } from "node:crypto";
import {
  PaymentMethod,
  Prisma,
  PrismaClient,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  calculateDistanceKm,
  calculateShippingFee,
} from "../../common/utils/distance";
import { prisma } from "../../lib/prisma";
import type { CheckoutInput } from "./checkout.schema";
import type { CheckoutResponse } from "./checkout.type";

type CheckoutDatabase = Pick<PrismaClient, "$transaction">;

const MAX_TRANSACTION_ATTEMPTS = 3;
const PAYMENT_EXPIRY_MINUTES = 15;

const checkoutOrderInclude = {
  invoice: {
    include: {
      payments: {
        orderBy: { createdAt: "asc" as const },
        take: 1,
      },
    },
  },
} satisfies Prisma.OrderInclude;

type CheckoutOrder = Prisma.OrderGetPayload<{
  include: typeof checkoutOrderInclude;
}>;

interface CheckoutLine {
  cartItemId: string;
  productId: string;
  name: string;
  sku: string;
  quantity: number;
  unitPrice: Prisma.Decimal;
  subtotal: Prisma.Decimal;
  taxRate: Prisma.Decimal;
  taxAmount: Prisma.Decimal;
  lineTotal: Prisma.Decimal;
}

const toNumber = (value: Prisma.Decimal): number => Number(value.toString());

const isRetryableTransactionError = (error: unknown): boolean =>
  error instanceof Prisma.PrismaClientKnownRequestError &&
  (error.code === "P2034" || error.code === "P2002");

const createReference = (prefix: string): string => {
  const date = new Date().toISOString().slice(0, 10).replaceAll("-", "");
  const suffix = randomUUID().replaceAll("-", "").slice(0, 12).toUpperCase();
  return `${prefix}-${date}-${suffix}`;
};

export class CheckoutService {
  constructor(private readonly db: CheckoutDatabase = prisma) {}

  async checkout(
    userId: string,
    input: CheckoutInput,
    clientIdempotencyKey?: string
  ): Promise<CheckoutResponse> {
    // Namespace caller-provided keys by the authenticated user because the current
    // database constraint is globally unique rather than unique per user.
    const idempotencyKey = `${userId}:${clientIdempotencyKey ?? randomUUID()}`;

    for (let attempt = 1; attempt <= MAX_TRANSACTION_ATTEMPTS; attempt += 1) {
      try {
        return await this.db.$transaction(
          async (tx) => this.runCheckout(tx, userId, input, idempotencyKey),
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable }
        );
      } catch (error) {
        if (!isRetryableTransactionError(error)) throw error;
        if (attempt === MAX_TRANSACTION_ATTEMPTS) {
          throw new AppError(
            409,
            ErrorCodes.CHECKOUT_CONFLICT,
            "Checkout đang bị xung đột với một yêu cầu khác, vui lòng thử lại."
          );
        }
      }
    }

    throw new AppError(
      409,
      ErrorCodes.CHECKOUT_CONFLICT,
      "Checkout đang bị xung đột với một yêu cầu khác, vui lòng thử lại."
    );
  }

  private async runCheckout(
    tx: Prisma.TransactionClient,
    userId: string,
    input: CheckoutInput,
    idempotencyKey: string
  ): Promise<CheckoutResponse> {
    const existingOrder = await tx.order.findUnique({
      where: { idempotencyKey },
      include: checkoutOrderInclude,
    });

    if (existingOrder) {
      this.assertIdempotentReplay(existingOrder, userId, input);
      return this.mapExistingCheckout(existingOrder);
    }

    const cart = await tx.cart.findUnique({
      where: { userId },
      select: {
        id: true,
        items: {
          orderBy: { productId: "asc" },
          select: {
            id: true,
            quantity: true,
            product: {
              select: {
                id: true,
                name: true,
                sku: true,
                price: true,
                taxRate: true,
                stock: true,
                isActive: true,
              },
            },
          },
        },
      },
    });

    if (!cart || cart.items.length === 0) {
      throw new AppError(
        422,
        ErrorCodes.CART_EMPTY,
        "Giỏ hàng đang trống, không thể checkout."
      );
    }

    const lines: CheckoutLine[] = cart.items.map((item) => {
      if (!item.product.isActive || item.product.stock < item.quantity) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_OUT_OF_STOCK,
          `Sản phẩm ${item.product.name} không còn đủ số lượng để checkout.`,
          { productId: item.product.id, availableStock: item.product.stock }
        );
      }

      const subtotal = item.product.price.mul(item.quantity);
      const taxAmount = subtotal
        .mul(item.product.taxRate)
        .div(100)
        .toDecimalPlaces(0);

      return {
        cartItemId: item.id,
        productId: item.product.id,
        name: item.product.name,
        sku: item.product.sku,
        quantity: item.quantity,
        unitPrice: item.product.price,
        subtotal,
        taxRate: item.product.taxRate,
        taxAmount,
        lineTotal: subtotal.add(taxAmount),
      };
    });

    const stores = await tx.store.findMany({
      where: { isActive: true },
      select: { latitude: true, longitude: true },
    });
    if (stores.length === 0) {
      throw new AppError(
        404,
        ErrorCodes.STORE_NOT_FOUND,
        "Hiện tại không có cửa hàng nào có thể xử lý đơn hàng."
      );
    }

    const nearestDistance = stores.reduce((nearest, store) => {
      const distance = calculateDistanceKm(
        input.latitude,
        input.longitude,
        Number(store.latitude.toString()),
        Number(store.longitude.toString())
      );
      return Math.min(nearest, distance);
    }, Number.POSITIVE_INFINITY);
    const shippingFee = new Prisma.Decimal(
      calculateShippingFee(nearestDistance)
    );
    const subtotalAmount = lines.reduce(
      (total, line) => total.add(line.subtotal),
      new Prisma.Decimal(0)
    );
    const taxAmount = lines.reduce(
      (total, line) => total.add(line.taxAmount),
      new Prisma.Decimal(0)
    );
    const grandTotal = subtotalAmount.add(taxAmount).add(shippingFee);

    // Cart items are sorted by product ID, giving concurrent checkouts a stable
    // lock order. Do all read-only pricing work before these updates so row locks
    // are held for as little time as possible.
    for (const line of lines) {
      const stockUpdate = await tx.product.updateMany({
        where: {
          id: line.productId,
          isActive: true,
          stock: { gte: line.quantity },
        },
        data: { stock: { decrement: line.quantity } },
      });
      if (stockUpdate.count !== 1) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_OUT_OF_STOCK,
          `Sản phẩm ${line.name} vừa thay đổi tồn kho, vui lòng kiểm tra lại giỏ hàng.`,
          { productId: line.productId }
        );
      }
    }

    const order = await tx.order.create({
      data: {
        userId,
        orderNumber: createReference("ORD"),
        idempotencyKey,
        paymentMethod: input.paymentMethod,
        totalAmount: grandTotal,
        shippingAddress: input.address,
        shippingLatitude: new Prisma.Decimal(input.latitude.toString()),
        shippingLongitude: new Prisma.Decimal(input.longitude.toString()),
        recipientName: input.receiverName,
        recipientPhone: input.phone,
        note: input.note ?? null,
        items: {
          create: lines.map((line) => ({
            productId: line.productId,
            name: line.name,
            sku: line.sku,
            unitPrice: line.unitPrice,
            quantity: line.quantity,
            subtotal: line.subtotal,
          })),
        },
      },
      select: { id: true, orderNumber: true, status: true },
    });

    const invoice = await tx.invoice.create({
      data: {
        orderId: order.id,
        userId,
        invoiceNo: createReference("INV"),
        customerName: input.receiverName,
        customerPhone: input.phone,
        customerAddress: input.address,
        subtotalAmount,
        discountAmount: new Prisma.Decimal(0),
        taxAmount,
        shippingFee,
        grandTotal,
        items: {
          create: lines.map((line) => ({
            productId: line.productId,
            name: line.name,
            sku: line.sku,
            unitPrice: line.unitPrice,
            quantity: line.quantity,
            discountAmount: new Prisma.Decimal(0),
            taxableAmount: line.subtotal,
            taxRate: line.taxRate,
            taxAmount: line.taxAmount,
            lineTotal: line.lineTotal,
          })),
        },
      },
      select: {
        id: true,
        invoiceNo: true,
        status: true,
        subtotalAmount: true,
        taxAmount: true,
        shippingFee: true,
        grandTotal: true,
      },
    });

    const payment =
      input.paymentMethod === PaymentMethod.SEPAY
        ? await tx.payment.create({
            data: {
              invoiceId: invoice.id,
              paymentCode: createReference("PAY").replaceAll("-", ""),
              provider: PaymentMethod.SEPAY,
              amount: grandTotal,
              expiresAt: new Date(
                Date.now() + PAYMENT_EXPIRY_MINUTES * 60 * 1000
              ),
              // A QR URL requires deployment-specific bank account settings.
              // The payment code is sufficient for the SePay webhook matcher.
              qrUrl: null,
            },
            select: {
              id: true,
              paymentCode: true,
              qrUrl: true,
              status: true,
            },
          })
        : null;

    // Delete only the snapshot items. Items concurrently added after the cart
    // read are not accidentally removed.
    await tx.cartItem.deleteMany({
      where: {
        id: { in: lines.map((line) => line.cartItemId) },
        cartId: cart.id,
      },
    });

    return {
      order: {
        id: order.id,
        orderCode: order.orderNumber,
        status: order.status,
      },
      invoice: {
        id: invoice.id,
        invoiceNumber: invoice.invoiceNo,
        status: invoice.status,
        subtotalAmount: toNumber(invoice.subtotalAmount),
        taxAmount: toNumber(invoice.taxAmount),
        shippingFee: toNumber(invoice.shippingFee),
        grandTotal: toNumber(invoice.grandTotal),
      },
      payment,
    };
  }

  private assertIdempotentReplay(
    order: CheckoutOrder,
    userId: string,
    input: CheckoutInput
  ): void {
    const isSameRequest =
      order.userId === userId &&
      order.paymentMethod === input.paymentMethod &&
      order.shippingAddress === input.address &&
      order.shippingLatitude.equals(input.latitude) &&
      order.shippingLongitude.equals(input.longitude) &&
      order.recipientName === input.receiverName &&
      order.recipientPhone === input.phone &&
      (order.note ?? null) === (input.note ?? null);

    if (!isSameRequest) {
      throw new AppError(
        409,
        ErrorCodes.CHECKOUT_CONFLICT,
        "Idempotency-Key đã được sử dụng cho một yêu cầu checkout khác."
      );
    }
  }

  private mapExistingCheckout(order: CheckoutOrder): CheckoutResponse {
    if (!order.invoice) {
      throw new AppError(
        409,
        ErrorCodes.CHECKOUT_CONFLICT,
        "Dữ liệu checkout trước đó chưa hoàn chỉnh."
      );
    }

    const payment =
      order.paymentMethod === PaymentMethod.SEPAY
        ? order.invoice.payments[0] ?? null
        : null;

    if (order.paymentMethod === PaymentMethod.SEPAY && !payment) {
      throw new AppError(
        409,
        ErrorCodes.CHECKOUT_CONFLICT,
        "Dữ liệu thanh toán của checkout trước đó chưa hoàn chỉnh."
      );
    }

    return {
      order: {
        id: order.id,
        orderCode: order.orderNumber,
        status: order.status,
      },
      invoice: {
        id: order.invoice.id,
        invoiceNumber: order.invoice.invoiceNo,
        status: order.invoice.status,
        subtotalAmount: toNumber(order.invoice.subtotalAmount),
        taxAmount: toNumber(order.invoice.taxAmount),
        shippingFee: toNumber(order.invoice.shippingFee),
        grandTotal: toNumber(order.invoice.grandTotal),
      },
      payment: payment
        ? {
            id: payment.id,
            paymentCode: payment.paymentCode,
            qrUrl: payment.qrUrl,
            status: payment.status,
          }
        : null,
    };
  }
}

export const checkoutService = new CheckoutService();
