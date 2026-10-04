-- Database-level integrity checks that Prisma schema cannot currently express.
ALTER TABLE "products"
  ADD CONSTRAINT "products_price_non_negative" CHECK ("price" >= 0),
  ADD CONSTRAINT "products_tax_rate_range" CHECK ("tax_rate" >= 0 AND "tax_rate" <= 100),
  ADD CONSTRAINT "products_stock_non_negative" CHECK ("stock" >= 0);

ALTER TABLE "cart_items"
  ADD CONSTRAINT "cart_items_quantity_positive" CHECK ("quantity" > 0);

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_total_non_negative" CHECK ("total_amount" >= 0),
  ADD CONSTRAINT "orders_latitude_range" CHECK ("shipping_latitude" >= -90 AND "shipping_latitude" <= 90),
  ADD CONSTRAINT "orders_longitude_range" CHECK ("shipping_longitude" >= -180 AND "shipping_longitude" <= 180);

ALTER TABLE "order_items"
  ADD CONSTRAINT "order_items_unit_price_non_negative" CHECK ("unit_price" >= 0),
  ADD CONSTRAINT "order_items_quantity_positive" CHECK ("quantity" > 0),
  ADD CONSTRAINT "order_items_subtotal_non_negative" CHECK ("subtotal" >= 0);

ALTER TABLE "invoices"
  ADD CONSTRAINT "invoices_subtotal_non_negative" CHECK ("subtotal_amount" >= 0),
  ADD CONSTRAINT "invoices_discount_non_negative" CHECK ("discount_amount" >= 0),
  ADD CONSTRAINT "invoices_tax_non_negative" CHECK ("tax_amount" >= 0),
  ADD CONSTRAINT "invoices_shipping_non_negative" CHECK ("shipping_fee" >= 0),
  ADD CONSTRAINT "invoices_grand_total_non_negative" CHECK ("grand_total" >= 0);

ALTER TABLE "invoice_items"
  ADD CONSTRAINT "invoice_items_unit_price_non_negative" CHECK ("unit_price" >= 0),
  ADD CONSTRAINT "invoice_items_quantity_positive" CHECK ("quantity" > 0),
  ADD CONSTRAINT "invoice_items_discount_non_negative" CHECK ("discount_amount" >= 0),
  ADD CONSTRAINT "invoice_items_taxable_non_negative" CHECK ("taxable_amount" >= 0),
  ADD CONSTRAINT "invoice_items_tax_rate_range" CHECK ("tax_rate" >= 0 AND "tax_rate" <= 100),
  ADD CONSTRAINT "invoice_items_tax_non_negative" CHECK ("tax_amount" >= 0),
  ADD CONSTRAINT "invoice_items_line_total_non_negative" CHECK ("line_total" >= 0);

ALTER TABLE "payments"
  ADD CONSTRAINT "payments_amount_non_negative" CHECK ("amount" >= 0),
  ADD CONSTRAINT "payments_sepay_fields" CHECK (
    "provider" <> 'SEPAY'
    OR ("payment_code" IS NOT NULL AND "expires_at" IS NOT NULL)
  );

ALTER TABLE "sepay_transactions"
  ADD CONSTRAINT "sepay_transactions_amount_positive" CHECK ("transfer_amount" > 0);

ALTER TABLE "notifications"
  ADD CONSTRAINT "notifications_read_state_consistent" CHECK (
    ("is_read" = false AND "read_at" IS NULL)
    OR ("is_read" = true AND "read_at" IS NOT NULL)
  );

ALTER TABLE "stores"
  ADD CONSTRAINT "stores_latitude_range" CHECK ("latitude" >= -90 AND "latitude" <= 90),
  ADD CONSTRAINT "stores_longitude_range" CHECK ("longitude" >= -180 AND "longitude" <= 180);

-- Keep updated_at correct for writes performed outside Prisma (for example SQL Editor).
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at BEFORE UPDATE ON "profiles"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER categories_set_updated_at BEFORE UPDATE ON "categories"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER products_set_updated_at BEFORE UPDATE ON "products"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER carts_set_updated_at BEFORE UPDATE ON "carts"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER cart_items_set_updated_at BEFORE UPDATE ON "cart_items"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER orders_set_updated_at BEFORE UPDATE ON "orders"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER invoices_set_updated_at BEFORE UPDATE ON "invoices"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER payments_set_updated_at BEFORE UPDATE ON "payments"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER stores_set_updated_at BEFORE UPDATE ON "stores"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER chatbot_conversations_set_updated_at BEFORE UPDATE ON "chatbot_conversations"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Flutter/web clients use Supabase only for Auth. Application data must go
-- through the backend, so every application table is deny-by-default in PostgREST.
ALTER TABLE "profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "products" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "carts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "cart_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "order_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "invoices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "invoice_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "payments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "sepay_transactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "stores" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "chatbot_conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "chatbot_messages" ENABLE ROW LEVEL SECURITY;

-- These roles exist on Supabase but not necessarily in a local PostgreSQL image.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON TABLE profiles, categories, products, carts, cart_items, orders, order_items, invoices, invoice_items, payments, sepay_transactions, notifications, stores, chatbot_conversations, chatbot_messages FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON TABLE profiles, categories, products, carts, cart_items, orders, order_items, invoices, invoice_items, payments, sepay_transactions, notifications, stores, chatbot_conversations, chatbot_messages FROM authenticated';
  END IF;
END;
$$;
