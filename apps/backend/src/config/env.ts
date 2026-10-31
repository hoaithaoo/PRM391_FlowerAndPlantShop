import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z
  .object({
    PORT: z.coerce.number().int().positive().max(65535).default(5000),
    NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
    DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
    DIRECT_URL: z.string().optional(),
    SUPABASE_URL: z.string().url("SUPABASE_URL must be a valid URL"),
    SUPABASE_PUBLISHABLE_KEY: z.string().min(1).optional(),
    // Backward-compatible fallbacks while Supabase phases out legacy keys.
    SUPABASE_ANON_KEY: z.string().min(1).optional(),
    SEPAY_WEBHOOK_SECRET: z.string().optional(),
    // Tài khoản nhận tiền để tạo ảnh VietQR qua SePay; thiếu thì qrUrl = null.
    SEPAY_BANK_ACCOUNT: z.string().trim().min(1).optional(),
    SEPAY_BANK_CODE: z.string().trim().min(1).optional(),
    SEPAY_QR_BASE_URL: z.string().url().default("https://qr.sepay.vn/img"),
    CORS_ORIGIN: z.string().default("*"),
    GEMINI_API_KEY: z.string().min(1).optional(),
    GEMINI_MODEL: z.string().min(1).default("gemini-3.6-flash"),
    GEMINI_EMBEDDING_MODEL: z.string().min(1).default("gemini-embedding-2"),
    GEMINI_API_BASE_URL: z.string().url().default("https://generativelanguage.googleapis.com/v1beta"),
    GEMINI_TIMEOUT_MS: z.coerce.number().int().positive().default(15000),
    CHATBOT_RATE_LIMIT_MS: z.coerce.number().int().min(0).default(1000),
    RAG_EMBEDDING_DIMENSIONS: z.coerce.number().int().default(768),
    RAG_MIN_SEMANTIC_SCORE: z.coerce.number().min(-1).max(1).default(0.55),
  })
  .superRefine((value, context) => {
    const hasSupabaseKey = value.SUPABASE_PUBLISHABLE_KEY || value.SUPABASE_ANON_KEY;

    if (!hasSupabaseKey) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["SUPABASE_PUBLISHABLE_KEY"],
        message: "SUPABASE_PUBLISHABLE_KEY is required (legacy keys are also accepted)",
      });
    }
    if (value.RAG_EMBEDDING_DIMENSIONS !== 768) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["RAG_EMBEDDING_DIMENSIONS"],
        message: "RAG_EMBEDDING_DIMENSIONS must be 768 to match the pgvector schema",
      });
    }
  });

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("❌ Invalid environment variables:", parsedEnv.error.format());
  process.exit(1);
}

export const env = parsedEnv.data;

// A publishable key is sufficient for auth.getUser(token) and follows least privilege.
// The legacy anon key remains a temporary low-privilege compatibility fallback.
export const supabaseApiKey = env.SUPABASE_PUBLISHABLE_KEY ?? env.SUPABASE_ANON_KEY!;
