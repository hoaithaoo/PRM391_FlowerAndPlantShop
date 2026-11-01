"use client";

import { type ReactNode } from "react";
import { ScrollReveal } from "@/components/scroll-reveal";

export function ScrollZoom({ children }: { children: ReactNode }) {
  return (
    <div className="collection-intro">
      <ScrollReveal><div className="scroll-zoom">{children}</div></ScrollReveal>
    </div>
  );
}
