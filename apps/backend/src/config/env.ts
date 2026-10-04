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
    CORS_ORIGIN: z.string().default("*"),
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
