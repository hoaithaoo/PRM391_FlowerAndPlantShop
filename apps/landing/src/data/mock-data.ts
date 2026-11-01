export interface Product {
  id: string;
  name: string;
  slug: string;
  category: "bouquet" | "plant" | "orchid" | "gift";
  categoryName: string;
  price: number;
  originalPrice?: number;
  rating: number;
  reviewCount: number;
  imageUrl: string;
  tags: string[];
  description: string;
  isBestSeller?: boolean;
  isNew?: boolean;
  stock: number;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  count: number;
  imageUrl: string;
  description: string;
}

export interface Occasion {
  id: string;
  title: string;
  subtitle: string;
  iconName: string;
  imageUrl: string;
}

export interface Testimonial {
  id: string;
  author: string;
  role: string;
  avatarUrl: string;
  rating: number;
  content: string;
  flowerPurchased: string;
  date: string;
}

export interface StoreLocation {
  id: string;
  name: string;
  address: string;
  district: string;
  city: string;
  phone: string;
  hours: string;
  mapQuery: string;
}

export interface Article {
  id: string;
  title: string;
  category: string;
  readTime: string;
  imageUrl: string;
  excerpt: string;
  date: string;
}

export const CATEGORIES: Category[] = [
  {
    id: "cat-1",
    name: "Bó Hoa Tươi Thiết Kế",
    slug: "bo-hoa-thiet-ke",
    count: 48,
    imageUrl: "https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=800&q=80",
    description: "Tuyển chọn hoa tươi Đà Lạt và nhập khẩu Hà Lan, cắm thủ công bởi Floral Artist.",
  },
  {
    id: "cat-2",
    name: "Cây Cảnh Nội Thất",
    slug: "cay-canh-noi-that",
    count: 36,
    imageUrl: "https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=800&q=80",
    description: "Cây lọc không khí, cây phong thủy bàn làm việc trong chậu gốm mộc tinh tế.",
  },
  {
    id: "cat-3",
    name: "Lan Hồ Điệp Hoàng Gia",
    slug: "lan-ho-diep",
    count: 24,
    imageUrl: "https://images.unsplash.com/photo-1525310072745-f49212b5ac6d?auto=format&fit=crop&w=800&q=80",
    description: "Biểu tượng của sự sang trọng, thịnh vượng và bền lâu từ 6 đến 8 tuần.",
  },
  {
    id: "cat-4",
    name: "Hoa Khô & Gift Set",
    slug: "hoa-kho-gift-set",
    count: 19,
    imageUrl: "https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&w=800&q=80",
    description: "Set quà tặng hoa khô nghệ thuật kèm nến thơm thủ công và thiệp viết tay.",
  },
];

