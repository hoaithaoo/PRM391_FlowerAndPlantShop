import {
  InvoiceStatus,
  OrderStatus,
  Prisma,
  PrismaClient,
  Role,
} from "@prisma/client";
import { toNumber } from "../../common/utils/decimal";
import { prisma } from "../../lib/prisma";
import { DashboardQuery, isDateOnly } from "./dashboard.schema";

type DashboardDatabase = Pick<
  PrismaClient,
  "$transaction" | "$queryRaw" | "profile" | "product" | "order" | "invoice"
>;
type Clock = () => Date;

export const LOW_STOCK_THRESHOLD = 5;
const DAY_MS = 24 * 60 * 60 * 1000;
// Cửa hàng hoạt động theo giờ Việt Nam (UTC+7, không có DST).
const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
const DEFAULT_RANGE_DAYS = 30;

const startOfVnDay = (date: Date): Date =>
  new Date(
    Math.floor((date.getTime() + VN_OFFSET_MS) / DAY_MS) * DAY_MS - VN_OFFSET_MS
  );

const startOfVnMonth = (date: Date): Date => {
  const vn = new Date(date.getTime() + VN_OFFSET_MS);
  return new Date(
    Date.UTC(vn.getUTCFullYear(), vn.getUTCMonth(), 1) - VN_OFFSET_MS
  );
};

// YYYY-MM-DD được hiểu là ngày theo giờ VN; `to` dạng ngày bao gồm cả ngày đó.
const parseFrom = (value: string): Date =>
  isDateOnly(value)
    ? new Date(Date.parse(`${value}T00:00:00+07:00`))
    : new Date(value);

const parseToExclusive = (value: string): Date =>
  isDateOnly(value)
    ? new Date(Date.parse(`${value}T00:00:00+07:00`) + DAY_MS)
    : new Date(Date.parse(value) + 1);

interface DailyRevenueRow {
  date: string;
  revenue: Prisma.Decimal | null;
  orderCount: bigint;
}

export class DashboardService {
  constructor(
    private readonly db: DashboardDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async getStats(query: DashboardQuery) {
    const now = this.now();
    const hasRange = Boolean(query.from || query.to);
    const rangeEnd = query.to ? parseToExclusive(query.to) : new Date(now.getTime() + 1);
    const rangeStart = query.from
      ? parseFrom(query.from)
      : hasRange
        ? new Date(0)
        : new Date(startOfVnDay(now).getTime() - (DEFAULT_RANGE_DAYS - 1) * DAY_MS);
    const createdInRange = hasRange ? { gte: rangeStart, lt: rangeEnd } : undefined;
    const paidInRange = { gte: rangeStart, lt: rangeEnd };
    const paidRevenueWhere = (paidAt: Prisma.DateTimeFilter<"Invoice"> | undefined) => ({
      where: { status: InvoiceStatus.PAID, ...(paidAt && { paidAt }) },
      _sum: { grandTotal: true as const },
    });

    const [
      totalUsers,
      totalProducts,
      totalOrders,
      pendingOrders,
      lowStockProducts,
      paidRevenue,
      revenueToday,
      revenueMonth,
    ] = await this.db.$transaction([
      this.db.profile.count({ where: { role: Role.USER } }),
      this.db.product.count({ where: { isActive: true } }),
      this.db.order.count({
        where: createdInRange ? { createdAt: createdInRange } : {},
      }),
      this.db.order.count({ where: { status: OrderStatus.PENDING } }),
      this.db.product.count({
        where: { isActive: true, stock: { lte: LOW_STOCK_THRESHOLD } },
      }),
      // Không truyền range => doanh thu toàn thời gian, đúng spec "trong range".
      this.db.invoice.aggregate(paidRevenueWhere(hasRange ? paidInRange : undefined)),
      this.db.invoice.aggregate(paidRevenueWhere({ gte: startOfVnDay(now) })),
      this.db.invoice.aggregate(paidRevenueWhere({ gte: startOfVnMonth(now) })),
    ]);

    const daily = await this.db.$queryRaw<DailyRevenueRow[]>`
      SELECT
        to_char((paid_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, 'YYYY-MM-DD') AS "date",
        SUM(grand_total) AS "revenue",
        COUNT(*) AS "orderCount"
      FROM invoices
      WHERE status = 'PAID'
        AND paid_at >= ${rangeStart}
        AND paid_at < ${rangeEnd}
      GROUP BY 1
      ORDER BY 1`;

    const sum = (value: Prisma.Decimal | null) => (value ? toNumber(value) : 0);
    const stats = {
      totalUsers,
      totalProducts,
      totalOrders,
      pendingOrders,
      paidRevenue: sum(paidRevenue._sum.grandTotal),
      lowStockProducts,
      lowStockThreshold: LOW_STOCK_THRESHOLD,
      revenueToday: sum(revenueToday._sum.grandTotal),
      revenueMonth: sum(revenueMonth._sum.grandTotal),
      // Chưa có giá vốn trong schema nên chỉ trả doanh thu và số đơn theo ngày.
      dailyRevenue: daily.map((row) => ({
        date: row.date,
        revenue: row.revenue ? Number(row.revenue.toString()) : 0,
        orderCount: Number(row.orderCount),
      })),
      from: hasRange ? rangeStart : null,
      to: hasRange ? rangeEnd : null,
    };
    return stats;
  }
}

export const dashboardService = new DashboardService();
