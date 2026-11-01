"use client";

import React, { useState } from "react";
import Image from "next/image";
import { ArrowRight, Heart, Gift, Compass } from "lucide-react";
import { OCCASIONS } from "@/data/mock-data";

export function OccasionSelector() {
  const [activeOccasionId, setActiveOccasionId] = useState(OCCASIONS[1]?.id || OCCASIONS[0].id);

  return (
    <section id="occasions" className="py-20 sm:py-28 bg-cream-100 border-b border-cream-200 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 sm:mb-16">
          <div className="max-w-2xl space-y-3">
            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-forest-800 block">
              Ý Nghĩa Trao Gửi
            </span>
            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-forest-950">
              Chọn hoa theo từng khoảnh khắc đáng nhớ
            </h2>
            <p className="text-sm sm:text-base text-charcoal-600">
              Mỗi loài hoa mang một thông điệp riêng. Để Nhà Có Hoa đồng hành cùng bạn gói ghém tình cảm chân thành nhất.
            </p>
          </div>

          <div className="mt-6 md:mt-0">
            <a
              href="#collection"
              className="inline-flex items-center gap-2 text-xs sm:text-sm font-semibold text-forest-900 hover:text-forest-700 transition-colors group"
            >
              <span>Xem tất cả bộ sưu tập</span>
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </a>
          </div>
        </div>

        {/* Editorial Expanding Cards Lookbook (Desktop) / Carousel (Mobile) */}
        <div className="hidden lg:flex gap-4 h-[480px]">
          {OCCASIONS.map((occ) => {
            const isActive = occ.id === activeOccasionId;
            return (
              <div
                key={occ.id}
                onMouseEnter={() => setActiveOccasionId(occ.id)}
                onClick={() => setActiveOccasionId(occ.id)}
                className={`relative rounded-3xl overflow-hidden cursor-pointer transition-all duration-700 ease-out flex flex-col justify-end p-8 ${
                  isActive ? "flex-[3] shadow-2xl ring-1 ring-white/30" : "flex-[1] hover:flex-[1.2] opacity-85 hover:opacity-100"
                }`}
              >
                {/* Background Photo */}
                <Image
                  src={occ.imageUrl}
                  alt={occ.title}
                  fill
                  sizes="(max-width: 1200px) 50vw, 33vw"
                  className="object-cover transition-transform duration-1000 scale-105 hover:scale-110"
                />

                {/* Dark Vignette Overlay */}
                <div
                  className={`absolute inset-0 transition-opacity duration-500 ${
                    isActive
                      ? "bg-gradient-to-t from-forest-950/90 via-forest-950/30 to-transparent"
                      : "bg-gradient-to-t from-forest-950/95 via-forest-950/60 to-black/30"
                  }`}
                />

                {/* Vertical Pill for inactive cards */}
                {!isActive && (
                  <div className="absolute inset-0 flex flex-col items-center justify-end pb-8 z-10">
                    <span className="text-white font-serif text-lg font-bold [writing-mode:vertical-rl] rotate-180 tracking-widest uppercase">
                      {occ.title}
                    </span>
                  </div>
                )}

                {/* Expanded Details Content for active card */}
                {isActive && (
                  <div className="relative z-10 space-y-3 animate-fade-in max-w-lg">
                    <span className="inline-block px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-white text-[11px] uppercase tracking-wider font-semibold">
                      Chủ đề được yêu thích
                    </span>
                    <h3 className="font-serif text-3xl font-bold text-white">
                      {occ.title}
                    </h3>
                    <p className="text-sm text-white/90 leading-relaxed font-light">
                      {occ.subtitle}. Mỗi cành hoa đều được Florist tuyển chọn tươi mới vào 05:00 sáng, giữ trọn sắc hương vẹn nguyên.
                    </p>
                    <div className="pt-2">
                      <a
                        href="#collection"
                        className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-white text-forest-950 text-xs font-semibold hover:bg-cream-100 transition-colors shadow-lg group"
                      >
                        <span>Khám phá các mẫu hoa</span>
                        <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
                      </a>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Mobile & Tablet Lookbook Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 lg:hidden">
          {OCCASIONS.map((occ) => (
            <div
              key={occ.id}
              className="relative h-80 rounded-3xl overflow-hidden shadow-md flex flex-col justify-end p-6 group"
            >
              <Image
                src={occ.imageUrl}
                alt={occ.title}
                fill
                sizes="(max-width: 768px) 100vw, 50vw"
                className="object-cover group-hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-forest-950/90 via-forest-950/40 to-transparent" />
              
              <div className="relative z-10 space-y-2">
                <span className="text-[10px] uppercase tracking-widest text-petal-300 font-semibold">
                  Ý Nghĩa Trao Gửi
                </span>
                <h3 className="font-serif text-xl font-bold text-white">
                  {occ.title}
                </h3>
                <p className="text-xs text-white/80 line-clamp-2">
                  {occ.subtitle}
                </p>
                <a
                  href="#collection"
                  className="inline-flex items-center gap-1.5 text-xs font-semibold text-petal-200 hover:text-white transition-colors pt-2"
                >
                  <span>Xem gợi ý hoa</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}