export const PRODUCTS: Product[] = [
  {
    id: "prod-1",
    name: "Pastel Meadow Reverie",
    slug: "pastel-meadow-reverie",
    category: "bouquet",
    categoryName: "Bó hoa tươi",
    price: 680000,
    originalPrice: 780000,
    rating: 4.9,
    reviewCount: 128,
    imageUrl: "https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=800&q=80",
    tags: ["Best Seller", "Giảm 13%"],
    description: "Sự kết hợp tinh khôi giữa hoa hồng kem dâu, cúc Tana, cát tường và lá bạc Eucalyptus.",
    isBestSeller: true,
    stock: 25,
  },
  {
    id: "prod-2",
    name: "Monstera Deliciosa Thụy Điển",
    slug: "monstera-deliciosa",
    category: "plant",
    categoryName: "Cây nội thất",
    price: 520000,
    rating: 4.8,
    reviewCount: 94,
    imageUrl: "https://images.unsplash.com/photo-1614594975525-e45190c55d0b?auto=format&fit=crop&w=800&q=80",
    tags: ["Lọc không khí", "Dễ chăm"],
    description: "Cây trầu bà lá xẻ Nam Mỹ trong chậu gốm tráng men mờ, biểu tượng sức sống tràn đầy.",
    isBestSeller: true,
    stock: 18,
  },
  {
    id: "prod-3",
    name: "Pure White Phalaenopsis",
    slug: "pure-white-phalaenopsis",
    category: "orchid",
    categoryName: "Lan hồ điệp",
    price: 1450000,
    originalPrice: 1650000,
    rating: 5.0,
    reviewCount: 67,
    imageUrl: "https://images.unsplash.com/photo-1525310072745-f49212b5ac6d?auto=format&fit=crop&w=800&q=80",
    tags: ["Cao cấp", "Hoa bền 2 tháng"],
    description: "Chậu lan hồ điệp trắng 5 cành tuyển chọn đại đóa, uốn lượn phong cách Ikebana Nhật Bản.",
    isBestSeller: true,
    stock: 10,
  },
  {
    id: "prod-4",
    name: "Terracotta Autumn Rose",
    slug: "terracotta-autumn-rose",
    category: "bouquet",
    categoryName: "Bó hoa tươi",
    price: 750000,
    rating: 4.9,
    reviewCount: 82,
    imageUrl: "https://images.unsplash.com/photo-1582794543139-8ac9cb0f7b11?auto=format&fit=crop&w=800&q=80",
    tags: ["Mới về"],
    description: "Tone màu cam đất ấm áp của hoa hồng Juliet, mao lương cam và quả chuỗi ngọc thanh nhã.",
    isNew: true,
    stock: 14,
  },
  {
    id: "prod-5",
    name: "Fiddle Leaf Fig (Bàng Singapore)",
    slug: "fiddle-leaf-fig",
    category: "plant",
    categoryName: "Cây nội thất",
    price: 650000,
    rating: 4.7,
    reviewCount: 46,
    imageUrl: "https://images.unsplash.com/photo-1597055181300-e3633a917c9c?auto=format&fit=crop&w=800&q=80",
    tags: ["Phong thủy phòng khách"],
    description: "Dáng cây thẳng đứng tán lá to tròn xanh bóng, mang lại nguồn năng lượng tích cực cho gia chủ.",
    stock: 12,
  },
  {
    id: "prod-6",
    name: "Ethereal Lavender Gift Box",
    slug: "ethereal-lavender-gift-box",
    category: "gift",
    categoryName: "Gift Set",
    price: 490000,
    originalPrice: 550000,
    rating: 4.9,
    reviewCount: 53,
    imageUrl: "https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&w=800&q=80",
    tags: ["Kèm nến thơm"],
    description: "Bó oải hương khô Pháp lưu hương 1 năm kết hợp cùng nến thơm sáp đậu nành tinh dầu hữu cơ.",
    stock: 20,
  },
  {
    id: "prod-7",
    name: "Crimson Velvet Romance",
    slug: "crimson-velvet-romance",
    category: "bouquet",
    categoryName: "Bó hoa tươi",
    price: 890000,
    rating: 5.0,
    reviewCount: 112,
    imageUrl: "https://images.unsplash.com/photo-1562690868-60bbe7293e94?auto=format&fit=crop&w=800&q=80",
    tags: ["Tình yêu", "Bán chạy"],
    description: "33 đóa hồng đỏ Ohara thơm ngát kết hợp giấy gói đen mờ sang trọng, tặng thiệp dập nổi cao cấp.",
    isBestSeller: true,
    stock: 16,
  },
  {
    id: "prod-8",
    name: "Olive Tree (Cây Oliu Địa Trung Hải)",
    slug: "olive-tree-mediterranean",
    category: "plant",
    categoryName: "Cây nội thất",
    price: 850000,
    rating: 4.9,
    reviewCount: 39,
    imageUrl: "https://images.unsplash.com/photo-1509423350716-97f9360b4e09?auto=format&fit=crop&w=800&q=80",
    tags: ["Xu hướng thiết kế"],
    description: "Cây Oliu biểu tượng của hòa bình và sự tối giản Scandinavian, thích hợp không gian quán cafe & căn hộ.",
    isNew: true,
    stock: 9,
  },
];

export const OCCASIONS: Occasion[] = [
  {
    id: "occ-1",
    title: "Sinh Nhật & Kỷ Niệm",
    subtitle: "Rạng rỡ từng khoảnh khắc ngọt ngào",
    iconName: "Gift",
    imageUrl: "https://images.unsplash.com/photo-1533616688419-b7a585564566?auto=format&fit=crop&w=600&q=80",
  },
  {
    id: "occ-2",
    title: "Tình Yêu & Lãng Mạn",
    subtitle: "Thay lời yêu thương chân thành",
    iconName: "Heart",
    imageUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80",
  },
  {
    id: "occ-3",
    title: "Khai Trương & Hồng Phát",
    subtitle: "Vận may thịnh vượng, tài lộc dồi dào",
    iconName: "Sparkles",
    imageUrl: "https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=600&q=80",
  },
  {
    id: "occ-4",
    title: "Cảm Ơn & Tri Ân",
    subtitle: "Sự tinh tế trong từng thông điệp",
    iconName: "Smile",
    imageUrl: "https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80",
  },
];

export const FEATURES = [
  {
    icon: "Truck",
    title: "Giao Hỏa Tốc Trong 2H",
    description: "Giao nhanh nội thành, bảo quản thùng chuyên dụng chống dập cánh và giữ lạnh độ tươi tối đa.",
  },
  {
    icon: "Sparkles",
    title: "Hoa Nông Trại Cắt Trong Ngày",
    description: "100% tuyển lựa trực tiếp từ nhà vườn Đà Lạt đạt chuẩn canh tác hữu cơ, cam kết tươi trên 5 ngày.",
  },
  {
    icon: "HeartHandshake",
    title: "Thiết Kế Độc Bản Theo Yêu Cầu",
    description: "Đội ngũ Florist tư vấn tone màu, chọn hoa theo thông điệp và tặng kèm thiệp thiết kế viết tay.",
  },
  {
    icon: "ShieldCheck",
    title: "Bảo Hành Tươi & Đổi Mới 100%",
    description: "Chụp ảnh thành phẩm gửi quý khách trước khi giao, hoàn tiền hoặc đổi ngay nếu hoa không đạt chuẩn.",
  },
];

