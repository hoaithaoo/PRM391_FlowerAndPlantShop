"use client";

import React, { useEffect, useRef } from "react";
import Image from "next/image";
import { CATEGORIES } from "@/data/mock-data";

export function CategoryGrid() {
  const titleRef = useRef<HTMLDivElement>(null);
  const itemsRef = useRef<(HTMLElement | null)[]>([]);

  useEffect(() => {
    // 3. Tiêu đề xuất hiện: hiện dần, dịch lên 20px, phóng từ 96% lên 100%
    const titleEl = titleRef.current;
    if (titleEl) {
      const observer = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            titleEl.classList.remove("opacity-0", "translate-y-5", "scale-[0.96]");
            titleEl.classList.add("opacity-100", "translate-y-0", "scale-100");
            observer.disconnect();
          }
        },
        { threshold: 0.15 }
      );
      observer.observe(titleEl);
    }

    // 4. Cuộn tiếp: ảnh hoa hiện lần lượt; chữ xuất hiện sau ảnh một nhịp ngắn
    const itemObservers: IntersectionObserver[] = [];
    itemsRef.current.forEach((el) => {
      if (!el) return;
      const observer = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            const photo = el.querySelector<HTMLElement>(".category-photo-reveal");
            const text = el.querySelector<HTMLElement>(".category-text-reveal");

            // Ảnh hoa hiện trước
            if (photo) {
              photo.classList.remove("opacity-0", "translate-y-8");
              photo.classList.add("opacity-100", "translate-y-0");
            }

            // Chữ xuất hiện sau ảnh một nhịp ngắn (delay 180ms)
            if (text) {
              setTimeout(() => {
                text.classList.remove("opacity-0", "translate-y-6");
                text.classList.add("opacity-100", "translate-y-0");
              }, 180);
            }

            observer.disconnect();
          }
        },
        { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
      );
      observer.observe(el);
      itemObservers.push(observer);
    });

    return () => {
      itemObservers.forEach((obs) => obs.disconnect());
    };
  }, []);

  return (
    <section id="categories" className="pt-20 sm:pt-28 pb-20 sm:pb-32 bg-[#FFF5F7]">
      <div className="max-w-6xl mx-auto px-6 lg:px-8">
        
        {/* 3. Tiêu đề: “Một chút thiên nhiên, một chút dịu dàng” */}
        <div
          ref={titleRef}
          className="max-w-4xl mx-auto text-center space-y-4 mb-20 sm:mb-28 opacity-0 translate-y-5 scale-[0.96] transition-all duration-700 ease-out will-change-transform"
        >
          <p className="text-xs sm:text-sm uppercase tracking-[0.22em] text-petal-500 font-semibold">
            Những sắc hoa ở Nhà Có Hoa
          </p>
          <h2 className="font-serif text-4xl sm:text-6xl lg:text-7xl text-forest-950 font-normal leading-[1.15] text-balance">
            Một chút thiên nhiên,<br /> một chút dịu dàng
          </h2>
          <div className="w-12 h-0.5 bg-petal-300 mx-auto mt-6 rounded-full" />
        </div>

        {/* 4. Danh sách các bài viết danh mục: ảnh hoa hiện trước, chữ theo sau */}
        <div className="space-y-24 sm:space-y-36">
          {CATEGORIES.map((category, index) => {
            const isReversed = index % 2 === 1;
            return (
              <article
                key={category.id}
                ref={(el) => {
                  itemsRef.current[index] = el;
                }}
                className="grid md:grid-cols-2 gap-10 md:gap-16 lg:gap-20 items-center"
              >
                {/* Ảnh hoa (hiện trước) */}
                <div className={isReversed ? "md:order-2" : ""}>
                  <div className="category-photo-reveal opacity-0 translate-y-8 transition-all duration-700 ease-out">
                    <div className="relative aspect-[4/5] rounded-t-[45%] rounded-b-3xl overflow-hidden bg-petal-100 shadow-2xl group border-4 border-white/60">
                      <Image
                        src={category.imageUrl}
                        alt={category.name}
                        fill
                        sizes="(max-width: 768px) 100vw, 50vw"
                        className="object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent pointer-events-none" />
                    </div>
                  </div>
                </div>

                {/* Chữ mô tả (xuất hiện sau ảnh một nhịp ngắn) */}
                <div className={isReversed ? "md:order-1" : ""}>
                  <div className="category-text-reveal opacity-0 translate-y-6 transition-all duration-600 ease-out space-y-5">
                    <p className="text-xs uppercase tracking-[0.25em] text-petal-500 font-semibold">
                      0{index + 1} / HOA & CÂY NGHỆ THUẬT
                    </p>
                    <h3 className="font-serif text-3xl sm:text-4xl lg:text-5xl text-forest-950 font-bold leading-tight">
                      {category.name}
                    </h3>
                    <p className="text-sm sm:text-base leading-relaxed text-charcoal-700 max-w-md font-light">
                      {category.description}
                    </p>
                    <div className="pt-2">
                      <a
                        href="#collection"
                        className="inline-flex items-center gap-2 text-xs uppercase tracking-widest font-semibold text-forest-900 hover:text-petal-600 transition-colors group"
                      >
                        <span>Chiêm ngưỡng bộ sưu tập</span>
                        <span className="transform group-hover:translate-x-1.5 transition-transform duration-200">
                          →
                        </span>
                      </a>
                    </div>
                  </div>
                </div>
              </article>
            );
          })}
        </div>

      </div>
    </section>
  );
}
