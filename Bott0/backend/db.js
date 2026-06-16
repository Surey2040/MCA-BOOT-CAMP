import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const poolConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'booto_shawarma',
};

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err.message);
});

export const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('Successfully connected to PostgreSQL database:', poolConfig.database);
    client.release();
    return true;
  } catch (error) {
    console.error('\n================================================================');
    console.error('WARNING: Could not connect to PostgreSQL database!');
    console.error('Reason:', error.message);
    console.error('Ensure PostgreSQL is running and credentials in backend/.env match.');
    console.error('================================================================\n');
    return false;
  }
};

export const query = async (text, params) => {
  return pool.query(text, params);
};

export default pool;
