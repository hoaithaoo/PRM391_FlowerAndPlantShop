"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";

const links = [
  ["#categories", "Thế giới hoa"],
  ["#collection", "Bộ sưu tập"],
  ["#occasions", "Những dịp đặc biệt"],
  ["#story", "Câu chuyện"],
  ["#stores", "Cửa hàng"],
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-40 text-white transition-opacity duration-400 ease-out ${
        mounted ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2"
      }`}
      style={{
        background: "linear-gradient(180deg, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.2) 65%, transparent 100%)",
        paddingTop: "env(safe-area-inset-top, 0px)",
      }}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between gap-4">
        {/* Logo */}
        <Link
          href="/"
          className="font-serif text-2xl sm:text-3xl text-white tracking-wide hover:opacity-90 transition-opacity"
        >
          Nhà Có Hoa
        </Link>

        {/* Transparent Navigation Links */}
        <nav className="hidden lg:flex items-center gap-7" aria-label="Điều hướng chính">
          {links.map(([href, label]) => (
            <a
              key={href}
              href={href}
              className="text-xs uppercase tracking-[0.16em] text-white/90 hover:text-white hover:underline underline-offset-8 transition-all py-2"
            >
              {label}
            </a>
          ))}
        </nav>

        {/* Action Button: Hotline or Contact */}
        <div className="flex items-center gap-3">
          <a
            href="tel:0901234567"
            className="min-h-10 px-4 py-2 rounded-full border border-white/40 text-white text-xs tracking-wider uppercase backdrop-blur-sm hover:bg-white/15 transition-all hidden sm:inline-flex items-center"
          >
            Hotline 090 123 4567
          </a>

          <button
            type="button"
            className="lg:hidden min-h-11 min-w-11 flex items-center justify-center text-white p-2"
            aria-expanded={open}
            aria-controls="mobile-navigation"
            aria-label={open ? "Đóng menu" : "Mở menu"}
            onClick={() => setOpen(!open)}
          >
            {open ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {open && (
        <nav
          id="mobile-navigation"
          aria-label="Điều hướng trên điện thoại"
          className="lg:hidden px-6 py-6 bg-black/90 backdrop-blur-xl border-t border-white/10 space-y-3"
        >
          {links.map(([href, label]) => (
            <a
              key={href}
              href={href}
              onClick={() => setOpen(false)}
              className="block py-2.5 text-sm uppercase tracking-wider text-white/90 border-b border-white/5"
            >
              {label}
            </a>
          ))}
          <div className="pt-3">
            <a
              href="tel:0901234567"
              className="w-full py-3 rounded-full bg-white text-forest-950 font-semibold text-xs text-center block uppercase tracking-wider"
            >
              Gọi Hotline 090 123 4567
            </a>
          </div>
        </nav>
      )}
    </header>
  );
}
