import express from 'express';
import { query } from '../db.js';

const router = express.Router();

// Get list of customers (with optional search filter)
router.get('/', async (req, res) => {
  try {
    const { search } = req.query;
    let queryStr = `SELECT * FROM customers`;
    const params = [];

    if (search) {
      queryStr += ` WHERE name ILIKE $1 OR mobile ILIKE $1`;
      params.push(`%${search}%`);
    }

    queryStr += ` ORDER BY name ASC`;
    const result = await query(queryStr, params);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Fetch customers error:', error);
    res.status(500).json({ error: 'Failed to fetch customers' });
  }
});

// Get order history for a specific customer
router.get('/:id/history', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Fetch orders
    const ordersResult = await query(
      `SELECT * FROM orders WHERE customer_id = $1 ORDER BY created_at DESC`,
      [id]
    );
    const orders = ordersResult.rows;

    if (orders.length > 0) {
      const orderIds = orders.map(o => o.id);
      
      // Fetch order items
      const placeholders = orderIds.map((_, i) => `$${i + 1}`).join(', ');
      const itemsResult = await query(
        `SELECT oi.*, mi.name as item_name 
         FROM order_items oi
         LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
         WHERE oi.order_id IN (${placeholders})`,
        orderIds
      );

      // Group items by order_id
      const itemsMap = {};
      itemsResult.rows.forEach(item => {
        if (!itemsMap[item.order_id]) {
          itemsMap[item.order_id] = [];
        }
        itemsMap[item.order_id].push(item);
      });

      orders.forEach(o => {
        o.items = itemsMap[o.id] || [];
      });
    }

    res.json(orders);
  } catch (error) {
    console.error('Fetch customer history error:', error);
    res.status(500).json({ error: 'Failed to fetch customer history' });
  }
});

// Create customer manually
router.post('/', async (req, res) => {
  try {
    const { name, mobile } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Customer name is required' });
    }

    const result = await query(
      `INSERT INTO customers (name, mobile) 
       VALUES ($1, $2) 
       ON CONFLICT (mobile) DO UPDATE SET name = EXCLUDED.name
       RETURNING *`,
      [name, mobile || null]
    );

    res.status(201).json({
      message: 'Customer registered successfully',
      customer: result.rows[0]
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ error: 'Failed to register customer' });
  }
});

export default router;
