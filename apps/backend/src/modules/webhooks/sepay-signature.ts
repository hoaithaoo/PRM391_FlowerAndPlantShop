import { createHmac, timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { env } from "../../config/env";
import { logger } from "../../lib/logger";

type Clock = () => number;

const SIGNATURE_PREFIX = "sha256=";
const MAX_TIMESTAMP_DRIFT_SECONDS = 300;

export class SepaySignatureVerifier {
  constructor(
    private readonly secret: string | undefined,
    private readonly now: Clock = () => Date.now()
  ) {}

  verify(
    rawBody: Buffer,
    signature: string | undefined,
    timestampHeader: string | undefined
  ): void {
    if (!this.secret) {
      throw new AppError(
        503,
        ErrorCodes.SERVICE_UNAVAILABLE,
        "Webhook SePay chưa được cấu hình."
      );
    }

    if (!signature || !timestampHeader) {
      this.invalidSignature("MISSING_HEADERS", {
        hasSignature: Boolean(signature),
        hasTimestamp: Boolean(timestampHeader),
      });
    }
    if (
      !/^sha256=[a-f0-9]{64}$/i.test(signature) ||
      !/^\d+$/.test(timestampHeader)
    ) {
      this.invalidSignature("MALFORMED_HEADERS", {
        signatureLength: signature.length,
        signatureHasPrefix: signature.startsWith(SIGNATURE_PREFIX),
        timestampIsDigits: /^\d+$/.test(timestampHeader),
      });
    }

    const timestamp = Number(timestampHeader);
    const nowSeconds = Math.floor(this.now() / 1000);
    if (
      !Number.isSafeInteger(timestamp) ||
      Math.abs(nowSeconds - timestamp) > MAX_TIMESTAMP_DRIFT_SECONDS
    ) {
      this.invalidSignature("TIMESTAMP_OUT_OF_RANGE", {
        driftSeconds: nowSeconds - timestamp,
      });
    }

    const hmac = createHmac("sha256", this.secret);
    hmac.update(`${timestampHeader}.`, "utf8");
    hmac.update(rawBody);
    const expected = `${SIGNATURE_PREFIX}${hmac.digest("hex")}`;
    const expectedBuffer = Buffer.from(expected, "utf8");
    const providedBuffer = Buffer.from(signature, "utf8");

    if (
      expectedBuffer.length !== providedBuffer.length ||
      !timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
      // Không log secret hay chữ ký; chỉ log thông tin giúp phân biệt nguyên nhân
      // (sai secret, secret có khoảng trắng/ngoặc kép, body rỗng do sai content type).
      this.invalidSignature("SIGNATURE_MISMATCH", {
        bodyBytes: rawBody.length,
        secretLength: this.secret.length,
        secretHasOuterWhitespaceOrQuotes: /^[\s"']|[\s"']$/.test(this.secret),
      });
    }
  }

  /**
   * Chế độ "API Key" của SePay: header `Authorization: Apikey <key>`.
   * Dùng chung SEPAY_WEBHOOK_SECRET với chế độ HMAC-SHA256.
   */
  verifyApiKey(authorization: string): void {
    if (!this.secret) {
      throw new AppError(
        503,
        ErrorCodes.SERVICE_UNAVAILABLE,
        "Webhook SePay chưa được cấu hình."
      );
    }

    const match = /^apikey\s+(.+)$/i.exec(authorization.trim());
    if (!match) {
      this.invalidSignature("UNSUPPORTED_AUTHORIZATION", {
        scheme: authorization.trim().split(/\s+/)[0] ?? null,
      });
    }

    const expectedBuffer = Buffer.from(this.secret, "utf8");
    const providedBuffer = Buffer.from(match[1].trim(), "utf8");
    if (
      expectedBuffer.length !== providedBuffer.length ||
      !timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
      this.invalidSignature("API_KEY_MISMATCH", {
        providedLength: providedBuffer.length,
        secretLength: expectedBuffer.length,
        secretHasOuterWhitespaceOrQuotes: /^[\s"']|[\s"']$/.test(this.secret),
      });
    }
  }

  private invalidSignature(
    reason: string,
    details: Record<string, unknown> = {}
  ): never {
    logger.warn("SePay webhook signature rejected", { reason, ...details });
    throw new AppError(
      401,
      ErrorCodes.SEPAY_SIGNATURE_INVALID,
      "Chữ ký webhook SePay không hợp lệ hoặc đã hết hạn."
    );
  }
}

export const sepaySignatureVerifier = new SepaySignatureVerifier(
  env.SEPAY_WEBHOOK_SECRET
);

export const rejectCompressedSepayWebhook = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  const contentEncoding = req.get("Content-Encoding")?.trim().toLowerCase();
  if (contentEncoding && contentEncoding !== "identity") {
    next(
      new AppError(
        400,
        ErrorCodes.BAD_REQUEST,
        "Webhook SePay không hỗ trợ body nén."
      )
    );
    return;
  }
  next();
};

export const verifySepaySignature = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  try {
    const signature = req.get("X-SePay-Signature");
    const authorization = req.get("Authorization");
    // Ưu tiên HMAC-SHA256 khi SePay có ký; nếu webhook cấu hình kiểu API Key
    // thì SePay chỉ gửi header Authorization.
    if (!signature && authorization) {
      sepaySignatureVerifier.verifyApiKey(authorization);
    } else {
      sepaySignatureVerifier.verify(
        // rawBody chỉ có khi body là JSON; SePay phải gửi Content-Type application/json.
        req.rawBody ?? Buffer.alloc(0),
        signature,
        req.get("X-SePay-Timestamp")
      );
    }
    next();
  } catch (error) {
    if (error instanceof AppError && error.statusCode === 401) {
      logger.warn("SePay webhook request info", {
        contentType: req.get("Content-Type") ?? null,
        hasRawBody: Boolean(req.rawBody),
        hasAuthorizationHeader: Boolean(req.get("Authorization")),
      });
    }
    next(error);
  }
};
