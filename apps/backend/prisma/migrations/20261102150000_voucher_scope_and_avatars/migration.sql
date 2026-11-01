-- Voucher theo loại: ORDER giảm tiền hàng, SHIPPING giảm phí ship
CREATE TYPE "VoucherScope" AS ENUM ('ORDER', 'SHIPPING');

ALTER TABLE "vouchers"
  ADD COLUMN "scope" "VoucherScope" NOT NULL DEFAULT 'ORDER';

ALTER TABLE "invoices"
  ADD COLUMN "shipping_discount_amount" DECIMAL(18,0) NOT NULL DEFAULT 0;

-- Một đơn dùng được nhiều voucher (mỗi loại một mã)
DROP INDEX "voucher_redemptions_order_id_key";
CREATE UNIQUE INDEX "voucher_redemptions_order_id_voucher_id_key"
  ON "voucher_redemptions"("order_id", "voucher_id");

-- Ảnh đại diện: đọc công khai, mỗi người chỉ ghi vào thư mục mang id của mình.
-- Chỉ chạy trên Supabase; Postgres thường không có schema storage.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'storage') THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp'])
    ON CONFLICT (id) DO NOTHING;

    EXECUTE $policy$
      CREATE POLICY "avatars_insert_own" ON storage.objects FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
    $policy$;
    EXECUTE $policy$
      CREATE POLICY "avatars_update_own" ON storage.objects FOR UPDATE TO authenticated
      USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
    $policy$;
    EXECUTE $policy$
      CREATE POLICY "avatars_delete_own" ON storage.objects FOR DELETE TO authenticated
      USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
    $policy$;
    -- Ghi đè file cần quyền SELECT, bucket public không tự cấp quyền này.
    EXECUTE $policy$
      CREATE POLICY "avatars_select_own" ON storage.objects FOR SELECT TO authenticated
      USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
    $policy$;
  END IF;
END;
$$;
