-- Có thể chạy lại mà không xoá dữ liệu yêu thích đã lưu.
CREATE TABLE IF NOT EXISTS "favorites" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" UUID NOT NULL,
  "product_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "favorites_profile_id_product_id_key" ON "favorites"("profile_id", "product_id");
CREATE INDEX IF NOT EXISTS "favorites_profile_id_created_at_idx" ON "favorites"("profile_id", "created_at");
-- Hỗ trợ xoá cascade khi sản phẩm bị xoá.
CREATE INDEX IF NOT EXISTS "favorites_product_id_idx" ON "favorites"("product_id");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'favorites_profile_id_fkey' AND conrelid = 'public.favorites'::regclass
  ) THEN
    ALTER TABLE "favorites" ADD CONSTRAINT "favorites_profile_id_fkey"
      FOREIGN KEY ("profile_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'favorites_product_id_fkey' AND conrelid = 'public.favorites'::regclass
  ) THEN
    ALTER TABLE "favorites" ADD CONSTRAINT "favorites_product_id_fkey"
      FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END;
$$;

-- Giống sổ địa chỉ: chỉ backend được truy cập bảng, luôn lọc theo hồ sơ đã xác thực.
ALTER TABLE "favorites" ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "favorites" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "favorites" FROM authenticated;
  END IF;
END;
$$;
