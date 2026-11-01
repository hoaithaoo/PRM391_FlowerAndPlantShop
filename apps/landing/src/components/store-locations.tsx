"use client";

import { useState } from "react";
import { STORE_LOCATIONS } from "@/data/mock-data";

export function StoreLocations() {
  const [activeStoreId, setActiveStoreId] = useState(STORE_LOCATIONS[0].id);
  const activeStore = STORE_LOCATIONS.find((store) => store.id === activeStoreId) || STORE_LOCATIONS[0];

  return (
    <section id="stores" className="py-20 sm:py-28 bg-cream-100">
      <div className="max-w-6xl mx-auto px-6">
        <p className="text-sm uppercase tracking-widest text-charcoal-600">Vị trí cửa hàng</p>
        <h2 className="font-serif text-4xl sm:text-5xl text-forest-950 mt-4">Hẹn bạn giữa những sắc hoa</h2>
        <p className="text-sm text-charcoal-600 mt-5 mb-10">Địa chỉ minh họa, chưa phải thông tin cửa hàng đã xác nhận.</p>
        <div className="grid lg:grid-cols-2 gap-8">
          <div className="space-y-3" aria-label="Chọn cửa hàng minh họa">
            {STORE_LOCATIONS.map((store) => (
              <button key={store.id} type="button" aria-pressed={store.id === activeStoreId}
                onClick={() => setActiveStoreId(store.id)}
                className={`w-full text-left rounded-2xl border p-6 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-forest-950 ${store.id === activeStoreId ? "bg-petal-100 border-petal-500" : "bg-white border-petal-200 hover:bg-petal-50"}`}>
                <span className="block text-sm text-charcoal-600">{store.city}{store.id === activeStoreId ? " · Đang chọn" : ""}</span>
                <span className="block text-lg font-semibold text-forest-950 mt-2">{store.name}</span>
                <span className="block text-sm leading-relaxed text-charcoal-600 mt-2">{store.address}, {store.district}</span>
              </button>
            ))}
          </div>
          <div className="rounded-3xl bg-white border border-petal-200 p-7 sm:p-10 flex flex-col justify-center" aria-live="polite">
            <p className="text-sm text-charcoal-600">Ghé thăm cửa hàng · Thông tin mẫu</p>
            <h3 className="font-serif text-3xl sm:text-4xl text-forest-950 mt-4">{activeStore.name}</h3>
            <address className="not-italic text-base leading-relaxed text-charcoal-600 mt-6">{activeStore.address}, {activeStore.district}, {activeStore.city}</address>
            <p className="text-base text-charcoal-600 mt-3">Giờ mở cửa: {activeStore.hours}</p>
            <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(activeStore.mapQuery)}`}
              target="_blank" rel="noopener noreferrer"
              className="inline-flex self-start items-center min-h-11 px-6 py-3 mt-8 rounded-full bg-forest-950 text-white hover:bg-forest-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-forest-950">
              Xem khu vực trên Google Maps ↗
            </a>
            <p className="text-sm text-charcoal-600 mt-4">Mở trong tab mới. Bản đồ hiện trỏ đến khu vực minh họa.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
