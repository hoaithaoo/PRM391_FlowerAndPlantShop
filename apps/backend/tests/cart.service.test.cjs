const assert = require("node:assert/strict");
const { test } = require("node:test");
const { Prisma } = require("@prisma/client");
const { CartService } = require("../dist/modules/carts/cart.service");

const product = {
  id: "product-a",
  name: "Hoa sen",
  price: new Prisma.Decimal("125000"),
  stock: 10,
  isActive: true,
};

function fixture(t) {
  const tx = {
    product: { findFirst: t.mock.fn(async () => product) },
    cart: { upsert: t.mock.fn(async () => ({ id: "cart-a", items: [] })) },
    cartItem: {
      findUnique: t.mock.fn(async () => null),
      findFirst: t.mock.fn(async () => ({ id: "item-a", product })),
      create: t.mock.fn(async ({ data }) => ({
        id: "item-a", productId: data.productId, quantity: data.quantity,
      })),
      update: t.mock.fn(async ({ data, select }) => ({
        id: "item-a",
        ...(select.productId && { productId: product.id }),
        quantity: data.quantity,
      })),
      deleteMany: t.mock.fn(async () => ({ count: 1 })),
    },
  };
  const db = {
    $transaction: t.mock.fn(async (operation) => operation(tx)),
    cartItem: tx.cartItem,
  };
  return { tx, db, service: new CartService(db) };
}

const hasError = (statusCode, code) => (error) => {
  assert.equal(error.statusCode, statusCode);
  assert.equal(error.code, code);
  return true;
};

const prismaError = (code) => new Prisma.PrismaClientKnownRequestError(
  "Simulated transaction conflict", { code, clientVersion: "6.19.3" }
);

test("getCart initializes an empty cart for the authenticated user", async (t) => {
  const { service, tx } = fixture(t);
  assert.deepEqual(await service.getCart("user-a"), {
    id: "cart-a", items: [], totalQuantity: 0, subtotal: 0,
  });
  assert.deepEqual(tx.cart.upsert.mock.calls[0].arguments[0].where, { userId: "user-a" });
  assert.deepEqual(tx.cart.upsert.mock.calls[0].arguments[0].create, { userId: "user-a" });
});

test("getCart maps current product data and totals all quantities", async (t) => {
  const { service, tx } = fixture(t);
  tx.cart.upsert.mock.mockImplementation(async () => ({
    id: "cart-a",
    items: [
      { id: "item-a", productId: product.id, quantity: 2, product },
      { id: "item-b", productId: "product-b", quantity: 3,
        product: { ...product, id: "product-b", price: new Prisma.Decimal("70000") } },
    ],
  }));
  const cart = await service.getCart("user-a");
  assert.equal(cart.totalQuantity, 5);
  assert.equal(cart.subtotal, 460000);
  assert.deepEqual(cart.items[0], {
    id: "item-a", productId: product.id, name: product.name,
    price: 125000, quantity: 2, subtotal: 250000,
  });
});

test("addItemToCart creates an item without decrementing product stock", async (t) => {
  const { service, tx } = fixture(t);
  assert.deepEqual(await service.addItemToCart("user-a", { productId: product.id, quantity: 2 }), {
    id: "item-a", productId: product.id, quantity: 2, subtotal: 250000,
  });
  assert.equal(tx.cartItem.create.mock.callCount(), 1);
  assert.equal(product.stock, 10);
});

test("adding the same product increments the existing item", async (t) => {
  const { service, tx } = fixture(t);
  tx.cartItem.findUnique.mock.mockImplementation(async () => ({ id: "item-a", quantity: 3 }));
  const item = await service.addItemToCart("user-a", { productId: product.id, quantity: 2 });
  assert.equal(item.quantity, 5);
  assert.equal(item.subtotal, 625000);
  assert.equal(tx.cartItem.create.mock.callCount(), 0);
});

test("stock validation uses the combined quantity, including the current cart", async (t) => {
  const { service, tx } = fixture(t);
  tx.cartItem.findUnique.mock.mockImplementation(async () => ({ id: "item-a", quantity: 9 }));
  await assert.rejects(
    service.addItemToCart("user-a", { productId: product.id, quantity: 2 }),
    hasError(409, "PRODUCT_OUT_OF_STOCK")
  );
  assert.equal(tx.cartItem.update.mock.callCount(), 0);
  assert.equal(tx.cartItem.create.mock.callCount(), 0);
});

