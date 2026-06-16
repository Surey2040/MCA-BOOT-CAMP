import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import ExcelJS from 'exceljs';
import PDFDocument from 'pdfkit';
import pool, { query } from '../db.js';
import { authenticateToken } from './auth.js';

const router = express.Router();
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 1. Reset Daily Sales (hard deletes orders from today to reset POS counters)
router.post('/reset-daily', authenticateToken, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Delete order items for today's orders first (cascade foreign keys)
    await client.query(`
      DELETE FROM order_items 
      WHERE order_id IN (
        SELECT id FROM orders WHERE created_at >= CURRENT_DATE
      )
    `);

    // Delete today's orders
    const result = await client.query(`
      DELETE FROM orders 
      WHERE created_at >= CURRENT_DATE
      RETURNING id
    `);

    await client.query('COMMIT');

    res.json({
      message: `Daily sales reset successfully. Deleted ${result.rowCount} orders from today.`,
      count: result.rowCount
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Reset daily sales error:', error);
    res.status(500).json({ error: 'Failed to reset daily sales' });
  } finally {
    client.release();
  }
});

// 2. Database Backup (dumps all tables into a JSON structure)
router.get('/backup', authenticateToken, async (req, res) => {
  try {
    const backupData = {};
    
    const tables = ['users', 'categories', 'menu_items', 'customers', 'orders', 'order_items', 'sales_reports'];
    
    for (const table of tables) {
      const result = await query(`SELECT * FROM ${table}`);
      backupData[table] = result.rows;
    }

    // Ensure backups directory exists
    const backupsDir = path.join(__dirname, '../backups');
    if (!fs.existsSync(backupsDir)) {
      fs.mkdirSync(backupsDir, { recursive: true });
    }

    const backupFile = path.join(backupsDir, `backup-${Date.now()}.json`);
    fs.writeFileSync(backupFile, JSON.stringify(backupData, null, 2));

    res.json({
      message: 'Backup created successfully',
      file: path.basename(backupFile),
      data: backupData
    });
  } catch (error) {
    console.error('Database backup error:', error);
    res.status(500).json({ error: 'Failed to generate database backup' });
  }
});

