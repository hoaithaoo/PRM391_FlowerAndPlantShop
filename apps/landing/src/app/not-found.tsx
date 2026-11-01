import Link from "next/link";

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-cream-100 text-center">
      <h2 className="font-serif text-3xl sm:text-4xl font-bold text-forest-950 mb-3">
        Không tìm thấy trang
      </h2>
      <p className="text-sm text-charcoal-600 mb-6 max-w-sm">
        Trang bạn đang tìm kiếm không tồn tại hoặc đã được di chuyển về bộ sưu tập chính.
      </p>
      <Link
        href="/"
        className="px-6 py-3 rounded-full bg-forest-900 text-white text-xs font-semibold hover:bg-forest-800 transition-colors"
      >
        Trở về trang chủ Nhà Có Hoa
      </Link>
    </div>
  );
}
