-- CreateEnum
CREATE TYPE "VoucherType" AS ENUM ('PERCENT', 'FIXED');

-- CreateTable
CREATE TABLE "vouchers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" TEXT NOT NULL,
    "type" "VoucherType" NOT NULL,
    "value" DECIMAL(18,0) NOT NULL,
    "max_discount" DECIMAL(18,0),
    "min_order_amount" DECIMAL(18,0) NOT NULL DEFAULT 0,
    "starts_at" TIMESTAMPTZ(3) NOT NULL,
    "ends_at" TIMESTAMPTZ(3) NOT NULL,
    "usage_limit" INTEGER,
    "per_user_limit" INTEGER NOT NULL DEFAULT 1,
    "used_count" INTEGER NOT NULL DEFAULT 0,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vouchers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "voucher_redemptions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "voucher_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "amount" DECIMAL(18,0) NOT NULL,
    "released_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "voucher_redemptions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "vouchers_code_key" ON "vouchers"("code");

-- CreateIndex
CREATE INDEX "vouchers_is_public_is_active_ends_at_idx" ON "vouchers"("is_public", "is_active", "ends_at");

-- CreateIndex
CREATE UNIQUE INDEX "voucher_redemptions_order_id_key" ON "voucher_redemptions"("order_id");

-- CreateIndex
CREATE INDEX "voucher_redemptions_voucher_id_user_id_idx" ON "voucher_redemptions"("voucher_id", "user_id");

-- CreateIndex
CREATE INDEX "voucher_redemptions_user_id_idx" ON "voucher_redemptions"("user_id");

-- AddForeignKey
ALTER TABLE "voucher_redemptions" ADD CONSTRAINT "voucher_redemptions_voucher_id_fkey" FOREIGN KEY ("voucher_id") REFERENCES "vouchers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voucher_redemptions" ADD CONSTRAINT "voucher_redemptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voucher_redemptions" ADD CONSTRAINT "voucher_redemptions_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Constraints
ALTER TABLE "vouchers"
  ADD CONSTRAINT "vouchers_value_positive" CHECK ("value" > 0),
  ADD CONSTRAINT "vouchers_percent_range" CHECK ("type" <> 'PERCENT' OR "value" <= 100),
  ADD CONSTRAINT "vouchers_max_discount_positive" CHECK ("max_discount" IS NULL OR "max_discount" > 0),
  ADD CONSTRAINT "vouchers_min_order_amount_non_negative" CHECK ("min_order_amount" >= 0),
  ADD CONSTRAINT "vouchers_time_window_valid" CHECK ("ends_at" > "starts_at"),
  ADD CONSTRAINT "vouchers_usage_limit_positive" CHECK ("usage_limit" IS NULL OR "usage_limit" > 0),
  ADD CONSTRAINT "vouchers_per_user_limit_positive" CHECK ("per_user_limit" > 0),
  ADD CONSTRAINT "vouchers_used_count_non_negative" CHECK ("used_count" >= 0);

ALTER TABLE "voucher_redemptions"
  ADD CONSTRAINT "voucher_redemptions_amount_non_negative" CHECK ("amount" >= 0);

-- Trigger updated_at
DROP TRIGGER IF EXISTS vouchers_set_updated_at ON "vouchers";
CREATE TRIGGER vouchers_set_updated_at BEFORE UPDATE ON "vouchers"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Security: RLS & Revoke from public roles
ALTER TABLE "vouchers" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "voucher_redemptions" ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON TABLE vouchers FROM anon';
    EXECUTE 'REVOKE ALL ON TABLE voucher_redemptions FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON TABLE vouchers FROM authenticated';
    EXECUTE 'REVOKE ALL ON TABLE voucher_redemptions FROM authenticated';
  END IF;
END;
$$;

-- Chốt dữ liệu cũ trước khi có bước tự hủy để đơn cũ không bị hủy hàng loạt
UPDATE "payments"
SET "status" = 'EXPIRED'
WHERE "status" = 'PENDING' AND "expires_at" <= now();

