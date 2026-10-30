import { Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import {
  ListNotificationsQuery,
  NOTIFICATIONS_PAGE_SIZE,
} from "./notification.schema";
import type {
  MarkAllNotificationsReadResponse,
  MarkNotificationReadResponse,
  NotificationListResponse,
} from "./notification.type";

type NotificationDatabase = Pick<PrismaClient, "$transaction" | "notification">;
type Clock = () => Date;

const notificationSelect = {
  id: true,
  type: true,
  title: true,
  message: true,
  isRead: true,
  createdAt: true,
} satisfies Prisma.NotificationSelect;

const markReadSelect = {
  id: true,
  isRead: true,
  readAt: true,
} satisfies Prisma.NotificationSelect;

export class NotificationService {
  constructor(
    private readonly db: NotificationDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async list(
    userId: string,
    query: ListNotificationsQuery
  ): Promise<NotificationListResponse> {
    const where: Prisma.NotificationWhereInput = {
      userId,
      ...(query.unreadOnly && { isRead: false }),
    };

    const [items, total, unreadCount] = await this.db.$transaction(
      [
        this.db.notification.findMany({
          where,
          orderBy: [{ createdAt: "desc" }, { id: "desc" }],
          skip: (query.page - 1) * NOTIFICATIONS_PAGE_SIZE,
          take: NOTIFICATIONS_PAGE_SIZE,
          select: notificationSelect,
        }),
        this.db.notification.count({ where }),
        this.db.notification.count({ where: { userId, isRead: false } }),
      ],
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead }
    );

    return {
      items,
      page: query.page,
      total,
      totalPages: Math.ceil(total / NOTIFICATIONS_PAGE_SIZE),
      unreadCount,
    };
  }

  async markRead(
    userId: string,
    notificationId: string
  ): Promise<MarkNotificationReadResponse> {
    const readAt = this.now();
    const result = await this.db.notification.updateMany({
      where: { id: notificationId, userId, isRead: false },
      data: { isRead: true, readAt },
    });

    if (result.count > 0) {
      return { id: notificationId, isRead: true, readAt };
    }

    const existing = await this.db.notification.findFirst({
      where: { id: notificationId, userId },
      select: markReadSelect,
    });
    if (!existing || !existing.isRead || !existing.readAt) {
      throw new AppError(
        404,
        ErrorCodes.NOTIFICATION_NOT_FOUND,
        "Không tìm thấy thông báo này."
      );
    }

    return {
      id: existing.id,
      isRead: true,
      readAt: existing.readAt,
    };
  }

  async markAllRead(userId: string): Promise<MarkAllNotificationsReadResponse> {
    const result = await this.db.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: this.now() },
    });

    return { updatedCount: result.count };
  }
}

export const notificationService = new NotificationService();
