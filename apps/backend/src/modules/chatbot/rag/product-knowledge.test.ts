import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { buildContextualChunk, chunkProductDescription } from "./product-knowledge";

describe("chunkProductDescription", () => {
  test("does not create knowledge for an empty description", () => {
    assert.deepEqual(chunkProductDescription("  \n\t  "), []);
  });

  test("keeps a short description in one normalized context-preserving chunk", () => {
    const description = "  Cây phù hợp trong nhà.   \n\n  Chỉ tưới khi đất khô.  ";

    assert.deepEqual(chunkProductDescription(description), [
      "Cây phù hợp trong nhà.\n\nChỉ tưới khi đất khô.",
    ]);
  });

  test("splits long content at complete sentence boundaries with sentence overlap", () => {
    const description = [
      "Cây phù hợp với ánh sáng gián tiếp.",
      "Lá cần được giữ sạch.",
      "Chỉ tưới khi mặt đất khô.",
      "Không để chậu bị ngập nước.",
    ].join(" ");

    assert.deepEqual(
      chunkProductDescription(description, { maxWords: 14, overlapWords: 5 }),
      [
        "Cây phù hợp với ánh sáng gián tiếp. Lá cần được giữ sạch.",
        "Lá cần được giữ sạch. Chỉ tưới khi mặt đất khô.",
        "Không để chậu bị ngập nước.",
      ]
    );
  });

  test("keeps an unusually long single sentence whole instead of cutting by characters", () => {
    const sentence = "Một câu rất dài nhưng vẫn phải được giữ nguyên vì điểm kết thúc câu mang theo ngữ cảnh hoàn chỉnh.";

    assert.deepEqual(chunkProductDescription(sentence, { maxWords: 5, overlapWords: 2 }), [sentence]);
  });

  test("keeps complete overlap even when it makes the next chunk exceed the soft limit", () => {
    const description = [
      "Một hai ba bốn.",
      "Năm sáu bảy tám.",
      "Chín mười mười một mười hai mười ba.",
    ].join(" ");

    assert.deepEqual(chunkProductDescription(description, { maxWords: 8, overlapWords: 4 }), [
      "Một hai ba bốn. Năm sáu bảy tám.",
      "Năm sáu bảy tám. Chín mười mười một mười hai mười ba.",
    ]);
  });

  test("returns deterministic chunks for the same input", () => {
    const description = "Đoạn thứ nhất có đủ thông tin. Đoạn thứ hai bổ sung cách chăm sóc.";

    assert.deepEqual(
      chunkProductDescription(description, { maxWords: 6, overlapWords: 3 }),
      chunkProductDescription(description, { maxWords: 6, overlapWords: 3 })
    );
  });
});

test("buildContextualChunk prefixes every chunk with product identity", () => {
  assert.equal(
    buildContextualChunk(
      {
        productId: "11111111-1111-4111-8111-111111111111",
        productName: "Cây Lưỡi Hổ",
        categoryName: "Cây cảnh",
      },
      "Cây chịu được ánh sáng yếu."
    ),
    [
      "Mã sản phẩm: 11111111-1111-4111-8111-111111111111",
      "Tên sản phẩm: Cây Lưỡi Hổ",
      "Danh mục: Cây cảnh",
      "",
      "Cây chịu được ánh sáng yếu.",
    ].join("\n")
  );
});