export const TESTIMONIALS: Testimonial[] = [
  {
    id: "t-1",
    author: "Thu Trang Nguyễn",
    role: "Khách hàng thân thiết (Quận 1, TP.HCM)",
    avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80",
    rating: 5,
    content: "Đặt bó Pastel Meadow tặng sinh nhật bạn thân lúc 9h sáng, đúng 10h30 đã giao đến tận tay văn phòng. Hoa tươi mơn mởn, giấy gói nhã nhặn và có mùi thơm tự nhiên rất dễ chịu.",
    flowerPurchased: "Pastel Meadow Reverie",
    date: "2 ngày trước",
  },
  {
    id: "t-2",
    author: "Minh Quân Trần",
    role: "Kiến trúc sư nội thất",
    avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80",
    rating: 5,
    content: "Cây Monstera và chậu Oliu mình mua cho studio decor nhận được lời khen của rất nhiều khách. Đất trồng sạch, cây khỏe và shop còn gửi kèm cẩm nang chăm sóc rất chu đáo!",
    flowerPurchased: "Monstera Deliciosa & Olive Tree",
    date: "1 tuần trước",
  },
  {
    id: "t-3",
    author: "Hoàng Yến Lê",
    role: "Quản lý sự kiện",
    avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80",
    rating: 5,
    content: "Chậu Lan Hồ Điệp trắng đặt chúc mừng đối tác khai trương sang xịn vượt mong đợi. Có video quay lại từng góc chậu trước khi xuất xưởng, phục vụ cực kỳ chuyên nghiệp.",
    flowerPurchased: "Pure White Phalaenopsis",
    date: "3 tuần trước",
  },
];

export const STORE_LOCATIONS: StoreLocation[] = [
  {
    id: "store-1",
    name: "Atelier & Flagship Store Thảo Điền",
    address: "Số 68 Đường Xuân Thủy, Phường Thảo Điền",
    district: "Thành phố Thủ Đức",
    city: "TP. Hồ Chí Minh",
    phone: "090 123 4567",
    hours: "08:00 - 21:30 hàng ngày",
    mapQuery: "Xuan Thuy Thao Dien Ho Chi Minh",
  },
  {
    id: "store-2",
    name: "Boutique Cửa Nam",
    address: "Số 15 Phố Cửa Nam, Phường Cửa Nam",
    district: "Quận Hoàn Kiếm",
    city: "Hà Nội",
    phone: "098 765 4321",
    hours: "08:30 - 21:00 hàng ngày",
    mapQuery: "Cua Nam Hoan Kiem Ha Noi",
  },
  {
    id: "store-3",
    name: "Vườn Ươm & Farmhouse Đà Lạt",
    address: "Đường Mimosa, Phường 10",
    district: "Thành phố Đà Lạt",
    city: "Lâm Đồng",
    phone: "093 345 6789",
    hours: "07:30 - 18:00 (Tham quan & thu hoạch)",
    mapQuery: "Duong Mimosa Da Lat",
  },
];

export const ARTICLES: Article[] = [
  {
    id: "art-1",
    title: "5 Bí Quyết Vàng Giúp Bó Hoa Tươi Lâu Hơn 7 Ngày Trong Phòng Máy Lạnh",
    category: "Mẹo Chăm Hoa",
    readTime: "4 phút đọc",
    imageUrl: "https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=800&q=80",
    excerpt: "Kỹ thuật cắt gốc góc 45 độ, pha dung dịch dinh dưỡng tự nhiên và vị trí đặt hoa lý tưởng tránh ánh nắng trực tiếp.",
    date: "02 Tháng 10, 2026",
  },
  {
    id: "art-2",
    title: "Top 6 Cây Cảnh Lọc Bụi Mịn & Khí Độc Tốt Nhất Cho Phòng Ngủ Hiện Đại",
    category: "Cây Phong Thủy",
    readTime: "6 phút đọc",
    imageUrl: "https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=800&q=80",
    excerpt: "Monstera, Lưỡi Hổ và Kim Ngân không chỉ làm đẹp không gian mà còn nhả oxy về đêm mang lại giấc ngủ thư thái.",
    date: "28 Tháng 9, 2026",
  },
  {
    id: "art-3",
    title: "Nghệ Thuật Cắm Hoa Ikebana: Tìm Lại Sự Tĩnh Lặng Trong Từng Cành Cây",
    category: "Phong Cách Sống",
    readTime: "5 phút đọc",
    imageUrl: "https://images.unsplash.com/photo-1508615039623-a25605d2b022?auto=format&fit=crop&w=800&q=80",
    excerpt: "Khám phá triết lý sống hòa hợp với thiên nhiên qua cách sắp đặt khoảng trống và đường cong của hoa lá.",
    date: "15 Tháng 9, 2026",
  },
];

