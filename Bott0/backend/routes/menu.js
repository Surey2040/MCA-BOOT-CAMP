import express from 'express';
import { query } from '../db.js';
import { authenticateToken } from './auth.js';

const router = express.Router();

// Get all categories
router.get('/categories', async (req, res) => {
  try {
    const result = await query('SELECT * FROM categories ORDER BY id ASC');
    res.json(result.rows);
  } catch (error) {
    console.error('Fetch categories error:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// Get all menu items
router.get('/', async (req, res) => {
  try {
    const result = await query(`
      SELECT m.*, c.name as category_name 
      FROM menu_items m
      JOIN categories c ON m.category_id = c.id
      ORDER BY m.category_id ASC, m.name ASC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Fetch menu items error:', error);
    res.status(500).json({ error: 'Failed to fetch menu items' });
  }
});

// Add a new menu item
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { category_id, name, price, description, image_url, is_available = true } = req.body;

    if (!category_id || !name || price === undefined) {
      return res.status(400).json({ error: 'category_id, name, and price are required' });
    }

    const result = await query(
      `INSERT INTO menu_items (category_id, name, price, description, image_url, is_available)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [category_id, name, price, description || '', image_url || null, is_available]
    );

    res.status(201).json({
      message: 'Menu item created successfully',
      item: result.rows[0]
    });
  } catch (error) {
    console.error('Add menu item error:', error);
    if (error.code === '23505') { // Unique constraint violation
      return res.status(400).json({ error: 'Menu item with this name already exists' });
    }
    res.status(500).json({ error: 'Failed to add menu item' });
  }
});

// Update a menu item
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { category_id, name, price, description, image_url, is_available } = req.body;

    // Build dynamic update query
    const fields = [];
    const values = [];
    let idx = 1;

    if (category_id !== undefined) {
      fields.push(`category_id = $${idx++}`);
      values.push(category_id);
    }
    if (name !== undefined) {
      fields.push(`name = $${idx++}`);
      values.push(name);
    }
    if (price !== undefined) {
      fields.push(`price = $${idx++}`);
      values.push(price);
    }
    if (description !== undefined) {
      fields.push(`description = $${idx++}`);
      values.push(description);
    }
    if (image_url !== undefined) {
      fields.push(`image_url = $${idx++}`);
      values.push(image_url);
    }
    if (is_available !== undefined) {
      fields.push(`is_available = $${idx++}`);
      values.push(is_available);
    }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields provided to update' });
    }

    values.push(id);
    const queryStr = `
      UPDATE menu_items 
      SET ${fields.join(', ')} 
      WHERE id = $${idx} 
      RETURNING *
    `;

    const result = await query(queryStr, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    res.json({
      message: 'Menu item updated successfully',
      item: result.rows[0]
    });
  } catch (error) {
    console.error('Update menu item error:', error);
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Menu item with this name already exists' });
    }
    res.status(500).json({ error: 'Failed to update menu item' });
  }
});

// Delete a menu item
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query('DELETE FROM menu_items WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    res.json({
      message: 'Menu item deleted successfully',
      item: result.rows[0]
    });
  } catch (error) {
    console.error('Delete menu item error:', error);
    res.status(500).json({ error: 'Failed to delete menu item' });
  }
});

export default router;
