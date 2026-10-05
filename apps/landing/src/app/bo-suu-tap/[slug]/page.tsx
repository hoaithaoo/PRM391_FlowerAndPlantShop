import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { COLLECTIONS, getCollection } from "@/data/collections";
import { ScrollReveal } from "@/components/scroll-reveal";
import { Footer } from "@/components/footer";

type Params = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return COLLECTIONS.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const collection = getCollection((await params).slug);
  if (!collection) return {};
  return {
    title: `${collection.title} • Nhà Có Hoa`,
    description: collection.intro,
  };
}

export default async function CollectionPage({ params }: Params) {
  const collection = getCollection((await params).slug);
  if (!collection) notFound();

  const currentIndex = COLLECTIONS.findIndex((c) => c.slug === collection.slug);
  const next = COLLECTIONS[(currentIndex + 1) % COLLECTIONS.length];

  return (
    <div style={{ background: collection.tint }} className="min-h-screen">
      {/* Top bar */}
      <header className="absolute inset-x-0 top-0 z-30 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-5 flex items-center justify-between">
          <Link href="/" className="font-editorial text-2xl sm:text-3xl tracking-wide">Nhà Có Hoa</Link>
          <Link
            href="/#collection"
            className="text-xs uppercase tracking-[0.18em] border border-white/50 rounded-full px-4 py-2 hover:bg-white/15 transition-colors"
          >
            ← Tất cả bộ sưu tập
          </Link>
        </div>
      </header>

      {/* Cover */}
      <section className="relative h-[85vh] min-h-[520px] overflow-hidden">
        <Image
          src={collection.coverUrl}
          alt={collection.title}
          fill
          priority
          sizes="100vw"
          className="object-cover collection-cover-zoom"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-black/30" />
        <div className="absolute inset-x-0 bottom-0 max-w-7xl mx-auto px-4 sm:px-6 pb-14 sm:pb-20 text-white collection-cover-text">
          <p className="text-xs sm:text-sm uppercase tracking-[0.25em] text-white/80">
            Bộ sưu tập {collection.index} • {collection.region}
          </p>
          <h1 className="font-editorial text-4xl sm:text-6xl lg:text-7xl mt-3 max-w-4xl leading-tight font-normal">
            {collection.title}
          </h1>
          <p className="mt-4 text-base sm:text-lg text-white/85 max-w-xl font-light">{collection.tagline}</p>
        </div>
      </section>

      {/* Concept Showcase (if present) */}
      {collection.concept ? (
        <section className="border-t border-forest-950/10 py-20 sm:py-28 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <ScrollReveal>
            <div className="text-center max-w-3xl mx-auto mb-14 sm:mb-20 space-y-4">
              <span className="text-xs uppercase tracking-[0.25em] text-petal-500 font-semibold block">
                Concept Triển Lãm Mỹ Thuật Đương Đại
              </span>
              <h2 className="font-editorial text-3xl sm:text-5xl lg:text-6xl font-normal text-forest-950">
                {collection.concept.theme}
              </h2>
              <p className="text-sm sm:text-base text-charcoal-700 leading-relaxed font-light">
                {collection.concept.subtitle}
              </p>
            </div>
          </ScrollReveal>

          {/* Panoramic Concept Photo Stage */}
          <ScrollReveal>
            <div className="relative rounded-[2.5rem] overflow-hidden shadow-2xl bg-white border border-forest-950/10">
              <div className="relative aspect-[16/9] w-full">
                <Image
                  src={collection.coverUrl}
                  alt={collection.concept.theme}
                  fill
                  priority
                  sizes="100vw"
                  className="object-cover"
                />
              </div>

              {/* Photo Concept Specs */}
              <div className="p-6 sm:p-10 bg-white/95 backdrop-blur-md border-t border-forest-950/5">
                <p className="text-xs uppercase tracking-[0.22em] text-petal-500 font-semibold mb-4">
                  Không Gian & Ngôn Ngữ Thị Giác Của Buổi Chụp
                </p>
                <div className="grid sm:grid-cols-3 gap-6 text-sm text-charcoal-700">
                  <div className="space-y-1.5">
                    <span className="font-semibold text-forest-950 block">Ánh Sáng (Lighting)</span>
                    <p className="font-light leading-relaxed">{collection.concept.photoDetails.lighting}</p>
                  </div>
                  <div className="space-y-1.5">
                    <span className="font-semibold text-forest-950 block">Không Gian (Space)</span>
                    <p className="font-light leading-relaxed">{collection.concept.photoDetails.space}</p>
                  </div>
                  <div className="space-y-1.5">
                    <span className="font-semibold text-forest-950 block">Chất Liệu Phối Cảnh (Materials)</span>
                    <p className="font-light leading-relaxed">{collection.concept.photoDetails.materials}</p>
                  </div>
                </div>
              </div>
            </div>
          </ScrollReveal>

          {/* 5 Artworks in the Photo */}
          {collection.concept.artworks && collection.concept.artworks.length > 0 && (
            <div className="mt-16 sm:mt-24">
              <ScrollReveal>
                <div className="text-center max-w-2xl mx-auto mb-10">
                  <span className="text-xs uppercase tracking-[0.22em] text-forest-700 font-semibold block">
                    Tuyển Tập Tác Phẩm
                  </span>
                  <h3 className="font-editorial text-2xl sm:text-4xl font-normal text-forest-950 mt-2">
                    5 Thế Cắm Sen Nghệ Thuật Trong Buổi Trưng Bày
                  </h3>
                </div>
              </ScrollReveal>

              <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {collection.concept.artworks.map((art, idx) => (
                  <ScrollReveal key={art.id} delay={idx * 60}>
                    <div className="h-full rounded-3xl bg-white/80 border border-forest-950/5 p-6 sm:p-8 flex flex-col justify-between hover:shadow-lg transition-shadow">
                      <div>
                        <div className="flex items-center justify-between gap-3 text-xs uppercase tracking-widest text-petal-500 font-semibold mb-3">
                          <span>Tác phẩm {art.id}</span>
                          <span className="px-2.5 py-1 rounded-full bg-petal-100 text-[11px] text-forest-900 font-normal">
                            {art.vessel}
                          </span>
                        </div>
                        <h4 className="font-editorial text-2xl sm:text-3xl text-forest-950 mb-3 font-normal">
                          {art.name}
                        </h4>
                        <p className="text-xs sm:text-sm text-charcoal-700 font-light leading-relaxed">
                          {art.desc}
                        </p>
                      </div>
                    </div>
                  </ScrollReveal>
                ))}
              </div>
            </div>
          )}

          {/* Story & Handcrafted Pottery Showcase (Image 1: Chậu Vân Sen Đăng Đối & Vũ Khúc Hương Đêm) */}
          {collection.concept.storyImageUrl && (
            <div className="mt-20 sm:mt-28">
              <ScrollReveal>
                <div className="rounded-[2.5rem] overflow-hidden bg-white/90 border border-forest-950/10 shadow-xl">
                  <div className="relative aspect-[16/9] w-full">
                    <Image
                      src={collection.concept.storyImageUrl}
                      alt="Câu chuyện: Vẻ đẹp hoa sen - Chậu Vân Sen Đăng Đối & Vũ Khúc Hương Đêm"
                      fill
                      sizes="100vw"
                      className="object-cover"
                    />
                  </div>

                  {collection.concept.storyExcerpt && (
                    <div className="p-8 sm:p-14 bg-[#FFF9F6] border-t border-forest-950/5">
                      <div className="max-w-4xl mx-auto text-center space-y-5">
                        <span className="text-xs uppercase tracking-[0.25em] text-petal-500 font-semibold block">
                          Gốm Thủ Công Độc Bản & Quốc Hoa Việt Nam
                        </span>
                        <h3 className="font-editorial text-3xl sm:text-5xl text-forest-950 font-normal tracking-wide">
                          {collection.concept.storyExcerpt.title}
                        </h3>
                        <blockquote className="font-editorial text-xl sm:text-2xl text-forest-800 italic max-w-2xl mx-auto font-light leading-relaxed">
                          “{collection.concept.storyExcerpt.quote}”
                        </blockquote>
                        <div className="space-y-3 pt-2 text-sm sm:text-base text-charcoal-700 font-light leading-relaxed max-w-3xl mx-auto">
                          {collection.concept.storyExcerpt.content.map((p, i) => (
                            <p key={i}>{p}</p>
                          ))}
                        </div>

                        {/* Featured Artworks Badges */}
                        <div className="grid sm:grid-cols-2 gap-6 pt-6 text-left">
                          {collection.concept.storyExcerpt.artworksFeatured.map((item) => (
                            <div key={item.name} className="p-6 rounded-2xl bg-white border border-forest-950/5 shadow-sm">
                              <h4 className="font-editorial text-xl sm:text-2xl font-normal text-forest-950 mb-2">
                                {item.name}
                              </h4>
                              <p className="text-xs sm:text-sm text-charcoal-700 font-light leading-relaxed">
                                {item.meaning}
                              </p>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </ScrollReveal>
            </div>
          )}

          {/* 3 Core Philosophical Questions: Lotus Nature, Why Chosen, Flower Meaning */}
          <div className="mt-20 sm:mt-28 space-y-14 sm:space-y-20">
            {/* 1. Hoa sen ở Đồng Tháp như thế nào? + Harvest Drone Image (Image 2) */}
            <ScrollReveal>
              <div className="rounded-[2.5rem] bg-white/85 border border-forest-950/10 p-8 sm:p-14 shadow-sm">
                <div className="max-w-3xl">
                  <span className="text-xs uppercase tracking-[0.22em] text-petal-500 font-semibold block">
                    Đặc Tính Bản Địa
                  </span>
                  <h3 className="font-editorial text-3xl sm:text-5xl text-forest-950 font-normal mt-2">
                    {collection.concept.regionNature.title}
                  </h3>
                  <p className="mt-4 text-sm sm:text-base text-charcoal-700 font-light leading-relaxed">
                    {collection.concept.regionNature.description}
                  </p>
                </div>

                {/* Drone Harvest Aerial Image */}
                {collection.concept.harvestImageUrl && (
                  <div className="mt-8 rounded-3xl overflow-hidden shadow-lg border border-forest-950/5 relative aspect-[16/9] w-full">
                    <Image
                      src={collection.concept.harvestImageUrl}
                      alt="Thu hoạch hoa sen 04:30 sáng tại Đồng Tháp Mười"
                      fill
                      sizes="100vw"
                      className="object-cover"
                    />
                    <div className="absolute inset-x-0 bottom-0 p-4 sm:p-6 bg-gradient-to-t from-black/80 via-black/30 to-transparent text-white">
                      <p className="text-xs uppercase tracking-widest text-petal-200 font-medium">
                        Khoảnh Khắc Đồng Tháp Mười
                      </p>
                      <p className="text-xs sm:text-sm text-white/90 font-light mt-1">
                        5 chiếc xuồng ba lá kết thành đóa hoa sen khổng lồ trên mặt nước châu thổ trong buổi hái sen tinh mơ 04:30 sáng.
                      </p>
                    </div>
                  </div>
                )}

                <div className="grid md:grid-cols-3 gap-6 sm:gap-8 mt-10 pt-10 border-t border-forest-950/10">
                  {collection.concept.regionNature.points.map((pt) => (
                    <div key={pt.title} className="space-y-2.5">
                      <div className="w-8 h-8 rounded-full bg-forest-900 text-cream-100 flex items-center justify-center text-xs font-semibold">
                        ✓
                      </div>
                      <h4 className="font-editorial text-xl font-normal text-forest-950">{pt.title}</h4>
                      <p className="text-xs sm:text-sm text-charcoal-700 font-light leading-relaxed">
                        {pt.desc}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </ScrollReveal>

            {/* 2. Vì sao Nhà Có Hoa mang hoa sen vào concept này? */}
            <ScrollReveal>
              <div className="rounded-[2.5rem] bg-[#F4EBE8] border border-forest-950/10 p-8 sm:p-14 shadow-sm">
                <div className="max-w-3xl">
                  <span className="text-xs uppercase tracking-[0.22em] text-forest-800 font-semibold block">
                    Cảm Hứng Giám Tuyển
                  </span>
                  <h3 className="font-editorial text-3xl sm:text-5xl text-forest-950 font-normal mt-2">
                    {collection.concept.whyThisConcept.title}
                  </h3>
                  <p className="mt-4 text-sm sm:text-base text-charcoal-700 font-light leading-relaxed">
                    {collection.concept.whyThisConcept.description}
                  </p>
                </div>

                <div className="grid md:grid-cols-3 gap-6 sm:gap-8 mt-10 pt-10 border-t border-forest-950/10">
                  {collection.concept.whyThisConcept.points.map((pt) => (
                    <div key={pt.title} className="space-y-2.5">
                      <div className="w-8 h-8 rounded-full bg-petal-500 text-white flex items-center justify-center text-xs font-semibold">
                        ✦
                      </div>
                      <h4 className="font-editorial text-xl font-normal text-forest-950">{pt.title}</h4>
                      <p className="text-xs sm:text-sm text-charcoal-700 font-light leading-relaxed">
                        {pt.desc}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </ScrollReveal>

            {/* 3. Ý nghĩa sâu sắc của Hoa Sen */}
            <ScrollReveal>
              <div className="rounded-[2.5rem] bg-forest-950 text-cream-100 p-8 sm:p-14 shadow-xl">
                <div className="max-w-3xl">
                  <span className="text-xs uppercase tracking-[0.22em] text-petal-300 font-semibold block">
                    Triết Lý Sống & Tâm Linh
                  </span>
                  <h3 className="font-editorial text-3xl sm:text-5xl text-white font-normal mt-2">
                    {collection.concept.flowerMeaning.title}
                  </h3>
                  <p className="mt-4 text-sm sm:text-base text-white/80 font-light leading-relaxed">
                    {collection.concept.flowerMeaning.description}
                  </p>
                </div>

                <div className="grid md:grid-cols-3 gap-6 sm:gap-8 mt-10 pt-10 border-t border-white/15">
                  {collection.concept.flowerMeaning.points.map((pt) => (
                    <div key={pt.title} className="space-y-2.5">
                      <div className="w-8 h-8 rounded-full bg-petal-400 text-forest-950 flex items-center justify-center text-xs font-bold">
                        ♥
                      </div>
                      <h4 className="font-editorial text-xl font-normal text-petal-100">{pt.title}</h4>
                      <p className="text-xs sm:text-sm text-white/85 font-light leading-relaxed">
                        {pt.desc}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </ScrollReveal>
          </div>
        </section>
      ) : (
        /* Why this collection (fallback when no detailed concept) */
        <section className="max-w-3xl mx-auto px-6 py-20 sm:py-28 text-center">
          <ScrollReveal>
            <p className="text-xs uppercase tracking-[0.22em] text-forest-700 font-semibold">
              Vì sao có bộ sưu tập này
            </p>
            <p className="mt-6 font-editorial text-2xl sm:text-3xl text-forest-950 leading-relaxed font-normal">
              {collection.intro}
            </p>
            <p className="mt-6 text-sm sm:text-base text-charcoal-700 leading-relaxed font-light">
              {collection.whyThisCollection}
            </p>
          </ScrollReveal>
        </section>
      )}

      {/* Flower chapters (Display Guide, Occasions, Care) */}
      {collection.flowers.map((flower, i) => (
        <article key={flower.slug} id={flower.slug} className="border-t border-forest-950/10">
          <div className="max-w-6xl mx-auto px-6 py-20 sm:py-28">
            {/* Display guide */}
            <ScrollReveal>
              <div>
                <span className="text-xs uppercase tracking-[0.22em] text-petal-500 font-semibold block">
                  Cẩm Nang Chưng Hoa
                </span>
                <h3 className="font-editorial text-3xl sm:text-4xl text-forest-950 font-normal mt-2">
                  Cách chưng & hướng đặt {flower.name.toLowerCase()}
                </h3>
                <dl className="mt-8 grid sm:grid-cols-3 gap-8">
                  <div className="rounded-2xl bg-white/70 p-6 border border-forest-950/5">
                    <dt className="text-xs uppercase tracking-[0.2em] text-forest-700 font-semibold">Vị trí & hướng</dt>
                    <dd className="mt-3 text-sm text-charcoal-700 leading-relaxed font-light">{flower.display.placement}</dd>
                  </div>
                  <div className="rounded-2xl bg-white/70 p-6 border border-forest-950/5">
                    <dt className="text-xs uppercase tracking-[0.2em] text-forest-700 font-semibold">Bình phù hợp</dt>
                    <dd className="mt-3 text-sm text-charcoal-700 leading-relaxed font-light">{flower.display.vessel}</dd>
                  </div>
                  <div className="rounded-2xl bg-white/70 p-6 border border-forest-950/5">
                    <dt className="text-xs uppercase tracking-[0.2em] text-forest-700 font-semibold">Cách cắm nghệ thuật</dt>
                    <dd className="mt-3 text-sm text-charcoal-700 leading-relaxed font-light">{flower.display.arrangement}</dd>
                  </div>
                </dl>

                <div className="mt-10 grid md:grid-cols-2 gap-8">
                  <div className="rounded-3xl bg-white/70 p-7 sm:p-9 border border-forest-950/5">
                    <h4 className="text-xs uppercase tracking-[0.2em] text-forest-700 font-semibold">Bí quyết giữ hoa tươi lâu</h4>
                    <ol className="mt-4 space-y-2.5 text-sm text-charcoal-700 font-light list-decimal pl-5">
                      {flower.display.care.map((tip) => <li key={tip}>{tip}</li>)}
                    </ol>
                  </div>
                  <div className="rounded-3xl bg-white/70 p-7 sm:p-9 border border-forest-950/5">
                    <h4 className="text-xs uppercase tracking-[0.2em] text-forest-700 font-semibold">Dịp phù hợp nhất</h4>
                    <ul className="mt-4 flex flex-wrap gap-2.5">
                      {flower.occasions.map((o) => (
                        <li key={o} className="px-3.5 py-2 rounded-full bg-forest-950 text-white text-xs font-light">{o}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            </ScrollReveal>
          </div>
        </article>
      ))}

      {/* Next collection */}
      <Link href={`/bo-suu-tap/${next.slug}`} className="group block relative h-[50vh] min-h-[320px] overflow-hidden">
        <Image src={next.coverUrl} alt={next.title} fill sizes="100vw" className="object-cover group-hover:scale-[1.03] transition-transform duration-700" />
        <div className="absolute inset-0 bg-black/50 group-hover:bg-black/40 transition-colors" />
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center text-white px-6">
          <p className="text-xs uppercase tracking-[0.25em] text-white/80">Bộ sưu tập tiếp theo • {next.region}</p>
          <p className="font-editorial text-3xl sm:text-5xl mt-3 font-normal">{next.title}</p>
          <span className="mt-5 text-sm underline underline-offset-8">Khám phá →</span>
        </div>
      </Link>

      <Footer />
    </div>
  );
}
