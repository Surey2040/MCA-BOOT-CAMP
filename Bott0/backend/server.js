import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { testConnection } from './db.js';

// Import Routes
import authRouter from './routes/auth.js';
import menuRouter from './routes/menu.js';
import ordersRouter from './routes/orders.js';
import customersRouter from './routes/customers.js';
import reportsRouter from './routes/reports.js';
import syncRouter from './routes/sync.js';
import settingsRouter from './routes/settings.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5001;

// Global Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Support larger payloads for backups / sync
app.use(express.urlencoded({ extended: true }));

// Mounting REST endpoints
app.use('/api/auth', authRouter);
app.use('/api/menu', menuRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/customers', customersRouter);
app.use('/api/reports', reportsRouter);
app.use('/api/sync', syncRouter);
app.use('/api/settings', settingsRouter);

// Root Health Check Route
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date(),
    service: 'Booto Shawarma POS API Backend'
  });
});

// Serve compiled Flutter Web frontend
app.use(express.static(path.join(__dirname, 'public')));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Startup verification
const startServer = async () => {
  // Try connecting to PostgreSQL, log a warning if offline
  await testConnection();

  app.listen(PORT, () => {
    console.log(`================================================================`);
    console.log(`BOOTTO SHAWARMA POS Backend running on http://localhost:${PORT}`);
    console.log(`================================================================`);
  });
};

startServer().catch(err => {
  console.error('Failed to start server:', err);
});
