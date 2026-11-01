import { Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import type { AddCartItemInput, UpdateCartItemInput } from "./cart.schema";
import type {
  AddCartItemResponse,
  CartResponse,
  UpdateCartItemResponse,
} from "./cart.type";

type CartDatabase = Pick<PrismaClient, "$transaction" | "cartItem">;

const MAX_TRANSACTION_ATTEMPTS = 3;

const isRetryableTransactionError = (error: unknown): boolean =>
  error instanceof Prisma.PrismaClientKnownRequestError &&
  (error.code === "P2034" || error.code === "P2002");

export class CartService {
  constructor(private readonly db: CartDatabase = prisma) {}

  async getCart(userId: string): Promise<CartResponse> {
    return this.withTransactionRetry(async (tx) => {
      const cart = await tx.cart.upsert({
        where: { userId },
        create: { userId },
        update: {},
        include: {
          items: {
            orderBy: { createdAt: "asc" },
            include: {
              product: {
                select: { id: true, name: true, price: true },
              },
            },
          },
        },
      });

      const items = cart.items.map((item) => {
        const price = Number(item.product.price.toString());
        return {
          id: item.id,
          productId: item.productId,
          name: item.product.name,
          price,
          quantity: item.quantity,
          subtotal: price * item.quantity,
        };
      });

      return {
        id: cart.id,
        items,
        totalQuantity: items.reduce((total, item) => total + item.quantity, 0),
        subtotal: items.reduce((total, item) => total + item.subtotal, 0),
      };
    });
  }

  async addItemToCart(
    userId: string,
    input: AddCartItemInput
  ): Promise<AddCartItemResponse> {
    return this.withTransactionRetry(async (tx) => {
      const product = await tx.product.findFirst({
        where: { id: input.productId, isActive: true },
        select: { id: true, price: true, stock: true },
      });

      if (!product) {
        throw new AppError(
          404,
          ErrorCodes.PRODUCT_NOT_FOUND,
          "Sản phẩm không tồn tại hoặc đã ngừng bán."
        );
      }

      const cart = await tx.cart.upsert({
        where: { userId },
        create: { userId },
        update: {},
        select: { id: true },
      });
      const existing = await tx.cartItem.findUnique({
        where: {
          cartId_productId: { cartId: cart.id, productId: product.id },
        },
        select: { id: true, quantity: true },
      });
      const quantity = (existing?.quantity ?? 0) + input.quantity;

      if (quantity > product.stock) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_OUT_OF_STOCK,
          "Số lượng sản phẩm trong giỏ vượt quá tồn kho hiện tại."
        );
      }

      const item = existing
        ? await tx.cartItem.update({
            where: { id: existing.id },
            data: { quantity },
            select: { id: true, productId: true, quantity: true },
          })
        : await tx.cartItem.create({
            data: { cartId: cart.id, productId: product.id, quantity },
            select: { id: true, productId: true, quantity: true },
          });

      return {
        ...item,
        subtotal: Number(product.price.toString()) * item.quantity,
      };
    });
  }

  async updateCartItem(
    userId: string,
    cartItemId: string,
    input: UpdateCartItemInput
  ): Promise<UpdateCartItemResponse> {
    return this.withTransactionRetry(async (tx) => {
      const existing = await tx.cartItem.findFirst({
        where: { id: cartItemId, cart: { userId } },
        include: { product: true },
      });

      if (!existing) {
        throw new AppError(
          404,
          ErrorCodes.CART_ITEM_NOT_FOUND,
          "Không tìm thấy sản phẩm này trong giỏ hàng của bạn."
        );
      }
      if (!existing.product.isActive) {
        throw new AppError(
          404,
          ErrorCodes.PRODUCT_NOT_FOUND,
          "Sản phẩm không tồn tại hoặc đã ngừng bán."
        );
      }
      if (input.quantity > existing.product.stock) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_OUT_OF_STOCK,
          "Số lượng sản phẩm trong giỏ vượt quá tồn kho hiện tại."
        );
      }

      const item = await tx.cartItem.update({
        where: { id: existing.id },
        data: { quantity: input.quantity },
        select: { id: true, quantity: true },
      });

      return {
        ...item,
        subtotal:
          Number(existing.product.price.toString()) * item.quantity,
      };
    });
  }

  async removeCartItem(userId: string, cartItemId: string): Promise<void> {
    const result = await this.db.cartItem.deleteMany({
      where: { id: cartItemId, cart: { userId } },
    });
    if (result.count === 0) {
      throw new AppError(
        404,
        ErrorCodes.CART_ITEM_NOT_FOUND,
        "Không tìm thấy sản phẩm này trong giỏ hàng của bạn."
      );
    }
  }

  private async withTransactionRetry<T>(
    operation: (tx: Prisma.TransactionClient) => Promise<T>
  ): Promise<T> {
    for (let attempt = 1; attempt <= MAX_TRANSACTION_ATTEMPTS; attempt += 1) {
      try {
        return await this.db.$transaction(operation, {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        });
      } catch (error) {
        if (!isRetryableTransactionError(error)) throw error;
        if (attempt === MAX_TRANSACTION_ATTEMPTS) {
          throw new AppError(
            409,
            ErrorCodes.TRANSACTION_CONFLICT,
            "Giỏ hàng vừa được thay đổi, vui lòng thử lại."
          );
        }
      }
    }

    throw new AppError(
      409,
      ErrorCodes.TRANSACTION_CONFLICT,
      "Giỏ hàng vừa được thay đổi, vui lòng thử lại."
    );
  }
}

export const cartService = new CartService();
