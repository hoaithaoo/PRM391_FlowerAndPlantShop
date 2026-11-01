import Link from "next/link";

export function Footer() {
  return (
    <footer className="bg-forest-900 text-cream-100 pt-14 sm:pt-16 pb-8 border-t border-forest-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-10 pb-10 border-b border-white/15">
          <div className="lg:col-span-2">
            <Link href="/" className="inline-flex items-center min-h-11">
              <span className="font-serif text-2xl sm:text-3xl font-bold tracking-wide">
                NHÀ CÓ HOA
              </span>
            </Link>
            <p className="text-sm text-cream-200/80 leading-relaxed max-w-md mt-3">
              Một góc nhỏ dành cho hoa tươi, cây xanh và những cảm hứng sống gần thiên nhiên.
            </p>
            <div className="mt-5 space-y-2 text-sm text-cream-200/80">
              <p>Thông tin liên hệ chính thức sẽ được cập nhật khi ra mắt.</p>
              <a href="#stores" className="inline-flex items-center min-h-11 underline underline-offset-4">Khám phá không gian cửa hàng</a>
            </div>
          </div>

          <nav aria-label="Bộ sưu tập">
            <h2 className="font-serif text-lg font-semibold mb-4">Bộ sưu tập</h2>
            <ul className="space-y-3 text-sm text-cream-200/80">
              <li><Link href="#categories" className="hover:text-white">Bó hoa tươi</Link></li>
              <li><Link href="#categories" className="hover:text-white">Lan hồ điệp</Link></li>
              <li><Link href="#categories" className="hover:text-white">Cây xanh nội thất</Link></li>
              <li><Link href="#occasions" className="hover:text-white">Hoa theo dịp</Link></li>
            </ul>
          </nav>

          <nav aria-label="Khám phá">
            <h2 className="font-serif text-lg font-semibold mb-4">Khám phá</h2>
            <ul className="space-y-3 text-sm text-cream-200/80">
              <li><Link href="#story" className="hover:text-white">Về Nhà Có Hoa</Link></li>
              <li><Link href="#collection" className="hover:text-white">Bộ sưu tập hoa & cây</Link></li>
              <li><Link href="#categories" className="hover:text-white">Thế giới hoa & cây</Link></li>
              <li><Link href="#reviews" className="hover:text-white">Đánh giá khách hàng</Link></li>
              <li><Link href="#stores" className="hover:text-white">Vị trí cửa hàng</Link></li>
              <li><Link href="#app-download" className="hover:text-white">Tải ứng dụng</Link></li>
            </ul>
          </nav>
        </div>

        <p className="pt-6 text-center sm:text-left text-xs text-cream-200/60">
          © 2026 Nhà Có Hoa. Đồng hành cùng những người yêu hoa và cây xanh.
        </p>
      </div>
    </footer>
  );
}
