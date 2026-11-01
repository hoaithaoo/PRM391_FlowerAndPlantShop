import { TESTIMONIALS } from "@/data/mock-data";

export function Testimonials() {
  return (
    <section id="reviews" className="py-20 sm:py-28 bg-petal-50">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-2xl mx-auto text-center mb-12">
          <p className="text-sm uppercase tracking-widest text-charcoal-600">Đánh giá từ khách hàng</p>
          <h2 className="font-serif text-4xl sm:text-5xl text-forest-950 mt-4">Những lời thương gửi lại</h2>
          <p className="text-sm text-charcoal-600 mt-5">Nội dung minh họa — sẽ được thay bằng đánh giá thực tế của khách hàng.</p>
        </div>
        <div className="grid md:grid-cols-3 gap-6">
          {TESTIMONIALS.map((item) => (
            <figure key={item.id} className="rounded-3xl border border-petal-200 bg-white p-7 flex flex-col">
              <p className="text-sm text-charcoal-600 mb-5">Đánh giá mẫu · {item.rating}/5</p>
              <blockquote className="text-base leading-relaxed text-forest-950 flex-1">“{item.content}”</blockquote>
              <figcaption className="mt-7 pt-5 border-t border-petal-100">
                <span className="block font-semibold text-forest-950">{item.author}</span>
                <span className="text-sm text-charcoal-600">{item.role}</span>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
