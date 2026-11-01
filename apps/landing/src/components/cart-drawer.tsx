"use client";

import React, { useState } from "react";
import Image from "next/image";
import { useCart } from "@/context/cart-context";
import {
  X,
  Plus,
  Minus,
  Trash2,
  ShoppingBag,
  ArrowRight,
  Sparkles,
  CheckCircle2,
  Phone,
  MapPin,
  FileText,
  CreditCard,
  Truck,
} from "lucide-react";

export function CartDrawer() {
  const {
    items,
    isOpen,
    closeCart,
    updateQuantity,
    removeFromCart,
    clearCart,
    totalItems,
    subtotal,
    discount,
    discountCode,
    applyDiscountCode,
    totalAmount,
    showToast,
  } = useCart();

  const [inputCode, setInputCode] = useState("");
  const [isCheckingOut, setIsCheckingOut] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState<string | null>(null);

  // Checkout form fields
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [cardMessage, setCardMessage] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<"cod" | "banking">("cod");

  if (!isOpen) return null;

  const handleApplyCoupon = (e: React.FormEvent) => {
    e.preventDefault();
    if (inputCode.trim()) {
      applyDiscountCode(inputCode);
      setInputCode("");
    }
  };

  const handleCompleteOrder = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName || !phone || !address) {
      showToast("Vui lòng điền đầy đủ họ tên, số điện thoại và địa chỉ giao hàng!");
      return;
    }
    const orderId = "NCH-" + Math.floor(100000 + Math.random() * 900000);
    setOrderSuccess(orderId);
    clearCart();
    setIsCheckingOut(false);
  };

  const resetAndClose = () => {
    setOrderSuccess(null);
    setIsCheckingOut(false);
    closeCart();
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden animate-fade-in">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
        onClick={resetAndClose}
      />

      <div className="fixed inset-y-0 right-0 max-w-full flex pl-10">
        <div className="w-screen max-w-md bg-white shadow-2xl flex flex-col justify-between">
          
          {/* Header */}
          <div className="p-6 border-b border-cream-200 flex items-center justify-between bg-cream-50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-forest-900 text-white flex items-center justify-center">
                <ShoppingBag className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-serif text-xl font-bold text-forest-950">
                  {orderSuccess ? "Đặt Hàng Thành Công" : isCheckingOut ? "Thông Tin Giao Hoa" : "Giỏ Hàng Của Bạn"}
                </h3>
                <p className="text-xs text-charcoal-500">
                  {orderSuccess
                    ? `Mã đơn: #${orderSuccess}`
                    : `${totalItems} tác phẩm hoa tươi & cây xanh`}
                </p>
              </div>
            </div>

            <button
              onClick={resetAndClose}
              aria-label="Đóng giỏ hàng"
              className="w-9 h-9 rounded-full bg-white border border-cream-200 text-charcoal-600 hover:text-forest-950 flex items-center justify-center transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Body Content */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            
            {/* Case 1: Order Placed Successfully */}
            {orderSuccess ? (
              <div className="text-center py-12 space-y-5">
                <div className="w-20 h-20 rounded-full bg-emerald-100 text-emerald-600 mx-auto flex items-center justify-center animate-bounce">
                  <CheckCircle2 className="w-10 h-10" />
                </div>
                <h4 className="font-serif text-2xl font-bold text-forest-950">
                  Cảm Ơn Bạn Đã Đặt Hoa!
                </h4>
                <p className="text-xs sm:text-sm text-charcoal-600 max-w-sm mx-auto leading-relaxed">
                  Đơn hàng <strong>#{orderSuccess}</strong> của bạn đã được chuyển đến nghệ nhân cắm hoa. Nhân viên sẽ liên hệ số điện thoại <strong>{phone}</strong> trong 5 phút để xác nhận và chụp ảnh thành phẩm trước khi giao hỏa tốc.
                </p>

                <div className="bg-cream-50 p-4 rounded-2xl border border-cream-200 text-left space-y-2 text-xs">
                  <div className="flex justify-between">
                    <span className="text-charcoal-500">Người nhận:</span>
                    <strong className="text-forest-950">{fullName}</strong>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-charcoal-500">Số điện thoại:</span>
                    <strong className="text-forest-950">{phone}</strong>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-charcoal-500">Địa chỉ giao:</span>
                    <strong className="text-forest-950">{address}</strong>
                  </div>
                  {cardMessage && (
                    <div className="pt-2 border-t border-cream-200">
                      <span className="text-charcoal-500 block">Lời chúc thiệp:</span>
                      <p className="italic text-forest-900 mt-1">&ldquo;{cardMessage}&rdquo;</p>
                    </div>
                  )}
                </div>

                <div className="pt-4">
                  <button
                    onClick={resetAndClose}
                    className="w-full py-3.5 rounded-full bg-forest-900 text-white font-medium text-xs sm:text-sm hover:bg-forest-800 transition-colors"
                  >
                    Tiếp tục ngắm hoa
                  </button>
                </div>
              </div>
            ) : isCheckingOut ? (
              /* Case 2: Checkout Form */
              <form onSubmit={handleCompleteOrder} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-forest-900 flex items-center gap-1.5">
                    <span>Họ và tên người nhận hoa</span>
                    <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Ví dụ: Nguyễn Phương Linh"
                    className="w-full px-4 py-2.5 rounded-xl border border-cream-300 text-xs sm:text-sm text-forest-950 focus:outline-none focus:ring-2 focus:ring-forest-800"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-forest-900 flex items-center gap-1.5">
                    <Phone className="w-3.5 h-3.5 text-forest-700" />
                    <span>Số điện thoại nhận hàng</span>
                    <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="Ví dụ: 0912 345 678"
                    className="w-full px-4 py-2.5 rounded-xl border border-cream-300 text-xs sm:text-sm text-forest-950 focus:outline-none focus:ring-2 focus:ring-forest-800"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-forest-900 flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-forest-700" />
                    <span>Địa chỉ giao hoa chi tiết</span>
                    <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="Số nhà, tên đường, phường, quận..."
                    className="w-full px-4 py-2.5 rounded-xl border border-cream-300 text-xs sm:text-sm text-forest-950 focus:outline-none focus:ring-2 focus:ring-forest-800"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-forest-900 flex items-center gap-1.5">
                    <FileText className="w-3.5 h-3.5 text-forest-700" />
                    <span>Lời nhắn thiệp tặng kèm (Miễn phí)</span>
                  </label>
                  <textarea
                    rows={2}
                    value={cardMessage}
                    onChange={(e) => setCardMessage(e.target.value)}
                    placeholder="Chúc mừng sinh nhật / Chúc bạn luôn rạng rỡ như đóa hoa..."
                    className="w-full px-4 py-2 rounded-xl border border-cream-300 text-xs text-forest-950 focus:outline-none focus:ring-2 focus:ring-forest-800"
                  />
                </div>

                {/* Payment selection */}
                <div className="space-y-2 pt-2">
                  <label className="text-xs font-semibold text-forest-900 block">
                    Phương thức thanh toán:
                  </label>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setPaymentMethod("cod")}
                      className={`p-3 rounded-2xl border text-xs flex flex-col items-center gap-1 transition-all ${
                        paymentMethod === "cod"
                          ? "border-forest-900 bg-forest-900/5 font-semibold text-forest-950"
                          : "border-cream-300 text-charcoal-600 hover:bg-cream-50"
                      }`}
                    >
                      <Truck className="w-4 h-4 text-forest-800" />
                      <span>COD (Nhận hoa trả tiền)</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setPaymentMethod("banking")}
                      className={`p-3 rounded-2xl border text-xs flex flex-col items-center gap-1 transition-all ${
                        paymentMethod === "banking"
                          ? "border-forest-900 bg-forest-900/5 font-semibold text-forest-950"
                          : "border-cream-300 text-charcoal-600 hover:bg-cream-50"
                      }`}
                    >
                      <CreditCard className="w-4 h-4 text-forest-800" />
                      <span>Chuyển khoản QR</span>
                    </button>
                  </div>
                </div>

                <div className="pt-4 flex gap-3">
                  <button
                    type="button"
                    onClick={() => setIsCheckingOut(false)}
                    className="w-1/3 py-3 rounded-full border border-cream-300 text-charcoal-700 text-xs hover:bg-cream-50"
                  >
                    Quay lại
                  </button>
                  <button
                    type="submit"
                    className="w-2/3 py-3 rounded-full bg-forest-900 text-white font-semibold text-xs sm:text-sm hover:bg-forest-800 transition-colors shadow-lg shadow-forest-900/20"
                  >
                    Xác nhận đặt hoa • {totalAmount.toLocaleString("vi-VN")}₫
                  </button>
                </div>
              </form>
            ) : items.length === 0 ? (
              /* Case 3: Empty Cart */
              <div className="text-center py-16 space-y-4">
                <div className="w-16 h-16 rounded-full bg-cream-100 text-charcoal-400 mx-auto flex items-center justify-center">
                  <ShoppingBag className="w-8 h-8" />
                </div>
                <h4 className="font-serif text-lg font-bold text-forest-950">
                  Giỏ hàng của bạn đang trống
                </h4>
                <p className="text-xs text-charcoal-500 max-w-xs mx-auto">
                  Hãy ghé thăm bộ sưu tập để chọn cho mình hoặc người thương những cành hoa tươi thắm nhất!
                </p>
                <button
                  onClick={closeCart}
                  className="px-6 py-2.5 rounded-full bg-forest-900 text-white text-xs font-semibold hover:bg-forest-800 transition-colors"
                >
                  Khám phá bộ sưu tập
                </button>
              </div>
            ) : (
              /* Case 4: Item List in Cart */
              <div className="space-y-4">
                {items.map(({ product, quantity }) => (
                  <div
                    key={product.id}
                    className="flex gap-4 p-3 rounded-2xl border border-cream-200 bg-cream-50/50 hover:bg-cream-50 transition-colors"
                  >
                    <div className="relative w-20 h-24 rounded-xl overflow-hidden flex-shrink-0 bg-white">
                      <Image
                        src={product.imageUrl}
                        alt={product.name}
                        fill
                        className="object-cover"
                        sizes="80px"
                      />
                    </div>

                    <div className="flex-1 flex flex-col justify-between py-0.5">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <span className="text-[10px] uppercase font-semibold text-forest-600 block">
                            {product.categoryName}
                          </span>
                          <h4 className="font-serif text-sm font-bold text-forest-950 line-clamp-1">
                            {product.name}
                          </h4>
                        </div>
                        <button
                          onClick={() => removeFromCart(product.id)}
                          aria-label={`Xóa ${product.name}`}
                          className="text-charcoal-400 hover:text-rose-500 transition-colors p-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="flex items-center justify-between mt-2">
                        <span className="font-serif text-sm font-bold text-forest-900">
                          {(product.price * quantity).toLocaleString("vi-VN")}₫
                        </span>

                        <div className="flex items-center gap-2 bg-white px-2 py-1 rounded-full border border-cream-200">
                          <button
                            onClick={() => updateQuantity(product.id, quantity - 1)}
                            aria-label="Giảm số lượng"
                            className="w-5 h-5 rounded-full flex items-center justify-center text-charcoal-600 hover:bg-cream-100"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="text-xs font-semibold text-forest-950 min-w-4 text-center">
                            {quantity}
                          </span>
                          <button
                            onClick={() => updateQuantity(product.id, quantity + 1)}
                            aria-label="Tăng số lượng"
                            className="w-5 h-5 rounded-full flex items-center justify-center text-charcoal-600 hover:bg-cream-100"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}

                {/* Promo Code input */}
                <form onSubmit={handleApplyCoupon} className="pt-2 flex gap-2">
                  <input
                    type="text"
                    value={inputCode}
                    onChange={(e) => setInputCode(e.target.value)}
                    placeholder="Mã giảm giá (nhập SPRING15)..."
                    className="flex-1 px-4 py-2 rounded-full border border-cream-300 text-xs text-forest-950 focus:outline-none focus:ring-1 focus:ring-forest-800"
                  />
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-full bg-forest-900 text-white text-xs font-semibold hover:bg-forest-800 transition-colors flex-shrink-0"
                  >
                    Áp dụng
                  </button>
                </form>

                {discountCode && (
                  <p className="text-[11px] text-emerald-600 flex items-center gap-1">
                    <Sparkles className="w-3 h-3" /> Đã áp dụng mã {discountCode} (-15%)
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Footer of Drawer (Summary & Checkout trigger) */}
          {!orderSuccess && !isCheckingOut && items.length > 0 && (
            <div className="p-6 border-t border-cream-200 bg-cream-50/80 space-y-3">
              <div className="space-y-1.5 text-xs">
                <div className="flex justify-between text-charcoal-600">
                  <span>Tạm tính ({totalItems} sản phẩm):</span>
                  <span>{subtotal.toLocaleString("vi-VN")}₫</span>
                </div>
                {discount > 0 && (
                  <div className="flex justify-between text-emerald-600 font-medium">
                    <span>Giảm giá (15%):</span>
                    <span>-{discount.toLocaleString("vi-VN")}₫</span>
                  </div>
                )}
                <div className="flex justify-between text-charcoal-600">
                  <span>Phí giao hoa hỏa tốc (2h):</span>
                  <span className="text-emerald-600 font-medium">Miễn phí</span>
                </div>
                <div className="flex justify-between text-sm font-bold text-forest-950 pt-2 border-t border-cream-200">
                  <span>Tổng thanh toán:</span>
                  <span className="font-serif text-lg text-forest-900">
                    {totalAmount.toLocaleString("vi-VN")}₫
                  </span>
                </div>
              </div>

              <button
                onClick={() => setIsCheckingOut(true)}
                className="w-full py-3.5 rounded-full bg-forest-900 text-white font-semibold text-xs sm:text-sm hover:bg-forest-800 transition-all flex items-center justify-center gap-2 shadow-lg shadow-forest-900/20 active:scale-95"
              >
                <span>Tiến hành đặt hoa</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <p className="text-[10px] text-center text-charcoal-500">
                * Cam kết bảo hành tươi 5 ngày & Chụp ảnh duyệt trước khi giao
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
