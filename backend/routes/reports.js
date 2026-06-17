import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

router.get('/', async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    // 1. General statistics (Revenue, Total Orders, Average, Pending, Ready)
    const todayOrders = await prisma.order.findMany({
      where: {
        createdAt: {
          gte: todayStart,
          lte: todayEnd
        },
        status: { not: 'cancelled' }
      }
    });

    const revenue = todayOrders.reduce((sum, order) => sum + parseFloat(order.total), 0);
    const totalOrders = todayOrders.length;
    const avgOrderValue = totalOrders > 0 ? (revenue / totalOrders) : 0;

    const pendingOrdersCount = await prisma.order.count({
      where: { status: 'pending' }
    });

    const readyOrdersCount = await prisma.order.count({
      where: { status: 'ready' }
    });

    // 2. Hourly Sales distribution (for the dashboard line chart)
    const hourlySalesMap = Array.from({ length: 24 }, (_, i) => ({ hour: i, sales: 0.0 }));
    todayOrders.forEach(order => {
      const hour = new Date(order.createdAt).getHours();
      hourlySalesMap[hour].sales += parseFloat(order.total);
    });

    // 3. Top 5 items sold today
    const orderItems = await prisma.orderItem.findMany({
      where: {
        order: {
          createdAt: {
            gte: todayStart,
            lte: todayEnd
          },
          status: { not: 'cancelled' }
        }
      },
      include: {
        menuItem: true
      }
    });

    const itemTotals = {};
    orderItems.forEach(item => {
      const name = item.menuItem ? item.menuItem.name : 'Unknown Item';
      if (!itemTotals[name]) {
        itemTotals[name] = { quantity: 0, revenue: 0 };
      }
      itemTotals[name].quantity += item.quantity;
      itemTotals[name].revenue += parseFloat(item.price) * item.quantity;
    });

    const topItems = Object.entries(itemTotals)
      .map(([name, stats]) => ({
        itemName: name,
        quantitySold: stats.quantity,
        revenue: stats.revenue
      }))
      .sort((a, b) => b.quantitySold - a.quantitySold)
      .slice(0, 5);

    res.json({
      revenue,
      totalOrders,
      pendingOrdersCount,
      readyOrdersCount,
      averageOrder: avgOrderValue.toFixed(2),
      hourlySales: hourlySalesMap,
      topItems
    });
  } catch (error) {
    console.error('Reports compile failed:', error);
    res.status(500).json({ error: 'Failed to compile reports data' });
  }
});

export default router;
