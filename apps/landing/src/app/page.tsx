"use client";

import React from "react";
import { Hero } from "@/components/hero";
import { CategoryGrid } from "@/components/category-grid";
import { CollectionShowcase } from "@/components/collection-showcase";
import { OccasionSelector } from "@/components/occasion-selector";
import { WhyChooseUs } from "@/components/why-choose-us";
import { Testimonials } from "@/components/testimonials";
import { AppDownloadSection } from "@/components/app-download-section";
import { ScrollReveal } from "@/components/scroll-reveal";
import { Footer } from "@/components/footer";
import { StoreLocations } from "@/components/store-locations";

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col bg-cream-100 selection:bg-petal-200 selection:text-charcoal-900">
      {/* Main Content Sections */}
      <main className="flex-1">
        <Hero />
        <div className="landing-content">
          <CategoryGrid />
          
          {/* Concept Collections Art Exhibition (Đồng Tháp, Đà Lạt, Tây Bắc) */}
          <ScrollReveal>
            <CollectionShowcase />
          </ScrollReveal>

          {/* Occasion Lookbook */}
          <ScrollReveal>
            <OccasionSelector />
          </ScrollReveal>

          {/* Founder Story with photo */}
          <ScrollReveal>
            <WhyChooseUs />
          </ScrollReveal>

          {/* Testimonials */}
          <ScrollReveal>
            <Testimonials />
          </ScrollReveal>

          {/* Store & Atelier Locations */}
          <ScrollReveal>
            <StoreLocations />
          </ScrollReveal>

          {/* App Download */}
          <ScrollReveal>
            <AppDownloadSection />
          </ScrollReveal>
        </div>
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}
