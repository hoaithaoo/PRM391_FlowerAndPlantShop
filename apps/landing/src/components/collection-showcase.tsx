import Image from "next/image";
import Link from "next/link";
import { COLLECTIONS } from "@/data/collections";
import { ScrollReveal } from "@/components/scroll-reveal";

export function CollectionShowcase() {
  return (
    <section id="collection" className="py-20 sm:py-32 bg-[#FAF6F0] border-b border-cream-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16 sm:mb-24 space-y-4">
          <span className="text-xs uppercase tracking-[0.25em] text-forest-800 font-semibold block">
            Phòng Trưng Bày Tác Phẩm • Concept Collections
          </span>
          <h2 className="font-serif text-3xl sm:text-5xl lg:text-6xl font-bold text-forest-950">
            Hương Sắc Ba Miền
          </h2>
          <p className="text-sm sm:text-base text-charcoal-700 max-w-2xl mx-auto leading-relaxed font-light">
            Ba vùng đất, ba câu chuyện. Mỗi bộ sưu tập kể về những loài hoa chúng tôi chọn, vì sao chọn và cách chưng để hoa nói trọn thông điệp của mình.
          </p>
        </div>

        <div className="space-y-10 sm:space-y-14">
          {COLLECTIONS.map((c) => (
            <ScrollReveal key={c.slug}>
              <Link
                href={`/bo-suu-tap/${c.slug}`}
                className="group relative block h-[60vh] min-h-[420px] rounded-[2rem] overflow-hidden shadow-xl"
              >
                <Image
                  src={c.coverUrl}
                  alt={c.title}
                  fill
                  sizes="100vw"
                  className="object-cover group-hover:scale-[1.03] transition-transform duration-700 ease-out"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/15 to-transparent" />
                <div className="absolute inset-x-0 bottom-0 p-7 sm:p-12 text-white flex flex-col sm:flex-row sm:items-end justify-between gap-6">
                  <div>
                    <p className="text-xs uppercase tracking-[0.25em] text-white/80">
                      {c.index} • {c.region}
                    </p>
                    <h3 className="font-serif text-3xl sm:text-5xl mt-2">{c.title}</h3>
                    <p className="mt-3 text-sm sm:text-base text-white/85 max-w-lg">{c.tagline}</p>
                    <p className="mt-3 text-xs text-white/70">
                      {c.flowers.map((f) => f.name).join(" · ")}
                    </p>
                  </div>
                  <span className="shrink-0 text-sm underline underline-offset-8 decoration-white/50 group-hover:decoration-white">
                    Xem bộ sưu tập →
                  </span>
                </div>
              </Link>
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  );
}