test("adding an unavailable product returns 404", async (t) => {
  const { service, tx } = fixture(t);
  tx.product.findFirst.mock.mockImplementation(async () => null);
  await assert.rejects(
    service.addItemToCart("user-a", { productId: product.id, quantity: 1 }),
    hasError(404, "PRODUCT_NOT_FOUND")
  );
  assert.deepEqual(tx.product.findFirst.mock.calls[0].arguments[0].where, {
    id: product.id, isActive: true,
  });
  assert.equal(tx.cart.upsert.mock.callCount(), 0);
});

test("update replaces the quantity rather than incrementing it", async (t) => {
  const { service } = fixture(t);
  assert.deepEqual(await service.updateCartItem("user-a", "item-a", { quantity: 4 }), {
    id: "item-a", quantity: 4, subtotal: 500000,
  });
});

test("update cannot access another user's item", async (t) => {
  const { service, tx } = fixture(t);
  tx.cartItem.findFirst.mock.mockImplementation(async () => null);
  await assert.rejects(
    service.updateCartItem("user-b", "item-a", { quantity: 1 }),
    hasError(404, "CART_ITEM_NOT_FOUND")
  );
  assert.deepEqual(tx.cartItem.findFirst.mock.calls[0].arguments[0].where, {
    id: "item-a", cart: { userId: "user-b" },
  });
  assert.equal(tx.cartItem.update.mock.callCount(), 0);
});

test("update rejects inactive products and quantities exceeding stock", async (t) => {
  const { service, tx } = fixture(t);
  await assert.rejects(
    service.updateCartItem("user-a", "item-a", { quantity: 11 }),
    hasError(409, "PRODUCT_OUT_OF_STOCK")
  );
  tx.cartItem.findFirst.mock.mockImplementation(async () => ({
    id: "item-a", product: { ...product, isActive: false },
  }));
  await assert.rejects(
    service.updateCartItem("user-a", "item-a", { quantity: 1 }),
    hasError(404, "PRODUCT_NOT_FOUND")
  );
  assert.equal(tx.cartItem.update.mock.callCount(), 0);
});

test("delete checks ownership in the mutation itself and permits inactive items", async (t) => {
  const { service, tx } = fixture(t);
  assert.equal(await service.removeCartItem("user-a", "item-a"), undefined);
  assert.deepEqual(tx.cartItem.deleteMany.mock.calls[0].arguments[0], {
    where: { id: "item-a", cart: { userId: "user-a" } },
  });
  tx.cartItem.deleteMany.mock.mockImplementation(async () => ({ count: 0 }));
  await assert.rejects(service.removeCartItem("user-b", "item-a"), hasError(404, "CART_ITEM_NOT_FOUND"));
});

test("serialization conflicts retry with fresh item quantity and recheck stock", async (t) => {
  const { service, db, tx } = fixture(t);
  tx.cartItem.findUnique.mock.mockImplementation(async () => ({ id: "item-a", quantity: 8 }));
  let attempts = 0;
  db.$transaction.mock.mockImplementation(async (operation, options) => {
    assert.equal(options.isolationLevel, "Serializable");
    attempts += 1;
    if (attempts === 1) {
      await operation(tx);
      tx.cartItem.findUnique.mock.mockImplementation(async () => ({ id: "item-a", quantity: 10 }));
      throw prismaError("P2034");
    }
    return operation(tx);
  });
  await assert.rejects(
    service.addItemToCart("user-a", { productId: product.id, quantity: 2 }),
    hasError(409, "PRODUCT_OUT_OF_STOCK")
  );
  assert.equal(attempts, 2);
});

test("concurrent first-cart uniqueness conflicts are retried", async (t) => {
  const { service, db, tx } = fixture(t);
  let attempts = 0;
  db.$transaction.mock.mockImplementation(async (operation) => {
    if (++attempts === 1) throw prismaError("P2002");
    return operation(tx);
  });
  assert.equal((await service.getCart("user-a")).id, "cart-a");
  assert.equal(attempts, 2);
});

test("persistent transaction conflicts become a bounded 409 response", async (t) => {
  const { service, db } = fixture(t);
  db.$transaction.mock.mockImplementation(async () => { throw prismaError("P2034"); });
  await assert.rejects(service.getCart("user-a"), hasError(409, "TRANSACTION_CONFLICT"));
  assert.equal(db.$transaction.mock.callCount(), 3);
});

test("unexpected database failures propagate without retrying", async (t) => {
  const { service, db } = fixture(t);
  const failure = new Error("Database unavailable");
  db.$transaction.mock.mockImplementation(async () => { throw failure; });
  await assert.rejects(service.getCart("user-a"), (error) => error === failure);
  assert.equal(db.$transaction.mock.callCount(), 1);
});
