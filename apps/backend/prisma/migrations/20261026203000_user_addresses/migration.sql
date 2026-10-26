-- CreateTable
CREATE TABLE IF NOT EXISTS "user_addresses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "label" TEXT NOT NULL DEFAULT 'Nhà riêng',
    "recipient_name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "address_line" TEXT,
    "ward" TEXT,
    "district" TEXT,
    "city" TEXT,
    "driver_note" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "latitude" DECIMAL(9,6),
    "longitude" DECIMAL(9,6),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_addresses_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "user_addresses_user_id_is_default_idx" ON "user_addresses"("user_id", "is_default");
CREATE INDEX IF NOT EXISTS "user_addresses_user_id_created_at_idx" ON "user_addresses"("user_id", "created_at");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'user_addresses_user_id_fkey'
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
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'user_addresses_latitude_range'
  ) THEN
    ALTER TABLE "user_addresses"
      ADD CONSTRAINT "user_addresses_latitude_range"
      CHECK ("latitude" IS NULL OR ("latitude" >= -90 AND "latitude" <= 90));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'user_addresses_longitude_range'
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
