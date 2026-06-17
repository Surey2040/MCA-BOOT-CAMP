import express from 'express';
import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';

const router = express.Router();
const prisma = new PrismaClient();

// Get all orders
router.get('/', async (req, res) => {
  try {
    const orders = await prisma.order.findMany({
      include: {
        items: {
          include: { menuItem: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    
    // Format response to match client expectation
    const formattedOrders = orders.map(order => ({
      id: order.id,
      customerId: order.customerId,
      type: order.orderType,
      status: order.status,
      total: parseFloat(order.total),
      note: order.items[0]?.specialInstructions || '',
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items.map(item => ({
        id: item.id,
        orderId: item.orderId,
        menuItemId: item.menuItemId,
        itemName: item.menuItem ? item.menuItem.name : 'Unknown',
        quantity: item.quantity,
        price: parseFloat(item.price),
        extras: typeof item.extras === 'string' ? JSON.parse(item.extras) : item.extras
      }))
    }));

    res.json(formattedOrders);
  } catch (error) {
    console.error('Failed to fetch orders:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Create a new order
router.post('/', async (req, res) => {
  try {
    const { type, total, note, items, customerName, customerMobile } = req.body;

    // 1. Generate clean sequential Order Number (e.g. ORDYYMMDD-XXXX)
    const todayCount = (await prisma.order.count({
      where: {
        createdAt: {
          gte: new Date(new Date().setHours(0, 0, 0, 0))
        }
      }
    })) + 1;
    const formattedDate = new Date().toISOString().slice(2, 10).replace(/-/g, '');
    const orderNumber = `ORD${formattedDate}-${todayCount.toString().padStart(4, '0')}`;
    const orderId = `ORD${Date.now()}`;

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
        orderNumber,
        orderType: type || 'Dine In',
        subtotal: parseFloat(total),
        discount: 0.00,
        total: parseFloat(total),
        status: 'pending',
        items: {
          create: items.map(item => ({
            id: `OI-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
            menuItemId: parseInt(item.menuItemId),
            quantity: parseInt(item.quantity),
            price: parseFloat(item.price),
            extras: item.extras || [],
            specialInstructions: note || ''
          }))
        }
      },
      include: {
        items: {
          include: { menuItem: true }
        }
      }
    });

    const formattedOrder = {
      id: newOrder.id,
      customerId: newOrder.customerId,
      type: newOrder.orderType,
      status: newOrder.status,
      total: parseFloat(newOrder.total),
      note: newOrder.items[0]?.specialInstructions || '',
      createdAt: newOrder.createdAt,
      updatedAt: newOrder.updatedAt,
      items: newOrder.items.map(item => ({
        id: item.id,
        orderId: item.orderId,
        menuItemId: item.menuItemId,
        itemName: item.menuItem ? item.menuItem.name : 'Unknown',
        quantity: item.quantity,
        price: parseFloat(item.price),
        extras: item.extras
      }))
    };

    // 4. Broadcast via WebSocket
    const broadcast = req.app.get('broadcast');
    if (broadcast) {
      broadcast({ type: 'ORDER_CREATED', order: formattedOrder });
    }

    res.status(201).json(formattedOrder);
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
      include: {
        items: {
          include: { menuItem: true }
        }
      }
    });

    const formattedOrder = {
      id: updatedOrder.id,
      customerId: updatedOrder.customerId,
      type: updatedOrder.orderType,
      status: updatedOrder.status,
      total: parseFloat(updatedOrder.total),
      note: updatedOrder.items[0]?.specialInstructions || '',
      createdAt: updatedOrder.createdAt,
      updatedAt: updatedOrder.updatedAt,
      items: updatedOrder.items.map(item => ({
        id: item.id,
        orderId: item.orderId,
        menuItemId: item.menuItemId,
        itemName: item.menuItem ? item.menuItem.name : 'Unknown',
        quantity: item.quantity,
        price: parseFloat(item.price),
        extras: item.extras
      }))
    };

    // Broadcast update via WebSocket
    const broadcast = req.app.get('broadcast');
    if (broadcast) {
      broadcast({ type: 'ORDER_STATUS_UPDATED', order: formattedOrder });
    }

    res.json(formattedOrder);
  } catch (error) {
    console.error('Failed to update order status:', error);
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

export default router;
