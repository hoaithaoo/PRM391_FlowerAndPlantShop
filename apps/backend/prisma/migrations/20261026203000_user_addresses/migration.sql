-- Một số môi trường đã tạo bảng user_addresses thủ công trước khi có migration này,
-- nên mọi lệnh đều idempotent và chỉ bổ sung phần còn thiếu, không xóa dữ liệu.

-- CreateTable
CREATE TABLE IF NOT EXISTS "user_addresses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "recipient_name" TEXT NOT NULL,
    "recipient_phone" TEXT NOT NULL,
    "address_line" TEXT NOT NULL,
    "label" TEXT DEFAULT 'Nhà riêng',
    "delivery_note" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "is_default" BOOLEAN NOT NULL DEFAULT true,
    "is_delete" BOOLEAN DEFAULT false,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_addresses_pkey" PRIMARY KEY ("id")
);

-- Bổ sung cột cho bảng được tạo thủ công từ trước
ALTER TABLE "user_addresses" ADD COLUMN IF NOT EXISTS "label" TEXT DEFAULT 'Nhà riêng';
ALTER TABLE "user_addresses" ADD COLUMN IF NOT EXISTS "delivery_note" TEXT;
ALTER TABLE "user_addresses" ADD COLUMN IF NOT EXISTS "latitude" DOUBLE PRECISION;
ALTER TABLE "user_addresses" ADD COLUMN IF NOT EXISTS "longitude" DOUBLE PRECISION;
ALTER TABLE "user_addresses" ADD COLUMN IF NOT EXISTS "is_delete" BOOLEAN DEFAULT false;
ALTER TABLE "user_addresses" ALTER COLUMN "label" SET DEFAULT 'Nhà riêng';

-- CreateIndex
CREATE INDEX IF NOT EXISTS "user_addresses_user_id_is_default_idx" ON "user_addresses"("user_id", "is_default");
CREATE INDEX IF NOT EXISTS "user_addresses_user_id_is_delete_idx" ON "user_addresses"("user_id", "is_delete");
CREATE INDEX IF NOT EXISTS "user_addresses_user_id_created_at_idx" ON "user_addresses"("user_id", "created_at");

-- AddForeignKey (bỏ qua nếu đã có FK cùng tên, kể cả FK cũ trỏ tới auth.users)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_addresses_user_id_fkey'
      AND conrelid = 'public.user_addresses'::regclass
  ) THEN
    ALTER TABLE "user_addresses"
      ADD CONSTRAINT "user_addresses_user_id_fkey"
      FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END;
$$;

-- Constraints
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_addresses_latitude_range'
      AND conrelid = 'public.user_addresses'::regclass
  ) THEN
    ALTER TABLE "user_addresses"
      ADD CONSTRAINT "user_addresses_latitude_range"
      CHECK ("latitude" IS NULL OR ("latitude" >= -90 AND "latitude" <= 90));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_addresses_longitude_range'
      AND conrelid = 'public.user_addresses'::regclass
  ) THEN
    ALTER TABLE "user_addresses"
      ADD CONSTRAINT "user_addresses_longitude_range"
      CHECK ("longitude" IS NULL OR ("longitude" >= -180 AND "longitude" <= 180));
  END IF;
END;
$$;

-- Trigger updated_at
DROP TRIGGER IF EXISTS user_addresses_set_updated_at ON "user_addresses";
CREATE TRIGGER user_addresses_set_updated_at BEFORE UPDATE ON "user_addresses"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE "user_addresses" ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON TABLE user_addresses FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON TABLE user_addresses FROM authenticated';
  END IF;
END;
$$;
