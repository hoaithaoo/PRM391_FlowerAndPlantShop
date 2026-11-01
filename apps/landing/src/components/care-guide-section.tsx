"use client";

import React from "react";
import Image from "next/image";
import { Clock, ArrowRight, BookOpen } from "lucide-react";
import { ARTICLES } from "@/data/mock-data";

export const CareGuideSection: React.FC = () => {
  return (
    <section id="care-guide" className="font-sans py-16 sm:py-24 bg-cream-50 border-b border-cream-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div className="space-y-3">
            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-forest-600 block">
              Góc Yêu Hoa & Cây
            </span>
            <h2 className="font-sans text-2xl sm:text-3xl lg:text-4xl font-semibold leading-tight text-forest-950">
              Cẩm nang chăm sóc hoa & cây cảnh
            </h2>
          </div>
          <p className="text-sm text-charcoal-600 max-w-md">
            Chia sẻ những kinh nghiệm thực tế giúp không gian sống luôn tràn ngập năng lượng an lành từ thiên nhiên.
          </p>
        </div>

        {/* 3 Articles Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {ARTICLES.map((art) => (
            <article
              key={art.id}
              className="group bg-white rounded-2xl overflow-hidden border border-cream-200 shadow-sm hover:shadow-editorial-hover transition-all duration-300 flex flex-col justify-between"
            >
              <div className="relative aspect-[16/10] overflow-hidden bg-cream-200">
                <Image
                  src={art.imageUrl}
                  alt={art.title}
                  fill
                  sizes="(max-width: 768px) 100vw, 33vw"
                  className="object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <span className="absolute top-4 left-4 px-3 py-1 rounded-full bg-white/90 backdrop-blur-md text-[11px] font-semibold text-forest-900 shadow-sm">
                  {art.category}
                </span>
              </div>

              <div className="p-6 flex-1 flex flex-col justify-between space-y-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-3 text-[11px] text-charcoal-400">
                    <span>{art.date}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {art.readTime}
                    </span>
                  </div>

                  <h3 className="font-sans text-lg font-semibold text-forest-950 group-hover:text-forest-700 transition-colors leading-snug">
                    {art.title}
                  </h3>

                  <p className="text-sm text-charcoal-600 leading-relaxed">
                    {art.excerpt}
                  </p>
                </div>

                <div className="pt-3 border-t border-cream-100 flex items-center justify-between">
                  <span className="text-xs font-semibold text-forest-800 group-hover:text-forest-600 inline-flex items-center gap-1">
                    Đọc tiếp
                    <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
                  </span>
                  <BookOpen className="w-4 h-4 text-charcoal-300 group-hover:text-forest-700 transition-colors" />
                </div>
              </div>
            </article>
          ))}
        </div>

      </div>
    </section>
  );
};
