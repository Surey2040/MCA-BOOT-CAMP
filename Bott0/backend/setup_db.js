import pg from 'pg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const { Client } = pg;

const connectionConfig = {
  host: '127.0.0.1',
  port: 5432,
  user: 'postgres',
  password: 'postgres',
};

async function setup() {
  console.log('Starting PostgreSQL Database Setup...');
  
  // 1. Connect to default 'postgres' database
  const client = new Client({ ...connectionConfig, database: 'postgres' });
  try {
    await client.connect();
    console.log('Connected to default postgres database.');
  } catch (err) {
    console.error('Error connecting to PostgreSQL:', err.message);
    console.error('Please ensure PostgreSQL service is installed and running on port 5432 with password "postgres".');
    process.exit(1);
  }

  // 2. Check if 'booto_shawarma' database exists
  try {
    const res = await client.query("SELECT 1 FROM pg_database WHERE datname = 'booto_shawarma'");
    if (res.rowCount === 0) {
      console.log("Database 'booto_shawarma' does not exist. Creating database...");
      await client.query("CREATE DATABASE booto_shawarma");
      console.log("Database 'booto_shawarma' created successfully.");
    } else {
      console.log("Database 'booto_shawarma' already exists.");
    }
  } catch (err) {
    console.error('Error checking/creating database:', err.message);
    await client.end();
    process.exit(1);
  } finally {
    await client.end();
  }

  // 3. Connect to the 'booto_shawarma' database and run schema.sql
  const dbClient = new Client({ ...connectionConfig, database: 'booto_shawarma' });
  try {
    await dbClient.connect();
    console.log("Connected to 'booto_shawarma' database. Running schema.sql...");
    
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    
    await dbClient.query(schemaSql);
    console.log('Database tables created and seeded successfully.');
  } catch (err) {
    console.error('Error running schema.sql:', err.message);
    process.exit(1);
  } finally {
    await dbClient.end();
  }
  
  console.log('Setup finished successfully!');
}

setup();
