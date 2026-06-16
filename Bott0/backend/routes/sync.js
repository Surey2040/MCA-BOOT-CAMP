import express from 'express';
import pool, { query } from '../db.js';

const router = express.Router();

// Synchronize endpoint
router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    const { orders = [], order_items = [] } = req.body;

    await client.query('BEGIN');

    const syncedOrderIds = [];

    // 1. Process orders uploaded from offline state
    for (const order of orders) {
      // Check if order already exists on server to prevent duplicates
      const checkResult = await client.query('SELECT id FROM orders WHERE id = $1', [order.id]);
      
      if (checkResult.rows.length === 0) {
        // Insert order
        // Check if customer needs to be created or linked
        let customerId = order.customer_id || null;
        
        // If customer details are embedded, ensure customer exists
        if (order.customer_mobile && !customerId) {
          const custCheck = await client.query('SELECT id FROM customers WHERE mobile = $1', [order.customer_mobile]);
          if (custCheck.rows.length > 0) {
            customerId = custCheck.rows[0].id;
          } else if (order.customer_name) {
            const custInsert = await client.query(
              'INSERT INTO customers (name, mobile) VALUES ($1, $2) RETURNING id',
              [order.customer_name, order.customer_mobile]
            );
            customerId = custInsert.rows[0].id;
          }
        }

        // Generate dynamic Order Number if not exists
        let orderNumber = order.order_number;
        if (!orderNumber) {
          const orderNumResult = await client.query(
            `SELECT count(*) FROM orders WHERE created_at >= CURRENT_DATE`
          );
          const todayCount = parseInt(orderNumResult.rows[0].count) + 1;
          const formattedDate = new Date().toISOString().slice(2, 10).replace(/-/g, '');
          orderNumber = `ORD${formattedDate}-${todayCount.toString().padStart(4, '0')}`;
        }

        await client.query(
          `INSERT INTO orders (id, customer_id, order_number, order_type, subtotal, discount, total, status, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            order.id,
            customerId,
            orderNumber,
            order.order_type || 'Dine In',
            order.subtotal,
            order.discount || 0.00,
            order.total,
            order.status || 'pending',
            order.created_at || new Date()
          ]
        );
      }
      syncedOrderIds.push(order.id);
    }

    // 2. Process order items uploaded from offline state
    for (const item of order_items) {
      const checkItem = await client.query('SELECT id FROM order_items WHERE id = $1', [item.id]);
      if (checkItem.rows.length === 0) {
        const extrasJson = typeof item.extras === 'string' ? item.extras : JSON.stringify(item.extras || []);
        
        await client.query(
          `INSERT INTO order_items (id, order_id, menu_item_id, quantity, price, extras, special_instructions)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            item.id,
            item.order_id,
            item.menu_item_id,
            item.quantity,
            item.price,
            extrasJson,
            item.special_instructions || ''
          ]
        );
      }
    }

    await client.query('COMMIT');

    // 3. Retrieve latest categories and menu items to sync back to client
    const categoriesResult = await client.query('SELECT * FROM categories ORDER BY id ASC');
    const menuItemsResult = await client.query(`
      SELECT m.*, c.name as category_name 
      FROM menu_items m
      JOIN categories c ON m.category_id = c.id
      ORDER BY m.category_id ASC, m.name ASC
    `);

    // Retrieve active orders for today (in case other devices modified them)
    const activeOrdersResult = await client.query(`
      SELECT o.*, c.name as customer_name, c.mobile as customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.created_at >= CURRENT_DATE - INTERVAL '1 day'
      ORDER BY o.created_at DESC
    `);
    const activeOrders = activeOrdersResult.rows;

    res.json({
      success: true,
      synced_order_ids: syncedOrderIds,
      categories: categoriesResult.rows,
      menu_items: menuItemsResult.rows,
      active_orders: activeOrders
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Offline synchronization error:', error);
    res.status(500).json({ error: 'Failed to synchronize offline data' });
  } finally {
    client.release();
  }
});

export default router;
