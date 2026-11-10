-- CreateEnum
CREATE TYPE "IncidentCategory" AS ENUM ('DAMAGED_PRODUCT', 'WRONG_ITEM', 'DELIVERY', 'PAYMENT', 'QUALITY', 'SERVICE', 'OTHER');

-- CreateEnum
CREATE TYPE "IncidentStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED');

-- CreateTable
CREATE TABLE "incident_reports" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "order_id" UUID,
    "category" "IncidentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "IncidentStatus" NOT NULL DEFAULT 'OPEN',
    "admin_note" TEXT,
    "resolved_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "incident_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "incident_reports_code_key" ON "incident_reports"("code");

-- CreateIndex
CREATE INDEX "incident_reports_user_id_created_at_idx" ON "incident_reports"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "incident_reports_status_created_at_idx" ON "incident_reports"("status", "created_at");

-- AddForeignKey
ALTER TABLE "incident_reports" ADD CONSTRAINT "incident_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incident_reports" ADD CONSTRAINT "incident_reports_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Chỉ backend (Prisma) truy cập bảng này, giống các bảng khác.
ALTER TABLE "incident_reports" ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS incident_reports_set_updated_at ON "incident_reports";
CREATE TRIGGER incident_reports_set_updated_at BEFORE UPDATE ON "incident_reports"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
