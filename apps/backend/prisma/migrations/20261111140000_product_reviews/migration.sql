-- CreateTable
CREATE TABLE "product_reviews" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "product_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "image_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_hidden" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_reviews_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "product_reviews_rating_check" CHECK ("rating" BETWEEN 1 AND 5),
    CONSTRAINT "product_reviews_image_urls_check" CHECK (cardinality("image_urls") <= 3)
);

-- CreateIndex
CREATE UNIQUE INDEX "product_reviews_order_id_product_id_key" ON "product_reviews"("order_id", "product_id");

-- CreateIndex
CREATE INDEX "product_reviews_product_id_is_hidden_created_at_idx" ON "product_reviews"("product_id", "is_hidden", "created_at");

-- CreateIndex
CREATE INDEX "product_reviews_user_id_idx" ON "product_reviews"("user_id");

-- AddForeignKey
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Chỉ backend (Prisma) truy cập bảng này, giống các bảng khác.
ALTER TABLE "product_reviews" ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS product_reviews_set_updated_at ON "product_reviews";
CREATE TRIGGER product_reviews_set_updated_at BEFORE UPDATE ON "product_reviews"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Bucket ảnh đánh giá: khách chỉ upload vào thư mục {uid}/ của mình, ai cũng xem được.
-- Chỉ chạy trên Supabase; Postgres thường không có schema storage.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'storage') THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('review-images', 'review-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
    ON CONFLICT (id) DO NOTHING;

    EXECUTE $policy$
      CREATE POLICY "review_images_insert_own" ON storage.objects FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'review-images' AND (storage.foldername(name))[1] = auth.uid()::text)
    $policy$;
  END IF;
END;
$$;
