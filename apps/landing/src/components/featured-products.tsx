"use client";

import React, { useMemo, useState } from "react";
import Image from "next/image";
import { Search, X, ShoppingBag, Check } from "lucide-react";
import { PRODUCTS } from "@/data/mock-data";
import { useCart } from "@/context/cart-context";

const categories = [
  { id: "all", label: "Tất cả" },
  { id: "bouquet", label: "Bó hoa tươi" },
  { id: "plant", label: "Cây nội thất" },
  { id: "orchid", label: "Lan hồ điệp" },
  { id: "gift", label: "Hoa khô & quà tặng" },
];

export const FeaturedProducts: React.FC = () => {
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const { addToCart } = useCart();

  const filteredProducts = useMemo(() => {
    const query = searchQuery.trim().toLocaleLowerCase("vi");
    return PRODUCTS.filter((product) => {
      const matchesCategory = selectedCategory === "all" || product.category === selectedCategory;
      const matchesQuery = !query || [
        product.name,
        product.categoryName,
        product.description,
      ].some((value) => value.toLocaleLowerCase("vi").includes(query));
      return matchesCategory && matchesQuery;
    });
  }, [selectedCategory, searchQuery]);

  return (
    <section id="featured" className="py-16 sm:py-24 bg-white border-b border-cream-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-12 space-y-3">
          <span className="text-xs font-semibold uppercase tracking-[0.2em] text-forest-700 block">
            Cửa Hàng Hoa Tươi & Cây Xanh
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-forest-950">
            Đặt Hoa Giao Hỏa Tốc 2 Giờ
          </h2>
          <p className="text-sm sm:text-base text-charcoal-600">
            Tuyển chọn những bó hoa tươi cắm mới trong ngày, cam kết tươi trên 5 ngày và tặng kèm thiệp viết tay.
          </p>
        </div>

        {/* Categories Bar & Search */}
        <div className="space-y-4 mb-8 sm:mb-10">
          <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none" aria-label="Lọc theo danh mục">
            {categories.map((category) => (
              <button
                key={category.id}
                type="button"
                onClick={() => setSelectedCategory(category.id)}
                aria-pressed={selectedCategory === category.id}
                className={`min-h-11 px-5 rounded-full text-xs sm:text-sm font-medium whitespace-nowrap transition-colors duration-180 ${
                  selectedCategory === category.id
                    ? "bg-forest-900 text-white shadow-sm"
                    : "bg-cream-50 text-charcoal-700 hover:bg-cream-100 border border-cream-200"
                }`}
              >
                {category.label}
              </button>
            ))}
          </div>

          <div className="relative">
            <Search className="w-4 h-4 text-charcoal-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Tìm theo tên loài hoa (Hồng Ohara, Lan hồ điệp, Cúc Tana, Monstera...)"
              className="w-full pl-10 pr-10 py-2.5 rounded-full border border-cream-300 text-xs sm:text-sm text-forest-950 placeholder-charcoal-400 bg-cream-50/50 focus:outline-none focus:ring-2 focus:ring-forest-800"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery("")}
                aria-label="Xóa tìm kiếm"
                className="w-8 h-8 rounded-full flex items-center justify-center text-charcoal-400 hover:text-charcoal-700 absolute right-1.5 top-1/2 -translate-y-1/2"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>

        {filteredProducts.length === 0 ? (
          <div className="text-center py-12 space-y-2">
            <p className="text-base font-medium text-forest-950">Không tìm thấy mẫu hoa phù hợp</p>
            <p className="text-sm text-charcoal-500">Bạn thử gõ tên hoa khác hoặc chọn danh mục khác nhé.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
            {filteredProducts.map((product) => (
              <article
                key={product.id}
                className="group rounded-3xl bg-cream-50/50 border border-cream-200 overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col justify-between"
              >
                <div className="relative aspect-[4/5] bg-cream-200 overflow-hidden">
                  <Image
                    src={product.imageUrl}
                    alt={product.name}
                    fill
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                    className="object-cover object-center group-hover:scale-105 transition-transform duration-500"
                  />
                  {product.tags && product.tags[0] && (
                    <span className="absolute top-3 left-3 px-2.5 py-1 rounded-full text-[10px] font-semibold tracking-wider uppercase bg-white/90 backdrop-blur-md text-forest-950 shadow-sm">
                      {product.tags[0]}
                    </span>
                  )}
                </div>

                <div className="p-5 flex-1 flex flex-col justify-between space-y-3">
                  <div>
                    <p className="text-[11px] font-semibold uppercase tracking-wider text-forest-700">
                      {product.categoryName}
                    </p>
                    <h3 className="font-serif text-lg font-bold text-forest-950 group-hover:text-forest-700 transition-colors line-clamp-1 mt-1">
                      {product.name}
                    </h3>
                    <p className="text-xs text-charcoal-500 leading-relaxed line-clamp-2 mt-1">
                      {product.description}
                    </p>
                  </div>

                  <div className="pt-3 border-t border-cream-200 flex items-center justify-between">
                    <div>
                      <div className="flex items-baseline gap-1.5">
                        <span className="font-serif text-base font-bold text-forest-900">
                          {product.price.toLocaleString("vi-VN")}₫
                        </span>
                        {product.originalPrice && (
                          <span className="text-[11px] text-charcoal-400 line-through">
                            {product.originalPrice.toLocaleString("vi-VN")}₫
                          </span>
                        )}
                      </div>
                      <span className="text-[10px] text-emerald-600 font-medium flex items-center gap-1">
                        <Check className="w-3 h-3" /> Giao hỏa tốc 2h
                      </span>
                    </div>

                    <button
                      type="button"
                      onClick={() => addToCart(product, 1)}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-forest-900 text-white text-xs font-semibold hover:bg-forest-800 active:scale-95 transition-all shadow-sm"
                    >
                      <ShoppingBag className="w-3.5 h-3.5" />
                      <span>Đặt mua</span>
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
    </section>
  );
};
