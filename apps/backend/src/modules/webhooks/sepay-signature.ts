import { createHmac, timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { env } from "../../config/env";

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

    if (
      !signature ||
      !/^sha256=[a-f0-9]{64}$/i.test(signature) ||
      !timestampHeader ||
      !/^\d+$/.test(timestampHeader)
    ) {
      this.invalidSignature();
    }

    const timestamp = Number(timestampHeader);
    const nowSeconds = Math.floor(this.now() / 1000);
    if (
      !Number.isSafeInteger(timestamp) ||
      Math.abs(nowSeconds - timestamp) > MAX_TIMESTAMP_DRIFT_SECONDS
    ) {
      this.invalidSignature();
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
      this.invalidSignature();
    }
  }

  private invalidSignature(): never {
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
    sepaySignatureVerifier.verify(
      req.rawBody ?? Buffer.alloc(0),
      req.get("X-SePay-Signature"),
      req.get("X-SePay-Timestamp")
    );
    next();
  } catch (error) {
    next(error);
  }
};
