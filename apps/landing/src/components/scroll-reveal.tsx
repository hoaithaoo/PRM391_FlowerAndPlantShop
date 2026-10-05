"use client";

import { useEffect, useRef, type ReactNode } from "react";

export function ScrollReveal({ children, delay = 0 }: { children: ReactNode; delay?: number }) {
  const elementRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const element = elementRef.current;
    if (!element || !("IntersectionObserver" in window)) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          element.classList.remove("scroll-reveal-pending");
          element.classList.add("scroll-reveal-visible");
          observer.disconnect();
        } else {
          element.classList.add("scroll-reveal-pending");
        }
      },
      { threshold: 0.08, rootMargin: "0px 0px -32px 0px" }
    );

    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  return <div ref={elementRef} className="scroll-reveal" style={{ transitionDelay: `${delay}ms` }}>{children}</div>;
}
