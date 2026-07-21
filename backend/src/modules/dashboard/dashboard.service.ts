import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}
  async summary(userId: string) {
    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const monthEnd = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
    const [pendingDocuments, dueObligations, pendingPayments, monthInvoices, nextObligation, unreadNotifications, activeCnpj] = await Promise.all([
      this.prisma.document.count({ where: { userId, status: { in: ['PENDING','REJECTED'] } } }),
      this.prisma.obligation.count({ where: { userId, status: { in: ['OPEN','DUE_SOON','OVERDUE'] } } }),
      this.prisma.payment.count({ where: { userId, status: { in: ['OPEN','OVERDUE'] } } }),
      this.prisma.invoice.aggregate({ where: { userId, status: 'ISSUED', serviceDate: { gte: monthStart, lt: monthEnd } }, _sum: { amount: true }, _count: true }),
      this.prisma.obligation.findFirst({ where: { userId, status: { in: ['OPEN','DUE_SOON','OVERDUE'] } }, orderBy: { dueDate: 'asc' } }),
      this.prisma.notification.count({ where: { userId, readAt: null } }),
      this.prisma.cnpj.findFirst({ where: { userId, active: true } }),
    ]);
    const revenue = Number(monthInvoices._sum.amount ?? 0);
    return {
      pendingDocuments, openIssues: pendingDocuments + dueObligations, dueObligations, pendingPayments,
      monthRevenue: revenue, orders: monthInvoices._count, averageTicket: monthInvoices._count ? revenue / monthInvoices._count : 0,
      unreadNotifications, activeCnpj,
      nextObligation: nextObligation ? { ...nextObligation, amount: Number(nextObligation.amount) } : null,
    };
  }
}
