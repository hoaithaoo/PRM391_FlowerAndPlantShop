import { z } from "zod";

export const favoriteProductIdParamSchema = z.object({
  productId: z.string().uuid("ID sản phẩm không hợp lệ."),
});
