import { Session, User, createClient } from "@supabase/supabase-js";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { env, supabaseApiKey } from "../../config/env";
import { logger } from "../../lib/logger";
import { prisma } from "../../lib/prisma";
import type { LoginInput, RefreshInput } from "./auth.schema";

// Tạo client riêng mỗi lần để session của người này không dính sang request khác.
const createAuthClient = () =>
  createClient(env.SUPABASE_URL, supabaseApiKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

const profileSelect = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  avatarUrl: true,
  role: true,
  status: true,
  createdAt: true,
} as const;

const metadataString = (user: User, key: string): string | null => {
  const value = user.user_metadata?.[key];
  return typeof value === "string" ? value : null;
};

export class AuthService {
  async login(input: LoginInput) {
    const { data, error } = await createAuthClient().auth.signInWithPassword({
      email: input.email,
      password: input.password,
    });
    if (error || !data.session || !data.user) {
      this.throwProviderError(error?.status, "Email hoặc mật khẩu không đúng.");
    }
    return this.buildSession(data.session!, data.user!);
  }

  async refresh(input: RefreshInput) {
    const { data, error } = await createAuthClient().auth.refreshSession({
      refresh_token: input.refreshToken,
    });
    if (error || !data.session || !data.user) {
      this.throwProviderError(error?.status, "Refresh token không hợp lệ hoặc đã hết hạn.");
    }
    return this.buildSession(data.session!, data.user!);
  }

  private async buildSession(session: Session, user: User) {
    // Đồng bộ profile giống profileMiddleware; không bao giờ nhận role/status từ client.
    const profile = await prisma.profile.upsert({
      where: { id: user.id },
      create: {
        id: user.id,
        email: user.email ?? null,
        fullName: metadataString(user, "full_name") ?? metadataString(user, "name"),
        avatarUrl: metadataString(user, "avatar_url"),
        role: "USER",
        status: "ACTIVE",
      },
      update: {},
      select: profileSelect,
    });

    if (profile.status === "DISABLED") {
      throw new AppError(403, ErrorCodes.ACCOUNT_DISABLED, "Tài khoản đã bị khóa.");
    }

    return {
      token: session.access_token,
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      tokenType: session.token_type,
      expiresIn: session.expires_in,
      expiresAt: session.expires_at ?? null,
      profile,
    };
  }

  private throwProviderError(status: number | undefined, message: string): never {
    if (status && status >= 500) {
      logger.warn("Supabase auth provider error", { status });
      throw new AppError(
        503,
        ErrorCodes.AUTH_PROVIDER_UNAVAILABLE,
        "Dịch vụ xác thực Supabase tạm thời không khả dụng."
      );
    }
    if (status === 429) {
      throw new AppError(429, ErrorCodes.RATE_LIMITED, "Thử đăng nhập quá nhiều lần, vui lòng đợi.");
    }
    throw new AppError(401, ErrorCodes.AUTH_INVALID_CREDENTIALS, message);
  }
}

export const authService = new AuthService();
