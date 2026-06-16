import express from 'express';
import { query } from '../db.js';
import pool from '../db.js';

const router = express.Router();

// Helper: Get items for a list of order IDs
const fetchOrderItems = async (orderIds) => {
  if (orderIds.length === 0) return {};
  
  // Create safe parameter list ($1, $2, ...)
  const placeholders = orderIds.map((_, i) => `$${i + 1}`).join(', ');
  const result = await query(
    `SELECT oi.*, mi.name as item_name, mi.price as item_base_price 
     FROM order_items oi
     LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
     WHERE oi.order_id IN (${placeholders})`,
    orderIds
  );

  // Group by order_id
  const itemsMap = {};
  result.rows.forEach(item => {
    if (!itemsMap[item.order_id]) {
      itemsMap[item.order_id] = [];
    }
    itemsMap[item.order_id].push(item);
  });
  return itemsMap;
};

// Get all orders (with optional status filtering)
router.get('/', async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    
    let queryStr = `
      SELECT o.*, c.name as customer_name, c.mobile as customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
    `;
    
    const params = [];
    if (status) {
      queryStr += ` WHERE o.status = $1`;
      params.push(status);
    }
    
    queryStr += ` ORDER BY o.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const ordersResult = await query(queryStr, params);
    const orders = ordersResult.rows;

    if (orders.length > 0) {
      const orderIds = orders.map(o => o.id);
      const itemsMap = await fetchOrderItems(orderIds);
      
      orders.forEach(o => {
        o.items = itemsMap[o.id] || [];
      });
    }

    res.json(orders);
  } catch (error) {
    console.error('Fetch orders error:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Get a single order by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const orderResult = await query(
      `SELECT o.*, c.name as customer_name, c.mobile as customer_mobile
       FROM orders o
       LEFT JOIN customers c ON o.customer_id = c.id
       WHERE o.id = $1`,
      [id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];
    const itemsMap = await fetchOrderItems([order.id]);
    order.items = itemsMap[order.id] || [];

    res.json(order);
  } catch (error) {
    console.error('Fetch order detail error:', error);
    res.status(500).json({ error: 'Failed to fetch order details' });
  }
});

// Create a new order (with transactional consistency)
router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    const {
      id, // Client UUID or ID
      customer_name,
      customer_mobile,
      order_type, // 'Dine In' or 'Take Away'
      subtotal,
      discount = 0.00,
      total,
      items = [] // Array: [{ id, menu_item_id, quantity, price, extras, special_instructions }]
    } = req.body;

    if (!items || items.length === 0 || !total) {
      return res.status(400).json({ error: 'Invalid order data. Items and total are required.' });
    }

    const orderId = id || `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    await client.query('BEGIN');

    // 1. Handle Customer upsert if customer details are provided
    let customerId = null;
    if (customer_mobile) {
      const custCheck = await client.query('SELECT id FROM customers WHERE mobile = $1', [customer_mobile]);
      if (custCheck.rows.length > 0) {
        customerId = custCheck.rows[0].id;
        // Optionally update customer name if changed
        if (customer_name) {
          await client.query('UPDATE customers SET name = $1 WHERE id = $2', [customer_name, customerId]);
        }
      } else if (customer_name) {
        const custInsert = await client.query(
          'INSERT INTO customers (name, mobile) VALUES ($1, $2) RETURNING id',
          [customer_name, customer_mobile]
        );
        customerId = custInsert.rows[0].id;
      }
    } else if (customer_name) {
      // Just insert without unique mobile check
      const custInsert = await client.query(
        'INSERT INTO customers (name) VALUES ($1) RETURNING id',
        [customer_name]
      );
      customerId = custInsert.rows[0].id;
    }

    // 2. Generate clean sequential Order Number (e.g. #ORD1024)
    // We get the max ID or simply count orders of today
    const orderNumResult = await client.query(
      `SELECT count(*) FROM orders WHERE created_at >= CURRENT_DATE`
    );
    const todayCount = parseInt(orderNumResult.rows[0].count) + 1;
    const formattedDate = new Date().toISOString().slice(2, 10).replace(/-/g, '');
    const orderNumber = `ORD${formattedDate}-${todayCount.toString().padStart(4, '0')}`;

    // 3. Create the Order
    const orderInsertQuery = `
      INSERT INTO orders (id, customer_id, order_number, order_type, subtotal, discount, total, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending')
      RETURNING *
    `;
    const orderResult = await client.query(orderInsertQuery, [
      orderId,
      customerId,
      orderNumber,
      order_type || 'Dine In',
      subtotal,
      discount,
      total
    ]);

    const createdOrder = orderResult.rows[0];

    // 4. Create Order Items
    for (const item of items) {
      const itemId = item.id || `OI-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
      const itemInsertQuery = `
        INSERT INTO order_items (id, order_id, menu_item_id, quantity, price, extras, special_instructions)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `;
      
      const extrasJson = typeof item.extras === 'string' ? item.extras : JSON.stringify(item.extras || []);
      
      await client.query(itemInsertQuery, [
        itemId,
        orderId,
        item.menu_item_id,
        item.quantity,
        item.price,
        extrasJson,
        item.special_instructions || ''
      ]);
    }

    await client.query('COMMIT');

    // Fetch back the complete created order structure
    const freshItemsResult = await client.query(
      `SELECT oi.*, mi.name as item_name 
       FROM order_items oi
       LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
       WHERE oi.order_id = $1`,
      [orderId]
    );

    createdOrder.items = freshItemsResult.rows;
    createdOrder.customer_name = customer_name || null;
    createdOrder.customer_mobile = customer_mobile || null;

    res.status(201).json({
      message: 'Order created successfully',
      order: createdOrder
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create order transaction error:', error);
    res.status(500).json({ error: 'Failed to create order due to database error' });
  } finally {
    client.release();
  }
});

// Update order status (mark ready, complete, or cancel)
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'pending', 'ready', 'completed', 'cancelled'

    if (!['pending', 'ready', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    const result = await query(
      `UPDATE orders 
       SET status = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $2 
       RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({
      message: `Order status updated to ${status}`,
      order: result.rows[0]
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

export default router;
