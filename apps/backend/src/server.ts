import { createApp } from "./app";
import { env } from "./config/env";
import { logger } from "./lib/logger";
import { prisma } from "./lib/prisma";
import { expireOverduePayments } from "./modules/payments/payment-expiry.service";

const PAYMENT_EXPIRY_INTERVAL_MS = 60_000;

const app = createApp();

const server = app.listen(env.PORT, () => {
  logger.info(`🚀 Plant & Flower Backend server is running`, {
    port: env.PORT,
    environment: env.NODE_ENV,
    url: `http://localhost:${env.PORT}`,
  });
});

const paymentExpiryTimer = setInterval(() => {
  expireOverduePayments().catch((error) => {
    logger.error("Payment expiry sweep failed", { error });
  });
}, PAYMENT_EXPIRY_INTERVAL_MS);
paymentExpiryTimer.unref();

// Graceful shutdown handling
const gracefulShutdown = async (signal: string) => {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  clearInterval(paymentExpiryTimer);
  server.close(async () => {
    logger.info("HTTP server closed.");
    try {
      await prisma.$disconnect();
      logger.info("Database connection closed.");
      process.exit(0);
    } catch (err) {
      logger.error("Error during database disconnect", { error: err });
      process.exit(1);
    }
  });

  // Force shutdown after 10 seconds
  setTimeout(() => {
    logger.error("Forcefully shutting down due to timeout.");
    process.exit(1);
  }, 10000);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
