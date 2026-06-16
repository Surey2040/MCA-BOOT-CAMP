import express from 'express';
import { query } from '../db.js';

const router = express.Router();

// Fetch admin statistics and reports
router.get('/', async (req, res) => {
  try {
    const { range = 'today' } = req.query; // 'today', 'yesterday', 'weekly', 'monthly'

    let startDate;
    let endDate = 'NOW()';

    switch (range.toLowerCase()) {
      case 'yesterday':
        startDate = "CURRENT_DATE - INTERVAL '1 day'";
        endDate = 'CURRENT_DATE';
        break;
      case 'weekly':
        startDate = "CURRENT_DATE - INTERVAL '7 days'";
        break;
      case 'monthly':
        startDate = "CURRENT_DATE - INTERVAL '30 days'";
        break;
      case 'today':
      default:
        startDate = 'CURRENT_DATE';
        break;
    }

    // 1. General Stats (Total Revenue, Total Orders count)
    const statsQuery = `
      SELECT 
        COALESCE(SUM(total), 0) as total_revenue,
        COUNT(id) as total_orders,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status = 'ready' THEN 1 END) as ready_orders,
        COALESCE(AVG(total), 0) as avg_order_value
      FROM orders
      WHERE created_at >= ${startDate} AND created_at < ${endDate} AND status != 'cancelled'
    `;
    const statsResult = await query(statsQuery);
    const stats = statsResult.rows[0];

    // 2. Top Selling Item
    const topItemQuery = `
      SELECT 
        mi.name as item_name,
        SUM(oi.quantity) as quantity_sold,
        SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ${startDate} AND o.created_at < ${endDate} AND o.status != 'cancelled'
      GROUP BY mi.name
      ORDER BY quantity_sold DESC, revenue DESC
      LIMIT 5
    `;
    const topItemResult = await query(topItemQuery);
    const topItems = topItemResult.rows;
    const topSellingItem = topItems.length > 0 ? topItems[0].item_name : 'N/A';

    // 3. Category-wise Sales
    const categorySalesQuery = `
      SELECT 
        c.name as category_name,
        SUM(oi.quantity) as quantity_sold,
        SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN categories c ON mi.category_id = c.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ${startDate} AND o.created_at < ${endDate} AND o.status != 'cancelled'
      GROUP BY c.name
      ORDER BY revenue DESC
    `;
    const categoryResult = await query(categorySalesQuery);
    const categorySales = categoryResult.rows;

    // 4. Item-wise Sales
    const itemSalesQuery = `
      SELECT 
        mi.name as item_name,
        c.name as category_name,
        SUM(oi.quantity) as quantity_sold,
        SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN categories c ON mi.category_id = c.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ${startDate} AND o.created_at < ${endDate} AND o.status != 'cancelled'
      GROUP BY mi.name, c.name
      ORDER BY quantity_sold DESC
    `;
    const itemResult = await query(itemSalesQuery);
    const itemSales = itemResult.rows;

    // Return compiled dashboard and report data
    res.json({
      range,
      revenue: parseFloat(stats.total_revenue),
      totalOrders: parseInt(stats.total_orders),
      pendingOrders: parseInt(stats.pending_orders),
      readyOrders: parseInt(stats.ready_orders),
      averageOrder: parseFloat(stats.avg_order_value).toFixed(2),
      topSellingItem,
      topItems,
      categorySales,
      itemSales
    });
  } catch (error) {
    console.error('Reports compiler error:', error);
    res.status(500).json({ error: 'Failed to compile reports data' });
  }
});

export default router;
