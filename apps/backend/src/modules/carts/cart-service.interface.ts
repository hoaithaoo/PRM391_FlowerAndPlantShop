import type { AddCartItemInput, UpdateCartItemInput } from "./cart.schema";
import type {
  AddCartItemResponse,
  CartResponse,
  UpdateCartItemResponse,
} from "./cart.type";

export interface ICartService {
  getCart(userId: string): Promise<CartResponse>;
  addItemToCart(
    userId: string,
    input: AddCartItemInput
  ): Promise<AddCartItemResponse>;
  updateCartItem(
    userId: string,
    cartItemId: string,
    input: UpdateCartItemInput
  ): Promise<UpdateCartItemResponse>;
  removeCartItem(userId: string, cartItemId: string): Promise<void>;
}
