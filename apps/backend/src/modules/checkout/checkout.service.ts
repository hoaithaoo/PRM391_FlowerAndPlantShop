import { randomUUID } from "node:crypto";
import {
  PaymentMethod,
  Prisma,
  PrismaClient,
  type Voucher,
  VoucherScope,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  calculateDistanceKm,
  calculateShippingFee,
} from "../../common/utils/distance";
import { env } from "../../config/env";
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
  voucherRedemptions: {
    select: { code: true },
  },
  items: {
    select: { productId: true, quantity: true },
  },
} satisfies Prisma.OrderInclude;

type CheckoutOrder = Prisma.OrderGetPayload<{
  include: typeof checkoutOrderInclude;
}>;

const checkoutProductSelect = {
  id: true,
  name: true,
  sku: true,
  price: true,
  taxRate: true,
  stock: true,
  isActive: true,
} satisfies Prisma.ProductSelect;

interface CheckoutLine {
  /** null khi mua ngay: dòng không đến từ giỏ hàng. */
  cartItemId: string | null;
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

/** Link ảnh VietQR của SePay; nội dung CK là paymentCode để webhook đối soát. */
export const buildSepayQrUrl = (
  paymentCode: string,
  amount: Prisma.Decimal,
  config: Pick<
    typeof env,
    "SEPAY_BANK_ACCOUNT" | "SEPAY_BANK_CODE" | "SEPAY_QR_BASE_URL"
  > = env
): string | null => {
  if (!config.SEPAY_BANK_ACCOUNT || !config.SEPAY_BANK_CODE) return null;
  const url = new URL(config.SEPAY_QR_BASE_URL);
  url.searchParams.set("acc", config.SEPAY_BANK_ACCOUNT);
  url.searchParams.set("bank", config.SEPAY_BANK_CODE);
  url.searchParams.set("amount", amount.toFixed(0));
  url.searchParams.set("des", paymentCode);
  url.searchParams.set("template", "compact");
  return url.toString();
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

    // 1. Đọc giỏ (hoặc sản phẩm mua ngay) và kiểm tra tồn kho
    const sourceItems = await this.loadCheckoutItems(tx, userId, input);
    const rawLines = sourceItems.map((item) => {
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

    // 2. Xác định nơi nhận và phí ship: voucher SHIPPING tính trên phí này
    const { address, latitude, longitude, shippingFee } = input.pickupStoreId
      ? await this.resolvePickup(tx, input.pickupStoreId, input.pickupAt)
      : await this.resolveDelivery(tx, input);

    if (input.pickupStoreId && input.shippingVoucherCode) {
      throw new AppError(
        422,
        ErrorCodes.VOUCHER_NOT_APPLICABLE,
        "Nhận tại quán không dùng được voucher phí ship."
      );
    }

    const orderVoucher = await this.applyVoucher(
      tx,
      input.voucherCode,
      VoucherScope.ORDER,
      userId,
      subtotalAmount,
      shippingFee
    );
    const shippingVoucher = await this.applyVoucher(
      tx,
      input.shippingVoucherCode,
      VoucherScope.SHIPPING,
      userId,
      subtotalAmount,
      shippingFee
    );
    const discountAmount = orderVoucher?.amount ?? new Prisma.Decimal(0);
    const shippingDiscountAmount =
      shippingVoucher?.amount ?? new Prisma.Decimal(0);
    const appliedVouchers = [orderVoucher, shippingVoucher].filter(
      (item) => item !== null
    );

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

    const taxAmount = lines.reduce(
      (total, line) => total.add(line.taxAmount),
      new Prisma.Decimal(0)
    );

    // 4. grandTotal = tiền hàng - giảm + thuế + phí ship - giảm phí ship
    const grandTotal = subtotalAmount
      .minus(discountAmount)
      .add(taxAmount)
      .add(shippingFee)
      .minus(shippingDiscountAmount);

    // 5. Nếu paymentMethod = SEPAY và grandTotal = 0: ném VOUCHER_NOT_APPLICABLE
    if (input.paymentMethod === PaymentMethod.SEPAY && grandTotal.isZero()) {
      throw new AppError(
        422,
        ErrorCodes.VOUCHER_NOT_APPLICABLE,
        "Không thể thanh toán SePay cho đơn 0đ. Vui lòng chọn COD."
      );
    }

    // 6. Trừ kho
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

    // 7. Sau khi trừ kho mới giữ lượt voucher
    for (const { voucher } of appliedVouchers) {
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

    // 8. Tạo order
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
    for (const { voucher, amount } of appliedVouchers) {
      await tx.voucherRedemption.create({
        data: {
          voucherId: voucher.id,
          userId,
          orderId: order.id,
          code: voucher.code,
          amount,
        },
      });
    }

    // 9. Tạo invoice
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
        shippingDiscountAmount,
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
        shippingDiscountAmount: true,
        grandTotal: true,
      },
    });

    const paymentCode = createReference("PAY").replaceAll("-", "");
    const payment =
      input.paymentMethod === PaymentMethod.SEPAY
        ? await tx.payment.create({
            data: {
              invoiceId: invoice.id,
              paymentCode,
              provider: PaymentMethod.SEPAY,
              amount: grandTotal,
              expiresAt: new Date(
                Date.now() + PAYMENT_EXPIRY_MINUTES * 60 * 1000
              ),
              qrUrl: buildSepayQrUrl(paymentCode, grandTotal),
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

    // Delete only the snapshot items; mua ngay không đụng tới giỏ
    const cartItemIds = lines.flatMap((line) =>
      line.cartItemId ? [line.cartItemId] : []
    );
    if (cartItemIds.length > 0) {
      await tx.cartItem.deleteMany({
        where: { id: { in: cartItemIds }, cart: { userId } },
      });
    }

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
        shippingDiscountAmount: toNumber(invoice.shippingDiscountAmount),
        grandTotal: toNumber(invoice.grandTotal),
      },
      payment,
    };
  }

  private async loadCheckoutItems(
    tx: Prisma.TransactionClient,
    userId: string,
    input: CheckoutInput
  ) {
    if (input.buyNow) {
      const product = await tx.product.findUnique({
        where: { id: input.buyNow.productId },
        select: checkoutProductSelect,
      });
      if (!product) {
        throw new AppError(
          404,
          ErrorCodes.PRODUCT_NOT_FOUND,
          "Sản phẩm không tồn tại hoặc đã ngừng bán."
        );
      }
      return [{ id: null, quantity: input.buyNow.quantity, product }];
    }

    const selectedIds = input.cartItemIds
      ? [...new Set(input.cartItemIds)]
      : undefined;
    const cart = await tx.cart.findUnique({
      where: { userId },
      select: {
        items: {
          ...(selectedIds ? { where: { id: { in: selectedIds } } } : {}),
          orderBy: { productId: "asc" },
          select: {
            id: true,
            quantity: true,
            product: { select: checkoutProductSelect },
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
    // Món đã chọn bị xoá khỏi giỏ (ở thiết bị khác) thì không đặt thiếu âm thầm.
    if (selectedIds && cart.items.length !== selectedIds.length) {
      throw new AppError(
        409,
        ErrorCodes.CART_ITEM_NOT_FOUND,
        "Một số sản phẩm đã chọn không còn trong giỏ hàng. Vui lòng tải lại giỏ."
      );
    }
    return cart.items;
  }

  /** Tìm và kiểm tra voucher. Sai loại cũng bị từ chối để mã không giảm nhầm khoản. */
  private async applyVoucher(
    tx: Prisma.TransactionClient,
    code: string | null | undefined,
    scope: VoucherScope,
    userId: string,
    subtotal: Prisma.Decimal,
    shippingFee: Prisma.Decimal
  ): Promise<{ voucher: Voucher; amount: Prisma.Decimal } | null> {
    if (!code) return null;

    const voucher = await tx.voucher.findUnique({ where: { code } });
    if (!voucher) {
      throw new AppError(
        404,
        ErrorCodes.VOUCHER_NOT_FOUND,
        "Mã voucher không tồn tại."
      );
    }
    if (voucher.scope !== scope) {
      throw new AppError(
        422,
        ErrorCodes.VOUCHER_NOT_APPLICABLE,
        "Mã voucher không đúng loại."
      );
    }

    const evaluation = await voucherService.evaluateVoucher(
      voucher,
      userId,
      subtotal,
      new Date(),
      tx,
      shippingFee
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

    return { voucher, amount: evaluation.discountAmount };
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
    const usedCodes = order.voucherRedemptions.map((item) => item.code).sort();
    const requestedCodes = [input.voucherCode, input.shippingVoucherCode]
      .filter((code) => !!code)
      .sort();
    const isSameVoucher =
      usedCodes.length === requestedCodes.length &&
      usedCodes.every((code, index) => code === requestedCodes[index]);

    // Mua ngay gửi lại phải đúng sản phẩm và số lượng đã đặt.
    const isSameItems =
      !input.buyNow ||
      (order.items.length === 1 &&
        order.items[0]!.productId === input.buyNow.productId &&
        order.items[0]!.quantity === input.buyNow.quantity);

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
      isSameVoucher &&
      isSameItems;

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
        shippingDiscountAmount: toNumber(order.invoice.shippingDiscountAmount),
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