// 3. Database Restore (clears tables and loads data from JSON structure)
router.post('/restore', authenticateToken, async (req, res) => {
  const { backup_data } = req.body;
  if (!backup_data) {
    return res.status(400).json({ error: 'backup_data object is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Disable triggers / constraint checks or delete in reverse order of FKs
    const tablesToDelete = ['order_items', 'orders', 'menu_items', 'categories', 'customers', 'users', 'sales_reports'];
    for (const table of tablesToDelete) {
      await client.query(`DELETE FROM ${table}`);
    }

    // Insert back in dependency order
    
    // users
    if (backup_data.users && backup_data.users.length > 0) {
      for (const row of backup_data.users) {
        await client.query(
          'INSERT INTO users (id, username, pin_hash, role, created_at) VALUES ($1, $2, $3, $4, $5)',
          [row.id, row.username, row.pin_hash, row.role, row.created_at]
        );
      }
    }

    // categories
    if (backup_data.categories && backup_data.categories.length > 0) {
      for (const row of backup_data.categories) {
        await client.query(
          'INSERT INTO categories (id, name, slug) VALUES ($1, $2, $3)',
          [row.id, row.name, row.slug]
        );
      }
    }

    // menu_items
    if (backup_data.menu_items && backup_data.menu_items.length > 0) {
      for (const row of backup_data.menu_items) {
        await client.query(
          'INSERT INTO menu_items (id, category_id, name, price, description, image_url, is_available, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
          [row.id, row.category_id, row.name, row.price, row.description, row.image_url, row.is_available, row.created_at]
        );
      }
    }

    // customers
    if (backup_data.customers && backup_data.customers.length > 0) {
      for (const row of backup_data.customers) {
        await client.query(
          'INSERT INTO customers (id, name, mobile, created_at) VALUES ($1, $2, $3, $4)',
          [row.id, row.name, row.mobile, row.created_at]
        );
      }
    }

    // orders
    if (backup_data.orders && backup_data.orders.length > 0) {
      for (const row of backup_data.orders) {
        await client.query(
          'INSERT INTO orders (id, customer_id, order_number, order_type, subtotal, discount, total, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
          [row.id, row.customer_id, row.order_number, row.order_type, row.subtotal, row.discount, row.total, row.status, row.created_at, row.updated_at]
        );
      }
    }

    // order_items
    if (backup_data.order_items && backup_data.order_items.length > 0) {
      for (const row of backup_data.order_items) {
        const extrasJson = typeof row.extras === 'string' ? row.extras : JSON.stringify(row.extras || []);
        await client.query(
          'INSERT INTO order_items (id, order_id, menu_item_id, quantity, price, extras, special_instructions, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
          [row.id, row.order_id, row.menu_item_id, row.quantity, row.price, extrasJson, row.special_instructions, row.created_at]
        );
      }
    }

    // sales_reports
    if (backup_data.sales_reports && backup_data.sales_reports.length > 0) {
      for (const row of backup_data.sales_reports) {
        await client.query(
          'INSERT INTO sales_reports (id, report_date, total_orders, total_revenue, top_selling_item, created_at) VALUES ($1, $2, $3, $4, $5, $6)',
          [row.id, row.report_date, row.total_orders, row.total_revenue, row.top_selling_item, row.created_at]
        );
      }
    }

    await client.query('COMMIT');
    res.json({ message: 'Database restored successfully' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Database restore error:', error);
    res.status(500).json({ error: 'Failed to restore database from backup' });
  } finally {
    client.release();
  }
});

// 4. Export to Excel (Generates a clean spreadsheet report)
router.get('/export/excel', async (req, res) => {
  try {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Sales Report');

    // Define columns
    worksheet.columns = [
      { header: 'Order ID', key: 'id', width: 25 },
      { header: 'Order #', key: 'order_number', width: 15 },
      { header: 'Type', key: 'order_type', width: 12 },
      { header: 'Subtotal (INR)', key: 'subtotal', width: 15 },
      { header: 'Discount (INR)', key: 'discount', width: 15 },
      { header: 'Total (INR)', key: 'total', width: 15 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Customer', key: 'customer_name', width: 20 },
      { header: 'Mobile', key: 'customer_mobile', width: 15 },
      { header: 'Date & Time', key: 'created_at', width: 22 }
    ];

    // Fetch order history
    const ordersResult = await query(`
      SELECT o.*, c.name as customer_name, c.mobile as customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
    `);

    // Add rows
    ordersResult.rows.forEach(order => {
      worksheet.addRow({
        id: order.id,
        order_number: order.order_number,
        order_type: order.order_type,
        subtotal: parseFloat(order.subtotal),
        discount: parseFloat(order.discount),
        total: parseFloat(order.total),
        status: order.status,
        customer_name: order.customer_name || 'Walk-in',
        customer_mobile: order.customer_mobile || '-',
        created_at: new Date(order.created_at).toLocaleString()
      });
    });

    // Style header
    worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFD4AF37' } // Gold header
    };

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename=' + `sales_report_${Date.now()}.xlsx`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    console.error('Excel export error:', error);
    res.status(500).json({ error: 'Failed to generate Excel report' });
  }
});

// 5. Export to PDF (Generates a beautifully styled invoice log PDF)
router.get('/export/pdf', async (req, res) => {
  try {
    const doc = new PDFDocument({ margin: 50 });
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=' + `sales_report_${Date.now()}.pdf`);
    
    doc.pipe(res);

    // Header Title
    doc.fillColor('#D4AF37').fontSize(26).text('BOOTO SHAWARMA', { align: 'center' });
    doc.fillColor('#E65100').fontSize(14).text('Daily Sales & POS Report', { align: 'center' });
    doc.moveDown(1.5);

    // Divider Line
    doc.strokeColor('#1E1E1E').lineWidth(2).moveTo(50, 110).lineTo(562, 110).stroke();
    doc.moveDown();

    // Summary statistics block
    const statsResult = await query(`
      SELECT 
        COALESCE(SUM(total), 0) as total_revenue,
        COUNT(id) as total_orders
      FROM orders
      WHERE status != 'cancelled'
    `);
    const stats = statsResult.rows[0];

    doc.fillColor('#121212').fontSize(12).text(`Report Compiled: ${new Date().toLocaleString()}`);
    doc.text(`Total Sales Count: ${stats.total_orders}`);
    doc.text(`Total Revenue (INR): Rs. ${parseFloat(stats.total_revenue).toFixed(2)}`);
    doc.moveDown(2);

    // Table Header
    doc.fillColor('#D4AF37').fontSize(12).text('Recent POS Orders', { underline: true });
    doc.moveDown(0.5);

    const ordersResult = await query(`
      SELECT o.order_number, o.order_type, o.total, o.status, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
      LIMIT 20
    `);

    // Draw simple column header text
    doc.fillColor('#1E1E1E').fontSize(10);
    const tableTop = doc.y;
    doc.text('Order Num', 50, tableTop, { bold: true });
    doc.text('Type', 150, tableTop, { bold: true });
    doc.text('Customer', 250, tableTop, { bold: true });
    doc.text('Total', 380, tableTop, { bold: true });
    doc.text('Status', 480, tableTop, { bold: true });
    
    doc.strokeColor('#D4AF37').lineWidth(1).moveTo(50, tableTop + 15).lineTo(550, tableTop + 15).stroke();
    doc.moveDown(1);

    let rowY = tableTop + 22;
    ordersResult.rows.forEach(order => {
      // If table crosses page limits, insert new page
      if (rowY > 700) {
        doc.addPage();
        rowY = 50;
      }
      doc.text(order.order_number, 50, rowY);
      doc.text(order.order_type, 150, rowY);
      doc.text(order.customer_name || 'Walk-in', 250, rowY);
      doc.text(`Rs. ${parseFloat(order.total).toFixed(2)}`, 380, rowY);
      doc.text(order.status, 480, rowY);
      rowY += 20;
    });

    doc.end();
  } catch (error) {
    console.error('PDF export error:', error);
    res.status(500).json({ error: 'Failed to generate PDF report' });
  }
});

export default router;
