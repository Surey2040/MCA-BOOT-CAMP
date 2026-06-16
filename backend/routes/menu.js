import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get all menu items
router.get('/', async (req, res) => {
  try {
    const items = await prisma.menuItem.findMany({
      orderBy: { name: 'asc' }
    });
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch menu items' });
  }
});

// Add menu item
router.post('/', async (req, res) => {
  try {
    const { category, name, price, imageUrl } = req.body;
    const newItem = await prisma.menuItem.create({
      data: { category, name, price: parseFloat(price), imageUrl }
    });
    res.status(201).json(newItem);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create menu item' });
  }
});

export default router;
