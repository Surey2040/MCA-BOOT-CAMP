import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get all orders
router.get('/', async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      include: { items: true },
      orderBy: { createdAt: 'desc' }
    });
    
    // Parse SQLite stringified extras back to JSON array
    const parsedOrders = orders.map(order => ({
      ...order,
      items: order.items.map(item => {
        let parsedExtras = [];
        try {
          parsedExtras = typeof item.extras === 'string' ? JSON.parse(item.extras) : item.extras;
        } catch (e) {
          parsedExtras = [];
        }
        return { ...item, extras: parsedExtras };
      })
    }));

    res.json(parsedOrders);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Create a new order
router.post('/', async (req, res) => {
  try {
    const { type, total, note, items, customerName, customerMobile } = req.body;

    // 1. Get next order ID (ORD1001...)
    const lastOrder = await prisma.order.findFirst({
      orderBy: { id: 'desc' }
    });
    let nextIdNumber = 1001;
    if (lastOrder && lastOrder.id.startsWith('ORD')) {
      const lastNum = parseInt(lastOrder.id.substring(3));
      if (!isNaN(lastNum)) {
        nextIdNumber = lastNum + 1;
      }
    }
    const orderId = `ORD${nextIdNumber}`;

    // 2. Associate customer if details provided
    let customerId = null;
    if (customerName) {
      let customer = null;
      if (customerMobile) {
        customer = await prisma.customer.findUnique({
          where: { mobile: customerMobile }
        });
      }
      if (!customer) {
        customer = await prisma.customer.create({
          data: { name: customerName, mobile: customerMobile }
        });
      }
      customerId = customer.id;
    }

    // 3. Create order transaction
    const newOrder = await prisma.order.create({
      data: {
        id: orderId,
        customerId,
        type,
        status: 'pending',
        total: parseFloat(total),
        note,
        items: {
          create: items.map(item => ({
            menuItemId: parseInt(item.menuItemId),
            itemName: item.itemName,
            quantity: parseInt(item.quantity),
            price: parseFloat(item.price),
            extras: JSON.stringify(item.extras || [])
          }))
        }
      },
      include: { items: true }
    });

    // Parse SQLite stringified extras back to JSON array for frontend/socket compatibility
    const parsedOrder = {
      ...newOrder,
      items: newOrder.items.map(item => {
        let parsedExtras = [];
        try {
          parsedExtras = typeof item.extras === 'string' ? JSON.parse(item.extras) : item.extras;
        } catch (e) {
          parsedExtras = [];
        }
        return { ...item, extras: parsedExtras };
      })
    };

    // 4. Broadcast via WebSocket
    const broadcast = req.app.get('broadcast');
    if (broadcast) {
      broadcast({ type: 'ORDER_CREATED', order: parsedOrder });
    }

    res.status(201).json(parsedOrder);
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// Update order status
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const updatedOrder = await prisma.order.update({
      where: { id },
      data: { status },
      include: { items: true }
    });

    // Parse SQLite stringified extras back to JSON array
    const parsedOrder = {
      ...updatedOrder,
      items: updatedOrder.items.map(item => {
        let parsedExtras = [];
        try {
          parsedExtras = typeof item.extras === 'string' ? JSON.parse(item.extras) : item.extras;
        } catch (e) {
          parsedExtras = [];
        }
        return { ...item, extras: parsedExtras };
      })
    };

    // Broadcast update via WebSocket
    const broadcast = req.app.get('broadcast');
    if (broadcast) {
      broadcast({ type: 'ORDER_STATUS_UPDATED', order: parsedOrder });
    }

    res.json(parsedOrder);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

export default router;
