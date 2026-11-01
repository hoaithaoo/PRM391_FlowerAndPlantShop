export interface CartItemResponse {
  id: string;
  productId: string;
  name: string;
  price: number;
  quantity: number;
  subtotal: number;
}

export interface CartResponse {
  id: string;
  items: CartItemResponse[];
  totalQuantity: number;
  subtotal: number;
}

export interface AddCartItemResponse {
  id: string;
  productId: string;
  quantity: number;
  subtotal: number;
}

export interface UpdateCartItemResponse {
  id: string;
  quantity: number;
  subtotal: number;
}
