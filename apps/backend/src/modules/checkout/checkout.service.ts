import { randomUUID } from "node:crypto";
import {
  PaymentMethod,
  Prisma,
  PrismaClient,
  type Voucher,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  calculateDistanceKm,
  calculateShippingFee,
} from "../../common/utils/distance";
import { prisma } from "../../lib/prisma";
import { allocateDiscount } from "../vouchers/voucher-pricing";
import { voucherService } from "../vouchers/voucher.service";
import type { CheckoutInput } from "./checkout.schema";
import type { CheckoutResponse } from "./checkout.type";

type CheckoutDatabase = Pick<PrismaClient, "$transaction">;

const MAX_TRANSACTION_ATTEMPTS = 3;
const PAYMENT_EXPIRY_MINUTES = 15;
// App cho chọn ngày trong 30 ngày tới, cộng thêm khung giờ của ngày cuối.
const MAX_PICKUP_DAYS = 31;

const checkoutOrderInclude = {
  invoice: {
    include: {
      payments: {
        orderBy: { createdAt: "asc" as const },
        take: 1,
      },
    },
  },
  voucherRedemption: {
    select: { code: true },
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
  discountAmount: Prisma.Decimal;
  taxableAmount: Prisma.Decimal;
  taxRate: Prisma.Decimal;
  taxAmount: Prisma.Decimal;
  lineTotal: Prisma.Decimal;
}

const toNumber = (value: Prisma.Decimal | null | undefined): number =>
  value ? Number(value.toString()) : 0;

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

    // 1. Đọc giỏ và kiểm tra tồn kho
    const rawLines = cart.items.map((item) => {
      if (!item.product.isActive || item.product.stock < item.quantity) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_OUT_OF_STOCK,
          `Sản phẩm ${item.product.name} không còn đủ số lượng để checkout.`,
          { productId: item.product.id, availableStock: item.product.stock }
        );
      }

      const subtotal = item.product.price.mul(item.quantity);
      return {
        cartItemId: item.id,
        productId: item.product.id,
        name: item.product.name,
        sku: item.product.sku,
        quantity: item.quantity,
        unitPrice: item.product.price,
        subtotal,
        taxRate: item.product.taxRate,
      };
    });

    const subtotalAmount = rawLines.reduce(
      (total, line) => total.add(line.subtotal),
      new Prisma.Decimal(0)
    );

    // 2. Nếu có voucherCode: tìm voucher và kiểm tra bằng hàm dùng chung
    let voucher: Voucher | null = null;
    let discountAmount = new Prisma.Decimal(0);

    if (input.voucherCode) {
      voucher = await tx.voucher.findUnique({
        where: { code: input.voucherCode },
      });

      if (!voucher) {
        throw new AppError(
          404,
          ErrorCodes.VOUCHER_NOT_FOUND,
          "Mã voucher không tồn tại."
        );
      }

      const evaluation = await voucherService.evaluateVoucher(
        voucher,
        userId,
        subtotalAmount,
        new Date(),
        tx
      );

      if (!evaluation.eligible) {
        const statusCode =
          evaluation.reasonCode === ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET
            ? 422
            : evaluation.reasonCode === ErrorCodes.VOUCHER_NOT_FOUND
            ? 404
            : 409;

        throw new AppError(
          statusCode,
          evaluation.reasonCode ?? ErrorCodes.VOUCHER_NOT_FOUND,
          evaluation.ineligibleReason ?? "Voucher không hợp lệ.",
          evaluation.missingAmount > 0
            ? { missingAmount: evaluation.missingAmount }
            : undefined
        );
      }

      discountAmount = evaluation.discountAmount;
    }

    // 3. Tính giảm và chia cho từng dòng
    const lineSubtotals = rawLines.map((l) => l.subtotal);
    const lineDiscounts = allocateDiscount(discountAmount, lineSubtotals);

    const lines: CheckoutLine[] = rawLines.map((line, idx) => {
      const lineDiscount = lineDiscounts[idx] ?? new Prisma.Decimal(0);
      const taxableAmount = line.subtotal.minus(lineDiscount);
      const taxAmount = taxableAmount
        .mul(line.taxRate)
        .div(100)
        .toDecimalPlaces(0);
      const lineTotal = taxableAmount.add(taxAmount);

      return {
        ...line,
        discountAmount: lineDiscount,
        taxableAmount,
        taxAmount,
        lineTotal,
      };
    });

    // 4. Xác định nơi nhận và phí ship
    const { address, latitude, longitude, shippingFee } = input.pickupStoreId
      ? await this.resolvePickup(tx, input.pickupStoreId, input.pickupAt)
      : await this.resolveDelivery(tx, input);
    const taxAmount = lines.reduce(
      (total, line) => total.add(line.taxAmount),
      new Prisma.Decimal(0)
    );

    // 5. grandTotal = subtotalAmount - discount + taxAmount + shippingFee
    const grandTotal = subtotalAmount
      .minus(discountAmount)
      .add(taxAmount)
      .add(shippingFee);

    // 6. Nếu paymentMethod = SEPAY và grandTotal = 0: ném VOUCHER_NOT_APPLICABLE
    if (input.paymentMethod === PaymentMethod.SEPAY && grandTotal.isZero()) {
      throw new AppError(
        422,
        ErrorCodes.VOUCHER_NOT_APPLICABLE,
        "Không thể thanh toán SePay cho đơn 0đ. Vui lòng chọn COD."
      );
    }

    // 7. Trừ kho
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

    // 8. Sau khi trừ kho mới giữ lượt voucher
    if (voucher) {
      const claimed = await tx.voucher.updateMany({
        where: {
          id: voucher.id,
          isActive: true,
          OR: [
            { usageLimit: null },
            { usedCount: { lt: voucher.usageLimit ?? 0 } },
          ],
        },
        data: { usedCount: { increment: 1 } },
      });
      if (claimed.count !== 1) {
        throw new AppError(
          409,
          ErrorCodes.VOUCHER_USAGE_EXCEEDED,
          "Voucher đã hết lượt sử dụng."
        );
      }
    }

    // 9. Tạo order
    const order = await tx.order.create({
      data: {
        userId,
        orderNumber: createReference("ORD"),
        idempotencyKey,
        paymentMethod: input.paymentMethod,
        totalAmount: grandTotal,
        shippingAddress: address,
        shippingLatitude: latitude,
        shippingLongitude: longitude,
        recipientName: input.receiverName,
        recipientPhone: input.phone,
        note: input.note ?? null,
        pickupStoreId: input.pickupStoreId ?? null,
        pickupAt: input.pickupStoreId ? new Date(input.pickupAt!) : null,
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

    // Tạo VoucherRedemption nếu dùng voucher
    if (voucher) {
      await tx.voucherRedemption.create({
        data: {
          voucherId: voucher.id,
          userId,
          orderId: order.id,
          code: voucher.code,
          amount: discountAmount,
        },
      });
    }

    // 10. Tạo invoice
    const invoice = await tx.invoice.create({
      data: {
        orderId: order.id,
        userId,
        invoiceNo: createReference("INV"),
        customerName: input.receiverName,
        customerPhone: input.phone,
        customerAddress: address,
        subtotalAmount,
        discountAmount,
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
            discountAmount: line.discountAmount,
            taxableAmount: line.taxableAmount,
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
        discountAmount: true,
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

    await tx.notification.create({
      data: payment
        ? {
            userId,
            type: "PAYMENT",
            title: "Chờ thanh toán",
            message: `Vui lòng thanh toán đơn hàng ${order.orderNumber}.`,
            data: {
              orderId: order.id,
              invoiceId: invoice.id,
              paymentId: payment.id,
              paymentCode: payment.paymentCode,
              status: payment.status,
            },
          }
        : {
            userId,
            type: "ORDER",
            title: "Đặt hàng thành công",
            message: `Đơn hàng ${order.orderNumber} đã được tạo.`,
            data: {
              orderId: order.id,
              invoiceId: invoice.id,
              status: order.status,
            },
          },
    });

    // Delete only the snapshot items
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
        discountAmount: toNumber(invoice.discountAmount),
        taxAmount: toNumber(invoice.taxAmount),
        shippingFee: toNumber(invoice.shippingFee),
        grandTotal: toNumber(invoice.grandTotal),
      },
      payment,
    };
  }

  private async resolveDelivery(
    tx: Prisma.TransactionClient,
    input: CheckoutInput
  ) {
    // checkoutSchema bắt buộc 3 field này khi không nhận tại quán.
    const address = input.address!;
    const latitude = input.latitude!;
    const longitude = input.longitude!;

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
        latitude,
        longitude,
        Number(store.latitude.toString()),
        Number(store.longitude.toString())
      );
      return Math.min(nearest, distance);
    }, Number.POSITIVE_INFINITY);

    return {
      address,
      latitude: new Prisma.Decimal(latitude.toString()),
      longitude: new Prisma.Decimal(longitude.toString()),
      shippingFee: new Prisma.Decimal(calculateShippingFee(nearestDistance)),
    };
  }

  private async resolvePickup(
    tx: Prisma.TransactionClient,
    storeId: string,
    pickupAt: string | undefined
  ) {
    const store = await tx.store.findFirst({
      where: { id: storeId, isActive: true },
      select: { address: true, latitude: true, longitude: true },
    });
    if (!store) {
      throw new AppError(
        404,
        ErrorCodes.STORE_NOT_FOUND,
        "Cửa hàng được chọn không tồn tại hoặc đã tạm dừng hoạt động."
      );
    }

    const pickupTime = new Date(pickupAt!).getTime();
    const now = Date.now();
    if (
      pickupTime <= now ||
      pickupTime > now + MAX_PICKUP_DAYS * 24 * 60 * 60 * 1000
    ) {
      throw new AppError(
        422,
        ErrorCodes.PICKUP_TIME_INVALID,
        "Thời gian nhận hoa không hợp lệ, vui lòng chọn lại."
      );
    }

    return {
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      shippingFee: new Prisma.Decimal(0),
    };
  }

  private assertIdempotentReplay(
    order: CheckoutOrder,
    userId: string,
    input: CheckoutInput
  ): void {
    const isSameVoucher =
      (order.voucherRedemption?.code ?? null) === (input.voucherCode ?? null);

    const isSameDestination = input.pickupStoreId
      ? order.pickupStoreId === input.pickupStoreId &&
        order.pickupAt?.getTime() === new Date(input.pickupAt!).getTime()
      : !order.pickupStoreId &&
        order.shippingAddress === input.address &&
        order.shippingLatitude.equals(input.latitude!) &&
        order.shippingLongitude.equals(input.longitude!);

    const isSameRequest =
      order.userId === userId &&
      order.paymentMethod === input.paymentMethod &&
      isSameDestination &&
      order.recipientName === input.receiverName &&
      order.recipientPhone === input.phone &&
      (order.note ?? null) === (input.note ?? null) &&
      isSameVoucher;

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
        discountAmount: toNumber(order.invoice.discountAmount),
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
