export interface DisplayGuide {
  placement: string; // Vị trí & hướng đặt
  vessel: string; // Bình / vật chứa
  arrangement: string; // Cách cắm
  care: string[]; // Giữ hoa lâu
}

export interface CollectionFlower {
  slug: string;
  name: string;
  origin: string;
  imageUrl: string;
  quote: string;
  story: string; // Câu chuyện loài hoa
  whyChosen: string; // Vì sao chọn cho bộ sưu tập
  meaning: string; // Hoa mang thông điệp gì khi chưng
  display: DisplayGuide;
  occasions: string[];
}

export interface ConceptArt {
  theme: string;
  subtitle: string;
  storyImageUrl?: string;
  harvestImageUrl?: string;
  storyExcerpt?: {
    title: string;
    quote: string;
    content: string[];
    artworksFeatured: { name: string; meaning: string }[];
  };
  photoDetails: {
    lighting: string;
    space: string;
    materials: string;
  };
  regionNature: {
    title: string;
    description: string;
    points: { title: string; desc: string }[];
  };
  whyThisConcept: {
    title: string;
    description: string;
    points: { title: string; desc: string }[];
  };
  flowerMeaning: {
    title: string;
    description: string;
    points: { title: string; desc: string }[];
  };
  artworks: {
    id: string;
    name: string;
    vessel: string;
    desc: string;
  }[];
}

export interface FlowerCollection {
  slug: string;
  index: string;
  region: string;
  title: string;
  tagline: string;
  coverUrl: string;
  tint: string; // màu nền nhạt riêng của vùng
  intro: string;
  whyThisCollection: string;
  concept?: ConceptArt;
  flowers: CollectionFlower[];
}

