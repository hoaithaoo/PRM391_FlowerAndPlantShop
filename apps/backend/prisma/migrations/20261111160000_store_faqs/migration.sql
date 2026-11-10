-- CreateTable
CREATE TABLE "store_faqs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "topic" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "store_faqs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "store_faqs_is_active_sort_order_idx" ON "store_faqs"("is_active", "sort_order");

-- Chỉ backend (Prisma) truy cập bảng này, giống các bảng khác.
ALTER TABLE "store_faqs" ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS store_faqs_set_updated_at ON "store_faqs";
CREATE TRIGGER store_faqs_set_updated_at BEFORE UPDATE ON "store_faqs"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Seed: FAQ ban đầu, admin sửa tiếp trong app quản trị.
INSERT INTO "store_faqs" ("topic", "answer", "sort_order") VALUES
    ('Phí giao hàng', 'Tính theo quãng đường từ cửa hàng gần nhất đến địa chỉ nhận: trong 2 km là 15.000đ, mỗi km thêm (làm tròn lên) cộng 5.000đ. Nhận tại cửa hàng không mất phí giao. Phí chính xác hiển thị ở bước thanh toán.', 10),
    ('Thời gian giao dự kiến', 'Ước tính khoảng 15 phút chuẩn bị cộng 3 phút cho mỗi km; đây là ước tính, không phải cam kết.', 20),
    ('Nhận tại cửa hàng', 'Ở bước thanh toán chọn nhận tại cửa hàng, chọn cửa hàng và thời gian nhận trong vòng 31 ngày tới. Địa chỉ, số điện thoại, giờ mở cửa xem ở màn bản đồ cửa hàng hoặc hỏi trợ lý.', 30),
    ('Phương thức thanh toán', 'Thanh toán khi nhận hàng (COD) hoặc chuyển khoản qua mã QR (SePay). Chuyển khoản cần hoàn tất trong 15 phút; quá hạn đơn tự hủy.', 40),
    ('Hủy đơn', 'Người dùng tự hủy được trong màn chi tiết đơn khi đơn đang chờ xác nhận hoặc đã xác nhận và chưa thanh toán. Đơn đã thanh toán hoặc đang chuẩn bị/đang giao thì không tự hủy được; hãy liên hệ cửa hàng hoặc gửi phiếu báo sự cố.', 50),
    ('Mã giảm giá (voucher)', 'Nhập mã ở bước thanh toán. Có hai loại: mã giảm tiền hàng và mã giảm phí giao; mỗi đơn dùng tối đa một mã mỗi loại. Mỗi mã có thời gian áp dụng, giá trị đơn tối thiểu, tổng số lượt dùng và số lượt mỗi người; không đủ điều kiện thì mã không được áp dụng.', 60),
    ('Tổng tiền đơn hàng', 'Tổng tiền = tiền hàng − giảm giá + thuế theo từng sản phẩm (nếu có) + phí giao − giảm phí giao.', 70),
    ('Theo dõi đơn hàng', 'Xem trong mục Đơn hàng ở tài khoản hoặc hỏi trợ lý. Trạng thái lần lượt: chờ xác nhận → đã xác nhận → đang chuẩn bị → đang giao → hoàn tất.', 80),
    ('Đánh giá sản phẩm', 'Chỉ đánh giá được sản phẩm trong đơn đã hoàn tất, từ màn chi tiết đơn; mỗi sản phẩm trong đơn đánh giá một lần, chấm 1–5 sao, kèm tối đa 3 ảnh.', 90),
    ('Báo sự cố / khiếu nại', 'Báo ngay trong chat (trợ lý soạn sẵn phiếu) hoặc từ chi tiết đơn. Mỗi phiếu có mã SC-..., cửa hàng xử lý và phản hồi qua ghi chú; có thể hỏi trợ lý tiến độ phiếu.', 100);
