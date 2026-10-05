const appStoreUrl = process.env.NEXT_PUBLIC_APP_STORE_URL;
const googlePlayUrl = process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL;

type StoreButtonProps = {
  label: string;
  url?: string;
};

function StoreButton({ label, url }: StoreButtonProps) {
  const className = "min-h-20 inline-flex w-60 items-center gap-4 rounded-2xl border border-white/20 px-5 py-4 text-left transition-colors";
  const content = <>
    <Image src={label === "App Store" ? "/brand/app-store.png" : "/brand/google-play.png"} alt="" width={40} height={40} className="h-10 w-10 object-contain shrink-0" />
    <span><span className="block text-xs text-white/70">{url ? "Tải ứng dụng trên" : "Sắp ra mắt trên"}</span><span className="block text-xl font-semibold text-white">{label}</span></span>
  </>;

  if (!url) {
    return (
      <button type="button" disabled className={`${className} cursor-not-allowed bg-white/5`}>
        {content}
      </button>
    );
  }

  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className={`${className} bg-white/10 hover:bg-white/20`}
    >
      {content}
    </a>
  );
}

export function AppDownloadSection() {
  return (
    <section id="app-download" className="py-16 sm:py-24 bg-cream-100">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="relative overflow-hidden rounded-[2rem] bg-forest-900 px-6 py-12 sm:px-12 sm:py-16 text-center text-white">
          <div className="absolute -top-24 -right-20 h-64 w-64 rounded-full bg-petal-400/20 blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -left-20 h-64 w-64 rounded-full bg-petal-300/15 blur-3xl pointer-events-none" />
          <div className="relative mx-auto max-w-2xl space-y-5">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-petal-200">
              Nhà Có Hoa trên điện thoại
            </p>
            <h2 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold leading-tight">
              Mang cảm hứng xanh theo bạn mỗi ngày
            </h2>
            <p className="text-sm sm:text-base leading-relaxed text-white/75">
              Ứng dụng đang được hoàn thiện. Theo dõi Nhà Có Hoa để nhận thông tin ngay khi có mặt trên cửa hàng ứng dụng.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
              <StoreButton label="App Store" url={appStoreUrl} />
              <StoreButton label="Google Play" url={googlePlayUrl} />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
import Image from "next/image";
