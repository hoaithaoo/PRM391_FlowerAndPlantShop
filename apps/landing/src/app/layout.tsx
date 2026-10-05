import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Nhà Có Hoa • Hoa tươi & cây xanh",
  description:
    "Khám phá các bộ sưu tập hoa nghệ thuật và câu chuyện về các loài hoa được Nhà Có Hoa tuyển chọn.",
  keywords: [
    "hoa tươi",
    "cây cảnh",
    "nghệ thuật cắm hoa",
    "sen đồng tháp",
    "hoa đà lạt",
    "hoa tây bắc",
    "bộ sưu tập hoa",
  ],
  openGraph: {
    title: "Nhà Có Hoa • Hoa tươi & cây xanh",
    description:
      "Ngắm các bộ sưu tập hoa nghệ thuật và câu chuyện về loài hoa từ Nhà Có Hoa.",
    locale: "vi_VN",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi">
      <body className="min-h-screen bg-cream-100 text-charcoal-900 font-sans selection:bg-petal-200 selection:text-charcoal-900">
        {children}
      </body>
    </html>
  );
}
