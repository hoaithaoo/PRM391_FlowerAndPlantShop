import { prisma } from "../../lib/prisma";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { UpdateProfileInput } from "./profile.schema";

export class ProfileService {
  async getProfile(userId: string) {
    const profile = await prisma.profile.findUnique({
      where: { id: userId },
    });

    if (!profile) {
      throw new AppError(404, ErrorCodes.USER_NOT_FOUND, "Không tìm thấy hồ sơ người dùng.");
    }

    return {
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      avatarUrl: profile.avatarUrl,
      phone: profile.phone,
      role: profile.role,
      status: profile.status,
      createdAt: profile.createdAt,
    };
  }

  async updateProfile(userId: string, input: UpdateProfileInput) {
    const existing = await prisma.profile.findUnique({
      where: { id: userId },
    });

    if (!existing) {
      throw new AppError(404, ErrorCodes.USER_NOT_FOUND, "Không tìm thấy hồ sơ người dùng.");
    }

    const updated = await prisma.profile.update({
      where: { id: userId },
      data: {
        ...(input.fullName !== undefined && { fullName: input.fullName }),
        ...(input.phone !== undefined && { phone: input.phone }),
        ...(input.avatarUrl !== undefined && { avatarUrl: input.avatarUrl }),
      },
    });

    return {
      id: updated.id,
      fullName: updated.fullName,
      phone: updated.phone,
      avatarUrl: updated.avatarUrl,
      updatedAt: updated.updatedAt,
    };
  }
}

export const profileService = new ProfileService();
