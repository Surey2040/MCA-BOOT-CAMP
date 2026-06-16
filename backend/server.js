import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { PrismaClient } from '@prisma/client';
import path from 'path';
import { fileURLToPath } from 'url';

// Routes
import menuRouter from './routes/menu.js';
import ordersRouter from './routes/orders.js';
import reportsRouter from './routes/reports.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const server = createServer(app);
const PORT = process.env.PORT || 5001;
const prisma = new PrismaClient();

// WebSocket Server
const wss = new WebSocketServer({ server });

// Shared WebSocket clients broadcasting function
const broadcast = (data) => {
  const payload = JSON.stringify(data);
  wss.clients.forEach(client => {
    if (client.readyState === 1) { // OPEN
      client.send(payload);
    }
  });
};

app.set('broadcast', broadcast);

// Middleware
app.use(cors());
app.use(express.json());

// Serve static POS interface files from the parent directory
app.use(express.static(path.join(__dirname, '../')));

// Routes
app.use('/api/menu', menuRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/reports', reportsRouter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date() });
});

// WebSocket connection handler
wss.on('connection', (ws) => {
  console.log('New WebSocket client connected');
  ws.send(JSON.stringify({ type: 'WELCOME', message: 'Connected to BooTo Shawarma WS Server' }));
  
  ws.on('close', () => {
    console.log('WebSocket client disconnected');
  });
});

// Pre-seeding database values if empty
const seedDatabase = async () => {
  try {
    // Clear old menu items to ensure they match the menu card exactly
    await prisma.menuItem.deleteMany();
    console.log('Cleared database menu items.');

    console.log('Seeding menu items to PostgreSQL database...');
    const items = [
      // Shawarma
      { category: 'Shawarma', name: 'Classic shawarma', price: 90 },
      { category: 'Shawarma', name: 'Spicy shawarma', price: 100 },
      { category: 'Shawarma', name: 'Tandoori shawarma', price: 100 },
      { category: 'Shawarma', name: 'Peri peri shawarma', price: 100 },
      { category: 'Shawarma', name: 'Maxicon shawarma', price: 100 },
      { category: 'Shawarma', name: 'Schezwan shawarma', price: 100 },
      { category: 'Shawarma', name: 'Cheese shawarma', price: 110 },
      { category: 'Shawarma', name: 'Zombie shawarma', price: 110 },
      
      // Lays Shawarma
      { category: 'Lays Shawarma', name: 'Lays role shawarma', price: 100 },
      { category: 'Lays Shawarma', name: 'Double lays role shawarma', price: 110 },
      { category: 'Lays Shawarma', name: 'Lays pocket Shawarma', price: 130 },
      { category: 'Lays Shawarma', name: 'Double Lays pocket Shawarma', price: 140 },

      // Plate Shawarma
      { category: 'Plate Shawarma', name: 'Classic plate', price: 130 },
      { category: 'Plate Shawarma', name: 'Spicy plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Thadoori plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Peri peri plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Maxicon plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Schezwan plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Zombie plate', price: 140 },
      { category: 'Plate Shawarma', name: 'Cheese plate', price: 140 },

      // Mug Shawarma
      { category: 'Mug Shawarma', name: 'Classic mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Spicy mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Thandoori mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Maxicon mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Schezwan mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Zombie mug shawarma', price: 150 },
      { category: 'Mug Shawarma', name: 'Double Cheese mug shawarma', price: 160 },

      // Special Shawarma
      { category: 'Special Shawarma', name: 'Booto Special shawarma', price: 130 },
      { category: 'Special Shawarma', name: 'Booto special plate', price: 160 },
      { category: 'Special Shawarma', name: 'Booto special mug', price: 170 },
      { category: 'Special Shawarma', name: 'Arabian gulf shawarma role', price: 130 },
      { category: 'Special Shawarma', name: 'Arabian gulf plate shawarma', price: 160 },
      { category: 'Special Shawarma', name: 'Arabian gulf mug shawarma', price: 170 }
    ];

    for (const item of items) {
      await prisma.menuItem.create({ data: item });
    }
    console.log('Seeding completed successfully!');
  } catch (err) {
    console.warn('Database seeding skipped (PostgreSQL might be offline).', err.message);
  }
};

const start = async () => {
  try {
    await seedDatabase();
    server.listen(PORT, () => {
      console.log(`BooTo Shawarma POS Backend running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
  }
};

start();
