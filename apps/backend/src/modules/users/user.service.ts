import {
  InvoiceStatus,
  Prisma,
  PrismaClient,
  Role,
  UserStatus,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { toNumber } from "../../common/utils/decimal";
import { toPageMeta, toSkipTake } from "../../common/utils/pagination";
import { prisma } from "../../lib/prisma";
import type { AdminListUsersQuery, AdminUpdateUserInput } from "./user.schema";

type UserDatabase = Pick<PrismaClient, "$transaction" | "profile" | "invoice">;

const userSelect = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  avatarUrl: true,
  role: true,
  status: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.ProfileSelect;

const notFound = () =>
  new AppError(404, ErrorCodes.USER_NOT_FOUND, "Không tìm thấy người dùng.");

export class UserService {
  constructor(private readonly db: UserDatabase = prisma) {}

  async adminList(query: AdminListUsersQuery) {
    const contains = query.search
      ? { contains: query.search, mode: "insensitive" as const }
      : undefined;
    const where: Prisma.ProfileWhereInput = {
      ...(query.role && { role: query.role }),
      ...(query.status && { status: query.status }),
      ...(contains && {
        OR: [{ email: contains }, { fullName: contains }, { phone: contains }],
      }),
    };

    const [users, total] = await this.db.$transaction([
      this.db.profile.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: userSelect,
      }),
      this.db.profile.count({ where }),
    ]);
    return { items: users, meta: toPageMeta(query, total) };
  }

  async adminGet(userId: string) {
    const [user, paid] = await this.db.$transaction([
      this.db.profile.findUnique({
        where: { id: userId },
        select: { ...userSelect, _count: { select: { orders: true } } },
      }),
      // Tính theo invoice PAID để gồm cả đơn COD (không có bản ghi payment).
      this.db.invoice.aggregate({
        where: { userId, status: InvoiceStatus.PAID },
        _sum: { grandTotal: true },
      }),
    ]);
    if (!user) throw notFound();

    const { _count, ...profile } = user;
    return {
      ...profile,
      orderCount: _count.orders,
      totalPaid: paid._sum.grandTotal ? toNumber(paid._sum.grandTotal) : 0,
    };
  }

  async adminUpdate(
    actorId: string,
    userId: string,
    input: AdminUpdateUserInput
  ) {
    const losesAdminAccess =
      input.status === UserStatus.DISABLED || input.role === Role.USER;
    if (actorId === userId && losesAdminAccess) {
      throw new AppError(
        409,
        ErrorCodes.ADMIN_SELF_LOCK_FORBIDDEN,
        "Không thể tự khóa hoặc tự hạ quyền tài khoản admin đang đăng nhập."
      );
    }

    return this.db.$transaction(
      async (tx) => {
        const user = await tx.profile.findUnique({
          where: { id: userId },
          select: { id: true, role: true, status: true },
        });
        if (!user) throw notFound();

        // Không để hệ thống mất admin ACTIVE cuối cùng.
        if (
          losesAdminAccess &&
          user.role === Role.ADMIN &&
          user.status === UserStatus.ACTIVE
        ) {
          const activeAdmins = await tx.profile.count({
            where: { role: Role.ADMIN, status: UserStatus.ACTIVE },
          });
          if (activeAdmins <= 1) {
            throw new AppError(
              409,
              ErrorCodes.ADMIN_SELF_LOCK_FORBIDDEN,
              "Không thể khóa hoặc hạ quyền admin đang hoạt động cuối cùng."
            );
          }
        }

        return tx.profile.update({
          where: { id: userId },
          data: {
            ...(input.role && { role: input.role }),
            ...(input.status && { status: input.status }),
          },
          select: userSelect,
        });
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable }
    );
  }
}

export const userService = new UserService();