export const COLLECTIONS: FlowerCollection[] = [
  {
    slug: "dong-thap",
    index: "01",
    region: "Đồng Tháp",
    title: "Ký Ức Sen Hồng Tháp Mười",
    tagline: "Bộ Sưu Tập: Vẻ Đẹp Hoa Sen • Góc Nhìn Nghệ Thuật Đương Đại",
    coverUrl: "/images/sen-dong-thap.png",
    tint: "#F8F6F4",
    intro:
      "Đồng Tháp Mười được bồi đắp bởi dòng phù sa sông Tiền cổ kính. Nơi đây, những đầm sen bạt ngàn nuôi dưỡng đóa sen hồng bách diệp thanh khiết, ngát hương giữa mênh mang sông nước phương Nam.",
    whyThisCollection:
      "Chúng tôi mở đầu bằng Đồng Tháp và dành trọn bộ sưu tập này cho Hoa Sen — loài hoa đại diện cho tinh thần của Nhà Có Hoa: mộc mạc, vươn lên từ bùn lầy châu thổ nhưng giữ trọn sự thanh cao, thuần khiết và an nhiên.",
    concept: {
      theme: "Bộ Sưu Tập: Vẻ Đẹp Hoa Sen • Góc Nhìn Nghệ Thuật",
      subtitle:
        "Buổi chụp concept độc bản đưa hoa sen Tháp Mười vào không gian sắp đặt mỹ thuật tối giản, đối thoại giữa nét mộc mạc châu thổ và triết lý Ikebana hiện đại.",
      storyImageUrl: "/images/sen-dong-thap-story.png",
      harvestImageUrl: "/images/sen-dong-thap-harvest.png",
      storyExcerpt: {
        title: "CÂU CHUYỆN: VẺ ĐẸP HOA SEN",
        quote: "Lấy cảm hứng từ sự thanh khiết giữa bùn lầy, bộ sưu tập tôn vinh vẻ đẹp của từng giai đoạn hoa sen, từ nụ đến khi tàn.",
        content: [
          "‘Chậu Vân Sen Đăng Đối’ đại diện cho sự viên mãn và ‘Vũ Khúc Hương Đêm’ là khoảnh khắc thầm lặng tỏa hương.",
          "Những thiết kế gốm thủ công độc bản được chế tác tỉ mỉ, gìn giữ tinh thần truyền thống và khơi gợi cảm xúc đương đại về quốc hoa Việt Nam.",
        ],
        artworksFeatured: [
          {
            name: "Chậu Vân Sen Đăng Đối",
            meaning: "Đại diện cho sự viên mãn, đủ đầy và sinh sôi bất tận trong âu gốm vân sọc trắng tinh khôi.",
          },
          {
            name: "Vũ Khúc Hương Đêm",
            meaning: "Khoảnh khắc thầm lặng tỏa ngát hương sương đêm, độc bản trong bình gốm mộc họa sen thủy mặc.",
          },
        ],
      },
      photoDetails: {
        lighting:
          "Ánh sáng studio tự nhiên khuếch tán mềm mại, điểm xuyết hiệu ứng bokeh mờ ảo của cánh hoa sen hồng ở tiền cảnh tạo chiều sâu điện ảnh.",
        space:
          "Bục thạch cao trắng đa tầng tối giản (Gallery Podium) kết hợp tường xi măng thô mộc và bức họa thủy mặc hoa sen truyền thống trên nền tường.",
        materials:
          "Âu gốm sọc gân thủ công, bình gốm trắng cổ cao, đĩa gốm phấn hồng pastel, phối hợp cùng nan tre uốn vòm và quạt giấy xếp nếp Ikebana đương đại.",
      },
      regionNature: {
        title: "Hoa sen ở Đồng Tháp như thế nào?",
        description:
          "Không giống như sen trồng ở các vùng đầm cạn hay hồ nhân tạo, sen Đồng Tháp sinh trưởng giữa vùng lõi đầm lầy Tháp Mười với lớp phù sa sông Tiền lắng đọng hàng trăm năm. Thổ nhưỡng đặc thù này tạo nên những phẩm chất độc nhất vô nhị:",
        points: [
          {
            title: "Dáng hoa bách diệp đẫy đà, dày cánh",
            desc: "Sen Tháp Mười có form hoa to tròn, cánh hoa xếp lớp kép (bách diệp) dày dặn, chóp cánh ửng hồng phấn thắm đượm và chuyển dần sang sắc trắng ngọc tinh khôi ở cuống hoa.",
          },
          {
            title: "Hương thơm đậm vị phù sa sông nước",
            desc: "Nhờ hấp thụ khoáng chất từ bùn ngọt châu thổ, hương sen Đồng Tháp có vị ngọt thanh, ngát hương nhưng đọng lại rất sâu và bền trong không gian, mang lại cảm giác thư thái lạ kỳ.",
          },
          {
            title: "Thu hoạch sớm lúc 04:30 sáng ngậm sương mai",
            desc: "Nghệ nhân chèo xuồng ra giữa đầm từ lúc 4 giờ sáng tinh mơ, cắt cuống khi búp hoa vừa hé đón những giọt sương đêm đầu tiên để giữ trọn vẹn sức sống và tinh dầu thơm quý giá.",
          },
        ],
      },
      whyThisConcept: {
        title: "Vì sao Nhà Có Hoa mang hoa sen vào concept này?",
        description:
          "Thông thường, hoa sen hay bị đóng khung trong việc dâng cúng tâm linh hoặc cắm bình truyền thống. Nhà Có Hoa muốn phá vỡ định kiến đó bằng một concept mỹ thuật đương đại:",
        points: [
          {
            title: "Linh hồn cốt lõi của Nhà Có Hoa",
            desc: "Sen biểu trưng cho sự chân thật, không phô trương cầu kỳ. Đưa sen vào concept là lời khẳng định về giá trị cốt lõi: tìm về vẻ đẹp thuần khiết nhất của tự nhiên.",
          },
          {
            title: "Cuộc đối thoại giữa bùn lầy & mỹ thuật tối giản",
            desc: "Mang những đóa sen mộc mạc từ đầm lầy miền Tây đặt lên bục triển lãm gốm trắng tinh giản, phối hợp cùng nan tre uốn lượn và quạt giấy nếp — tạo nên một ngôn ngữ thị giác sang trọng mà gần gũi.",
          },
          {
            title: "Tôn vinh trọn vẹn vòng tuần hoàn sinh mệnh",
            desc: "Concept không chỉ trưng đóa hoa nở rộ, mà nâng niu từ búp sen e ấp, đài sen đón nắng, phiến lá sen uốn lượn cho đến cánh hoa rơi rụng, phản chiếu vẻ đẹp trọn vẹn của vạn vật.",
          },
        ],
      },
      flowerMeaning: {
        title: "Ý nghĩa sâu sắc của Hoa Sen",
        description:
          "Trong tâm thức người Việt và triết lý Á Đông, hoa sen là biểu tượng thiêng liêng gói trọn ba tầng ý nghĩa nhân sinh:",
        points: [
          {
            title: "Thanh khiết & Khí phách kiên cường",
            desc: "“Gần bùn mà chẳng hôi tanh mùi bùn” — Đóa sen nhắc nhở con người về bản lĩnh giữ gìn tâm hồn trong sạch, kiên cường vượt qua nghịch cảnh để nở hoa rạng rỡ giữa đời.",
          },
          {
            title: "Minh triết & Tỉnh thức trong tâm hồn",
            desc: "Hình ảnh đóa sen bung nở như sự khai mở của trí tuệ và sự bình an nội tại. Sen giúp xua tan những xáo trộn ồn ã, đưa tâm trí trở về trạng thái an nhiên, tĩnh lặng.",
          },
          {
            title: "Vượng khí an lành khi chưng trong nhà",
            desc: "Theo phong thủy và thẩm mỹ không gian sống, hoa sen tỏa ra từ trường êm dịu, giúp thanh lọc sinh khí, gắn kết yêu thương trong gia đình và mang lại sự hòa thuận, may mắn.",
          },
        ],
      },
      artworks: [
        {
          id: "01",
          name: "Hồn Sen Bộ Sưu Tập 01",
          vessel: "Đĩa gốm phấn hồng pastel",
          desc: "Đóa sen hồng hé nở kết hợp cùng đài sen tươi và lá quạt giấy xếp nếp, tạo nhịp điệu e ấp dịu dàng.",
        },
        {
          id: "02",
          name: "Nghệ Thuật Đơn Đóa Vươn Cao",
          vessel: "Bình gốm trắng cổ cao thanh thoát",
          desc: "Một đóa sen hồng duy nhất vươn thẳng kiêu hãnh đón ánh sáng, tôn vinh vẻ đẹp độc bản tĩnh lặng.",
        },
        {
          id: "03",
          name: "Tác Phẩm Trung Tâm: Phép Màu Sen",
          vessel: "Âu gốm sọc trắng nghệ thuật",
          desc: "Trọng tâm của triển lãm quy tụ đóa sen hé nở, búp sen vươn đón nắng mai, đài sen xanh ngọc và lá sen non châu thổ.",
        },
        {
          id: "04",
          name: "Sức Sống Vươn Lên",
          vessel: "Bệ gốm tròn kết hợp quạt giấy trắng",
          desc: "Đài sen vươn cao vượt bậc biểu trưng cho sự tiến bước, hòa quyện cùng cánh sen hồng rạng rỡ.",
        },
        {
          id: "05",
          name: "Sức Sống Miền Quê (Mềm Mại)",
          vessel: "Bình gốm đa giác hình học",
          desc: "Vòng nan tre uốn lượn ôm trọn đóa sen nở rộ, gợi nhắc về sự mềm mại của ngọn tre và con người phương Nam.",
        },
      ],
    },
    flowers: [
      {
        slug: "hoa-sen",
        name: "Hoa Sen Tháp Mười • Tuyển Tập Nghệ Thuật",
        origin: "Đầm sen Tháp Mười, Đồng Tháp",
        imageUrl: "/images/sen-dong-thap.png",
        quote: "Gần bùn mà chẳng hôi tanh mùi bùn.",
        story:
          "Sen mọc lên từ lớp bùn sâu lắng của đầm châu thổ, nhưng khi vươn lên đón nắng mai lại mang sắc hồng dịu ngọt và hương thơm thanh tịnh. Với người Việt, hoa sen là biểu tượng của sự kiên cường, thoát tục và an lạc. Tại Nhà Có Hoa, từng cành sen được hái sớm từ lúc 4:30 sáng khi búp hoa còn ngậm sương mai, sau đó được nghệ nhân tạo tác thành 5 thế cắm nghệ thuật độc bản.",
        whyChosen:
          "Bộ sưu tập Đồng Tháp được tinh giản tối đa để chỉ tôn vinh duy nhất Hoa Sen. Chúng tôi không phối thêm loài hoa nào khác nhằm hướng trọn vẹn sự chú ý của người thưởng ngoạn vào sự thanh khiết, trang nhã và chiều sâu thiền định của quốc hoa.",
        meaning:
          "Chưng hoa sen trong không gian sống mang thông điệp về sự thanh lọc tâm hồn, trí tuệ minh triết và bình an gia đạo. Năng lượng thuần khiết từ sen giúp không gian lắng đọng, giải tỏa căng thẳng và mang lại nguồn sinh khí thiện lành, tích cực.",
        display: {
          placement:
            "Thích hợp đặt tại bàn trà thiền định, phòng khách trang nhã, không gian thưởng thức nghệ thuật hoặc bàn thờ gia tiên. Đặt nơi đón ánh sáng tự nhiên dịu nhẹ buổi sáng, tránh gió điều hòa phả trực tiếp.",
          vessel:
            "Âu gốm sọc trắng, đĩa gốm men mờ hoặc bình gốm sứ mộc mạc kết hợp nan tre uốn lượn và quạt giấy nếp đương đại phong cách Ikebana.",
          arrangement:
            "Có thể chọn 1 trong 5 dáng cắm nghệ thuật: Dáng vươn cao đơn đóa thanh thoát, dáng âu thuyền đài sen sum vầy, hoặc phối kết búp sen và lá non theo cấu trúc đối xứng tự nhiên.",
          care: [
            "Cắt vát cuống sen ngập sâu trong nước mát để tránh bọt khí tràn vào mạch dẫn.",
            "Thay nước sạch mỗi ngày, có thể thêm vài viên đá lạnh giúp cuống hoa giòn và bền lâu.",
            "Phun sương mịn lên búp và cánh hoa vào mỗi sớm mai.",
            "Tránh đặt hoa gần nguồn nhiệt, quạt gió mạnh hoặc đĩa trái cây chín.",
          ],
        },
        occasions: [
          "Không gian thiền định, bàn trà và góc đọc sách tĩnh tâm",
          "Lễ Vu Lan báo hiếu, ngày rằm và đại lễ trang trọng",
          "Mừng thọ ông bà, cha mẹ",
          "Quà tặng tri ân đối tác trang trọng hoặc tân gia an lành",
        ],
      },
    ],
  },
  {
    slug: "da-lat",
    index: "02",
    region: "Đà Lạt",
    title: "Sương Sớm Cao Nguyên",
    tagline: "Dịu dàng như buổi sáng mờ sương trên đồi thông",
    coverUrl:
      "https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=2000&q=80",
    tint: "#FBF3F5",
    intro:
      "Khí hậu se lạnh quanh năm giúp hoa Đà Lạt có màu dịu và cánh mềm. Những vườn hoa trên triền dốc là nguồn cảm hứng cho sự nhẹ nhàng của bộ sưu tập này.",
    whyThisCollection:
      "Sau sự thanh tịnh của sen, Đà Lạt mang tới sự lãng mạn. Đây là bộ sưu tập dành cho những cảm xúc riêng tư: lời cảm ơn, lời yêu, một món quà vỗ về.",
    flowers: [
      {
        slug: "cam-tu-cau",
        name: "Cẩm Tú Cầu",
        origin: "Vườn hoa Trại Mát, Đà Lạt",
        imageUrl:
          "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1400&q=80",
        quote: "Một chùm hoa, trăm đóa nhỏ cùng nở.",
        story:
          "Cẩm tú cầu đổi màu theo độ chua của đất, từ xanh lam đến hồng tím. Ở Đà Lạt, hoa nở rộ thành từng đồi, trở thành biểu tượng của thành phố.",
        whyChosen:
          "Hàng trăm cánh hoa nhỏ hợp thành một chùm tròn, giống cách những điều nhỏ bé tạo nên một tình cảm trọn vẹn.",
        meaning: "Lời cảm ơn chân thành và sự gắn kết bền chặt.",
        display: {
          placement:
            "Bàn ăn, bàn làm việc hoặc đầu giường. Cần nơi mát, tránh nắng chiều.",
          vessel: "Bình thủy tinh trong hoặc bình gốm trắng miệng rộng.",
          arrangement: "Cắm 1–3 chùm, cắt ngắn để chùm hoa nằm sát miệng bình.",
          care: [
            "Nhúng cả chùm hoa vào nước mát 10 phút nếu hoa bị héo.",
            "Thay nước hằng ngày.",
          ],
        },
        occasions: ["Lời cảm ơn", "Kỷ niệm", "Sinh nhật bạn thân"],
      },
      {
        slug: "mimosa",
        name: "Mimosa",
        origin: "Đèo Mimosa, Đà Lạt",
        imageUrl:
          "https://images.unsplash.com/photo-1582794543139-8ac9cb0f7b11?auto=format&fit=crop&w=1400&q=80",
        quote: "Vàng bồng bềnh như mây đậu bên sườn đồi.",
        story:
          "Mimosa nở vào cuối đông, đầu xuân. Những bông tròn nhỏ như bông gòn phủ vàng con đèo mang tên loài hoa.",
        whyChosen: "Mimosa báo hiệu mùa xuân, khép lại bộ sưu tập Đà Lạt bằng sự ấm áp.",
        meaning: "Sự chung thủy âm thầm và niềm vui khởi đầu.",
        display: {
          placement: "Phòng khách, kệ sách, nơi thoáng khí.",
          vessel: "Bình gốm men rạn hoặc lọ thủy tinh màu hổ phách.",
          arrangement: "Cắm cành dài, để tán hoa tự nhiên xòe ra.",
          care: ["Mimosa có thể để khô tự nhiên, giữ màu nhiều tuần."],
        },
        occasions: ["Kỷ niệm ngày cưới", "Tân gia", "Đầu xuân"],
      },
    ],
  },
  {
    slug: "tay-bac",
    index: "03",
    region: "Tây Bắc",
    title: "Ngàn Mây Mộc Châu",
    tagline: "Hoang sơ và kiên cường giữa núi rừng",
    coverUrl:
      "https://images.unsplash.com/photo-1522383225653-ed111181a951?auto=format&fit=crop&w=2000&q=80",
    tint: "#F2F3F1",
    intro:
      "Mùa xuân Tây Bắc, hoa mận và hoa ban phủ trắng các thung lũng. Những cành hoa mọc trên nền đá và gió lạnh mang vẻ đẹp phóng khoáng hiếm có.",
    whyThisCollection:
      "Bộ sưu tập khép lại hành trình bằng sự phóng khoáng của núi rừng. Chúng tôi giữ nguyên dáng cành tự nhiên, nên mỗi tác phẩm là độc nhất.",
    flowers: [
      {
        slug: "hoa-ban",
        name: "Hoa Ban",
        origin: "Điện Biên & Sơn La",
        imageUrl:
          "https://images.unsplash.com/photo-1522383225653-ed111181a951?auto=format&fit=crop&w=1400&q=80",
        quote: "Trắng phớt tím, son sắt như tình yêu miền sơn cước.",
        story:
          "Theo truyền thuyết người Thái, hoa ban là hóa thân của nàng Ban thủy chung. Hoa nở vào tháng Ba, nhuộm trắng núi rừng Tây Bắc.",
        whyChosen: "Hoa ban mang câu chuyện về lòng thủy chung, rất gần với những món quà gắn kết.",
        meaning: "Sự thủy chung và tình cảm bền lâu.",
        display: {
          placement: "Sảnh nhà, phòng khách rộng, góc nhiều khoảng trống.",
          vessel: "Chum gốm thô, bình đất nung cao.",
          arrangement: "1–2 cành dài, để khoảng trống quanh cành theo tinh thần tối giản.",
          care: ["Đập dập nhẹ gốc cành để hút nước tốt hơn.", "Thay nước 2 ngày một lần."],
        },
        occasions: ["Kỷ niệm", "Tân gia phong cách mộc", "Không gian trưng bày"],
      },
      {
        slug: "hoa-man",
        name: "Hoa Mận",
        origin: "Cao nguyên Mộc Châu",
        imageUrl:
          "https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=1400&q=80",
        quote: "Cành rêu phong, hoa trắng tinh khôi.",
        story: "Hoa mận nở trắng thung lũng Mộc Châu mỗi độ xuân về, báo hiệu một năm mới đủ đầy.",
        whyChosen: "Sự đối lập giữa thân cành gân guốc và cánh hoa mỏng manh là điều chúng tôi muốn giữ lại.",
        meaning: "Khởi đầu thanh khiết, may mắn đầu năm.",
        display: {
          placement: "Phòng khách, bàn trà, hướng Đông đón nắng sớm.",
          vessel: "Bình gốm men tro hoặc bình sứ trắng.",
          arrangement: "Cắm cành nghiêng, tạo dáng như cành mọc vươn ra.",
          care: ["Cắt xiên gốc, ngâm nước ấm trước khi cắm."],
        },
        occasions: ["Tết", "Khai xuân", "Phòng trà"],
      },
    ],
  },
];

export const getCollection = (slug: string) => COLLECTIONS.find((c) => c.slug === slug);
