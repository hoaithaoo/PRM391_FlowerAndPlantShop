"use client";

import { useEffect, useRef, useState } from "react";
import { Navbar } from "@/components/navbar";

export function Hero() {
  const sectionRef = useRef<HTMLElement>(null);
  const frameRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const manuallyPaused = useRef(false);
  const [playing, setPlaying] = useState(false);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    const video = videoRef.current;
    const section = sectionRef.current;
    const frame = frameRef.current;
    if (!video || !section || !frame) return;

    let animationFrame = 0;
    const update = () => {
      animationFrame = 0;
      const scrollY = window.scrollY;
      const heroHeight = section.offsetHeight || window.innerHeight;

      // 2. Bắt đầu cuộn: video giữ nguyên kích thước, tối nhẹ dần
      const progress = Math.min(1, Math.max(0, scrollY / (heroHeight * 0.75)));
      frame.style.setProperty("--scroll-darken", String(progress * 0.55));

      // Tạm dừng video khi nội dung hồng pastel đã trượt lên phủ hết
      const isCovered = scrollY >= heroHeight;
      if (isCovered) {
        if (!video.paused) video.pause();
      } else {
        if (video.paused && !manuallyPaused.current && !document.hidden) {
          void video.play().catch(() => setPlaying(false));
        }
      }
    };

    const schedule = () => {
      if (!animationFrame) animationFrame = requestAnimationFrame(update);
    };

    window.addEventListener("scroll", schedule, { passive: true });
    update();

    return () => {
      cancelAnimationFrame(animationFrame);
      window.removeEventListener("scroll", schedule);
      if (video) video.pause();
    };
  }, []);

  const togglePlayback = () => {
    const video = videoRef.current;
    if (!video) return;
    if (video.paused) {
      manuallyPaused.current = false;
      void video.play().catch(() => setPlaying(false));
    } else {
      manuallyPaused.current = true;
      video.pause();
    }
  };

  return (
    <section ref={sectionRef} className="cinema-hero" aria-label="Thước phim hoa Nhà Có Hoa">
      <div className="cinema-stage">
        {/* 1. Mở trang: Logo và menu trong suốt hiện nhẹ trong khoảng 400ms */}
        <Navbar />

        {/* 2. Khung video giữ nguyên kích thước (không thu nhỏ) */}
        <div ref={frameRef} className="cinema-frame">
          <video
            ref={videoRef}
            className="cinema-video"
            src="/video/flower-hero.mp4"
            poster="https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=1600&q=80"
            autoPlay
            muted
            loop
            playsInline
            preload="auto"
            onPlay={() => setPlaying(true)}
            onPause={() => setPlaying(false)}
            onError={() => setFailed(true)}
            aria-label="Cận cảnh những đóa hoa tươi tràn đầy sức sống"
          />

          {/* Lớp phủ tối nhẹ dần theo độ cuộn */}
          <div className="cinema-shade" />

          {/* Cụm chữ thương hiệu ở tâm video */}
          <div className="cinema-wordmark">
            <p className="text-xs sm:text-sm uppercase tracking-[0.22em] mb-5">Bộ sưu tập mùa xuân 2026</p>
            <h1>Giấc Mơ Hoa Cỏ</h1>
            <p className="text-base sm:text-lg mt-6">Mang vẻ đẹp thuần khiết của thiên nhiên vào từng khoảnh khắc.</p>
          </div>

          {/* Nút điều khiển tinh giản */}
          <div className="cinema-controls">
            <a href="#categories" className="cinema-control">Cuộn xuống để khám phá ↓</a>
            {!failed && (
              <button
                type="button"
                className={playing ? "video-pause-accessible" : "cinema-control"}
                onClick={togglePlayback}
              >
                {playing ? "Tạm dừng" : "Phát video"}
              </button>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
