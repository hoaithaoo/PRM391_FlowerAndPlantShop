import { Prisma, PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main(): Promise<void> {
  const categories = await Promise.all([
    prisma.category.upsert({
      where: { slug: "hoa-tuoi" },
      update: { name: "Hoa tươi", isActive: true },
      create: { name: "Hoa tươi", slug: "hoa-tuoi" },
    }),
    prisma.category.upsert({
      where: { slug: "cay-canh" },
      update: { name: "Cây cảnh", isActive: true },
      create: { name: "Cây cảnh", slug: "cay-canh" },
    }),
    prisma.category.upsert({
      where: { slug: "phu-kien" },
      update: { name: "Phụ kiện", isActive: true },
      create: { name: "Phụ kiện", slug: "phu-kien" },
    }),
  ]);

  const categoryBySlug = new Map(
    categories.map((category) => [category.slug, category.id])
  );

  const products = [
    {
      categorySlug: "hoa-tuoi",
      name: "Bó hoa hồng đỏ",
      slug: "bo-hoa-hong-do",
      sku: "FLOWER-ROSE-001",
      description:
        "Bó hoa hồng đỏ mang phong cách trang trọng và lãng mạn, phù hợp làm quà sinh nhật, kỷ niệm hoặc gửi lời chúc. Khi cắm bình, nên đặt hoa ở nơi thoáng mát, tránh nắng trực tiếp và nguồn nhiệt. Thay nước sạch mỗi ngày, cắt chéo một đoạn nhỏ ở gốc và loại bỏ lá nằm dưới mặt nước để hoa giữ được độ tươi lâu hơn.",
      price: "250000",
      stock: 50,
      taxRate: "8.00",
    },
    {
      categorySlug: "hoa-tuoi",
      name: "Bó hoa hướng dương",
      slug: "bo-hoa-huong-duong",
      sku: "FLOWER-SUN-001",
      description:
        "Bó hoa hướng dương có màu sắc tươi sáng, phù hợp làm quà chúc mừng, khai trương hoặc trang trí không gian. Khi cắm bình, đặt hoa ở nơi thoáng mát có ánh sáng dịu, tránh nắng gắt và luồng gió mạnh. Thay nước mỗi ngày, cắt chéo gốc hoa và giữ phần lá không ngập trong nước để hạn chế hư hỏng.",
      price: "320000",
      stock: 35,
      taxRate: "8.00",
    },
    {
      categorySlug: "cay-canh",
      name: "Cây lưỡi hổ",
      slug: "cay-luoi-ho",
      sku: "PLANT-SNAKE-001",
      description:
        "Cây lưỡi hổ là cây cảnh trong nhà dễ chăm sóc, phù hợp đặt trên bàn làm việc, kệ hoặc trong văn phòng. Cây chịu được ánh sáng yếu nhưng phát triển tốt hơn ở nơi có ánh sáng gián tiếp. Chỉ tưới khi đất đã khô, thông thường khoảng 7–14 ngày tùy nhiệt độ và độ ẩm. Cây chịu hạn tốt, không thích đất bị úng và phù hợp với người mới trồng cây.",
      price: "180000",
      stock: 25,
      taxRate: "8.00",
    },
    {
      categorySlug: "cay-canh",
      name: "Cây Monstera",
      slug: "cay-monstera",
      sku: "PLANT-MONSTERA-001",
      description:
        "Cây Monstera có lá lớn tạo điểm nhấn, phù hợp trang trí phòng khách hoặc văn phòng có không gian rộng. Cây phát triển tốt ở nơi có ánh sáng sáng nhưng gián tiếp; nắng gắt có thể làm cháy lá. Tưới khi lớp đất mặt đã khô và bảo đảm chậu thoát nước để tránh úng rễ. Có thể lau lá định kỳ và đặt cây ở nơi có độ ẩm vừa phải.",
      price: "450000",
      stock: 15,
      taxRate: "8.00",
    },
    {
      categorySlug: "phu-kien",
      name: "Chậu gốm tối giản",
      slug: "chau-gom-toi-gian",
      sku: "ACC-POT-001",
      description:
        "Chậu gốm có màu trung tính và phong cách tối giản, phù hợp phối cùng cây để bàn trong nhà, văn phòng hoặc góc làm việc. Sản phẩm dùng để trang trí và giữ bầu cây. Trước khi chọn, nên đối chiếu kích thước bầu cây và kiểm tra nhu cầu thoát nước của loại cây đang trồng.",
      price: "120000",
      stock: 60,
      taxRate: "8.00",
    },
    {
      categorySlug: "phu-kien",
      name: "Đất trồng hữu cơ 5 lít",
      slug: "dat-trong-huu-co-5-lit",
      sku: "ACC-SOIL-001",
      description:
        "Đất trồng hữu cơ đóng gói 5 lít dùng cho hoa và cây cảnh. Sản phẩm phù hợp để bổ sung hoặc thay đất cho chậu cây quy mô nhỏ. Khi sử dụng, cần chọn chậu có khả năng thoát nước và điều chỉnh lượng tưới theo nhu cầu của từng loại cây; không nên để hỗn hợp đất ngập nước kéo dài.",
      price: "90000",
      stock: 80,
      taxRate: "5.00",
    },
  ];

  for (const product of products) {
    const categoryId = categoryBySlug.get(product.categorySlug);

    if (!categoryId) {
      throw new Error(`Missing seed category: ${product.categorySlug}`);
    }

    const data = {
      categoryId,
      name: product.name,
      slug: product.slug,
      sku: product.sku,
      description: product.description,
      price: new Prisma.Decimal(product.price),
      stock: product.stock,
      taxRate: new Prisma.Decimal(product.taxRate),
      imageUrl: null,
      images: [],
      isActive: true,
    };

    await prisma.product.upsert({
      where: { sku: product.sku },
      update: data,
      create: data,
    });
  }

  const stores = [
    {
      id: "10000000-0000-4000-8000-000000000001",
      name: "Plant & Flower Shop - Quận 1",
      address: "Quận 1, Thành phố Hồ Chí Minh",
      latitude: 10.7756,
      longitude: 106.7004,
      phone: "02800000001",
      openingHours: "08:00-21:00",
    },
    {
      id: "10000000-0000-4000-8000-000000000002",
      name: "Plant & Flower Shop - Thủ Đức",
      address: "Thành phố Thủ Đức, Thành phố Hồ Chí Minh",
      latitude: 10.8494,
      longitude: 106.7537,
      phone: "02800000002",
      openingHours: "08:00-21:00",
    },
  ];

  for (const store of stores) {
    await prisma.store.upsert({
      where: { id: store.id },
      update: { ...store, isActive: true },
      create: { ...store, isActive: true },
    });
  }

  console.info(
    `Seed completed: ${categories.length} categories, ${products.length} products, ${stores.length} stores.`
  );
}

main()
  .catch((error: unknown) => {
    console.error("Seed failed", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
