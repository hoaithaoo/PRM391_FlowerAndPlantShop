import assert from "node:assert/strict";
import { describe, test } from "node:test";

import {
  parseProductSearchFilters,
  stripProductSearchFilters,
} from "./product-search-query";

describe("parseProductSearchFilters", () => {
  test("extracts a Vietnamese maximum price using k shorthand", () => {
    assert.deepEqual(parseProductSearchFilters("Tìm cây để bàn dưới 300k"), {
      maxPrice: 300_000,
    });
  });

  test("extracts a Vietnamese price range with grouped digits", () => {
    assert.deepEqual(parseProductSearchFilters("Cây từ 200.000 đến 500.000 đồng"), {
      minPrice: 200_000,
      maxPrice: 500_000,
    });
  });

  test("extracts English upper and Vietnamese lower price bounds", () => {
    assert.deepEqual(parseProductSearchFilters("desk plant under 300000 vnd"), {
      maxPrice: 300_000,
    });
    assert.deepEqual(parseProductSearchFilters("cây trên 1 triệu"), {
      minPrice: 1_000_000,
    });
  });

  test("returns no hard filters when the query has no explicit price constraint", () => {
    assert.deepEqual(parseProductSearchFilters("Cây nào chịu được ánh sáng yếu?"), {});
  });
});

describe("stripProductSearchFilters", () => {
  test("removes Vietnamese price constraints without removing product meaning", () => {
    assert.equal(
      stripProductSearchFilters("Tìm cây lưỡi hổ dưới 300k"),
      "Tìm cây lưỡi hổ"
    );
    assert.equal(
      stripProductSearchFilters("Cây để bàn từ 200.000 đến 500.000 đồng"),
      "Cây để bàn"
    );
  });

  test("removes English price constraints and keeps an unfiltered query unchanged", () => {
    assert.equal(stripProductSearchFilters("desk plant under 300000 vnd"), "desk plant");
    assert.equal(
      stripProductSearchFilters("Cây nào chịu được ánh sáng yếu?"),
      "Cây nào chịu được ánh sáng yếu?"
    );
  });
});
