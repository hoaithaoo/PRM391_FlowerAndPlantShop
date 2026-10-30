import type { NotificationType } from "@prisma/client";

export interface NotificationResponse {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: Date;
}

export interface NotificationListResponse {
  items: NotificationResponse[];
  page: number;
  total: number;
  totalPages: number;
  unreadCount: number;
}

export interface MarkNotificationReadResponse {
  id: string;
  isRead: true;
  readAt: Date;
}

export interface MarkAllNotificationsReadResponse {
  updatedCount: number;
}
