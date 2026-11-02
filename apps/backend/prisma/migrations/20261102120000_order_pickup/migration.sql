-- Nhận tại quán: đơn có pickup_store_id là đơn khách tự đến lấy
ALTER TABLE "orders"
  ADD COLUMN "pickup_store_id" UUID,
  ADD COLUMN "pickup_at" TIMESTAMPTZ(3);

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_pickup_store_id_fkey"
  FOREIGN KEY ("pickup_store_id") REFERENCES "stores"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
