import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get all menu items
router.get('/', async (req, res) => {
  try {
    const items = await prisma.menuItem.findMany({
      include: { category: true },
      orderBy: { name: 'asc' }
    });
    
    // Map database model back to structure expected by client
    const formattedItems = items.map(item => ({
      id: item.id,
      category: item.category ? item.category.name : 'Uncategorized',
      name: item.name,
      price: parseFloat(item.price),
      imageUrl: item.imageUrl
    }));
    
    res.json(formattedItems);
  } catch (error) {
    console.error('Failed to fetch menu items:', error);
    res.status(500).json({ error: 'Failed to fetch menu items', details: error.message, stack: error.stack });
  }
});

// Add menu item
router.post('/', async (req, res) => {
  try {
    const { category, name, price, imageUrl } = req.body;
    
    // Find or create the Category
    let dbCategory = await prisma.category.findFirst({
      where: { name: category }
    });
    if (!dbCategory) {
      dbCategory = await prisma.category.create({
        data: {
          name: category,
          slug: category.toLowerCase().replace(/ /g, '-')
        }
      });
    }

    const newItem = await prisma.menuItem.create({
      data: { 
        categoryId: dbCategory.id, 
        name, 
        price: parseFloat(price), 
        imageUrl 
      }
    });

    res.status(201).json({
      id: newItem.id,
      category: category,
      name: newItem.name,
      price: parseFloat(newItem.price),
      imageUrl: newItem.imageUrl
    });
  } catch (error) {
    console.error('Failed to create menu item:', error);
    res.status(500).json({ error: 'Failed to create menu item' });
  }
});

export default router;
