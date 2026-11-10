import { createHmac, timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { env } from "../../config/env";
import { logger } from "../../lib/logger";

type Clock = () => number;

const SIGNATURE_PREFIX = "sha256=";
const APIKEY_PREFIX = "apikey ";
const MAX_TIMESTAMP_DRIFT_SECONDS = 300;

/** Lý do từ chối, chỉ để ghi log chẩn đoán (không chứa secret). */
export type SepayRejectReason =
  | "missing_signature_headers"
  | "malformed_signature_headers"
  | "stale_timestamp"
  | "hmac_mismatch"
  | "apikey_mismatch"
  | "no_supported_auth";

export class SepayAuthError extends AppError {
  constructor(public readonly reason: SepayRejectReason) {
    super(
      401,
      ErrorCodes.SEPAY_SIGNATURE_INVALID,
      "Chữ ký webhook SePay không hợp lệ hoặc đã hết hạn."
    );
  }
}

const safeEqual = (a: string, b: string): boolean => {
  const left = Buffer.from(a, "utf8");
  const right = Buffer.from(b, "utf8");
  return left.length === right.length && timingSafeEqual(left, right);
};

/**
 * Xác thực webhook SePay theo hai kiểu SePay hỗ trợ:
 * - HMAC-SHA256 (khuyến nghị): `X-SePay-Signature: sha256=<hex>` ký trên
 *   `{X-SePay-Timestamp}.{raw_body}` bằng `SEPAY_WEBHOOK_SECRET`.
 * - API Key: `Authorization: Apikey <SEPAY_WEBHOOK_API_KEY>`.
 * Request có header chữ ký thì luôn kiểm HMAC; không có thì mới xét API Key.
 */
export class SepaySignatureVerifier {
  constructor(
    private readonly secret: string | undefined,
    private readonly now: Clock = () => Date.now(),
    private readonly apiKey?: string
  ) {}

  verify(
    rawBody: Buffer,
    signature: string | undefined,
    timestampHeader: string | undefined,
    authorization?: string
  ): void {
    if (!this.secret && !this.apiKey) {
      throw new AppError(
        503,
        ErrorCodes.SERVICE_UNAVAILABLE,
        "Webhook SePay chưa được cấu hình."
      );
    }

    if (signature !== undefined || timestampHeader !== undefined) {
      if (!this.secret) throw new SepayAuthError("no_supported_auth");
      this.verifyHmac(rawBody, signature, timestampHeader, this.secret);
      return;
    }

    if (
      this.apiKey &&
      authorization?.toLowerCase().startsWith(APIKEY_PREFIX)
    ) {
      const provided = authorization.slice(APIKEY_PREFIX.length).trim();
      if (!safeEqual(provided, this.apiKey)) {
        throw new SepayAuthError("apikey_mismatch");
      }
      return;
    }

    throw new SepayAuthError(
      this.secret ? "missing_signature_headers" : "no_supported_auth"
    );
  }

  private verifyHmac(
    rawBody: Buffer,
    signature: string | undefined,
    timestampHeader: string | undefined,
    secret: string
  ): void {
    if (
      !signature ||
      !/^sha256=[a-f0-9]{64}$/i.test(signature) ||
      !timestampHeader ||
      !/^\d+$/.test(timestampHeader)
    ) {
      throw new SepayAuthError("malformed_signature_headers");
    }

    const timestamp = Number(timestampHeader);
    const nowSeconds = Math.floor(this.now() / 1000);
    if (
      !Number.isSafeInteger(timestamp) ||
      Math.abs(nowSeconds - timestamp) > MAX_TIMESTAMP_DRIFT_SECONDS
    ) {
      throw new SepayAuthError("stale_timestamp");
    }

    const hmac = createHmac("sha256", secret);
    hmac.update(`${timestampHeader}.`, "utf8");
    hmac.update(rawBody);
    const expected = `${SIGNATURE_PREFIX}${hmac.digest("hex")}`;

    if (!safeEqual(expected, signature.toLowerCase())) {
      throw new SepayAuthError("hmac_mismatch");
    }
  }
}

export const sepaySignatureVerifier = new SepaySignatureVerifier(
  env.SEPAY_WEBHOOK_SECRET,
  () => Date.now(),
  env.SEPAY_WEBHOOK_API_KEY
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
    sepaySignatureVerifier.verify(
      req.rawBody ?? Buffer.alloc(0),
      req.get("X-SePay-Signature"),
      req.get("X-SePay-Timestamp"),
      req.get("Authorization")
    );
    next();
  } catch (error) {
    if (error instanceof SepayAuthError) {
      // Chỉ ghi dạng request, không ghi secret, chữ ký hay API key.
      const timestamp = Number(req.get("X-SePay-Timestamp"));
      logger.warn("SePay webhook rejected", {
        requestId: req.requestId,
        reason: error.reason,
        contentType: req.get("Content-Type") ?? null,
        bodyBytes: req.rawBody?.length ?? 0,
        hasSignature: Boolean(req.get("X-SePay-Signature")),
        hasTimestamp: Boolean(req.get("X-SePay-Timestamp")),
        timestampDriftSeconds: Number.isFinite(timestamp)
          ? Math.floor(Date.now() / 1000) - timestamp
          : null,
        authorizationScheme:
          req.get("Authorization")?.split(" ")[0] ?? null,
      });
    }
    next(error);
  }
};
