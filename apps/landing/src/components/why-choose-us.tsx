"use client";

import React from "react";
import Image from "next/image";
import { CheckCircle2 } from "lucide-react";

export const WhyChooseUs: React.FC = () => {
  return (
    <section id="story" className="py-20 sm:py-28 bg-[#FAF6F0] border-b border-cream-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Story Section Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
          
          {/* Left: Founder Portrait (Clean, no floating cards or badges) */}
          <div className="lg:col-span-5 relative">
            <div className="relative aspect-[3/4] w-full rounded-3xl overflow-hidden shadow-2xl bg-cream-200 border-4 border-white/90 group">
              <Image
                src="/images/founder.jpg"
                alt="Đinh Phạm - Founder Nhà Có Hoa Studio"
                fill
                priority
                sizes="(max-width: 1024px) 100vw, 42vw"
                className="object-cover object-center group-hover:scale-102 transition-transform duration-700"
              />
            </div>
          </div>

          {/* Right: Story Copy & Quality Promises */}
          <div className="lg:col-span-7 space-y-6">
            <div className="space-y-1">
              <span className="text-xs uppercase tracking-[0.22em] text-forest-800 font-semibold block">
                Nhà Có Hoa Studio • Thủ Công • Tinh Tế • Bền Vững
              </span>
              <p className="text-[11px] uppercase tracking-widest text-charcoal-500 font-light">
                Sáng lập bởi Đinh Phạm
              </p>
            </div>

            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-forest-950 leading-tight">
              Gửi trao những rung cảm chân thực của tự nhiên
            </h2>

            <p className="text-sm sm:text-base text-charcoal-700 leading-relaxed font-light">
              Khởi đầu từ tình yêu thuần khiết với vẻ đẹp mộc mạc của hoa cỏ, <strong>Nhà Có Hoa Studio</strong> được sáng lập bởi <strong>Đinh Phạm</strong> với triết lý đưa hoa tươi trở về đúng với bản nguyên: không hóa chất công nghiệp, tôn trọng đường nét tự nhiên và lấy cảm xúc chân thật làm trung tâm.
            </p>

            <p className="text-sm sm:text-base text-charcoal-700 leading-relaxed font-light">
              Từng cành hoa được tuyển chọn từ nông trại sớm mai, kết hợp nét mộc mạc của hoa sen Đồng Tháp, sự thơ mộng của cao nguyên Đà Lạt và chất hoang sơ của núi rừng Tây Bắc. Mỗi tác phẩm trao đi là một lời thì thầm chân thành chạm đến trái tim người nhận.
            </p>

            <div className="space-y-3 pt-2">
              <div className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-forest-700 flex-shrink-0 mt-0.5" />
                <p className="text-xs sm:text-sm text-charcoal-700">
                  <strong className="text-forest-950">Chất liệu thân thiện môi trường:</strong> 100% giấy kraft mộc tái chế, dây thừng đay tự nhiên và ruy băng vải thô, loại bỏ hoàn toàn màng nhựa nilông khó phân hủy.
                </p>
              </div>

              <div className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-forest-700 flex-shrink-0 mt-0.5" />
                <p className="text-xs sm:text-sm text-charcoal-700">
                  <strong className="text-forest-950">Hoa cắt trong ngày:</strong> Thu hoạch trực tiếp từ các vườn hoa địa phương lúc 05:00 sáng, giữ nguyên độ ngậm nước tự nhiên và hương thơm thuần khiết.
                </p>
              </div>

              <div className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-forest-700 flex-shrink-0 mt-0.5" />
                <p className="text-xs sm:text-sm text-charcoal-700">
                  <strong className="text-forest-950">Bảo chứng tươi lâu trên 5 ngày:</strong> Kèm gói dưỡng hoa sinh học hữu cơ và cẩm nang chăm sóc độc quyền của Nhà Có Hoa Studio.
                </p>
              </div>
            </div>

            <div className="pt-2">
              <span className="font-serif italic text-base text-forest-900 block">
                — Đinh Phạm, Founder Nhà Có Hoa Studio
              </span>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
