-- Schema for BOOTO SHAWARMA PostgreSQL Database

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table 1: users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    pin_hash VARCHAR(255) NOT NULL, -- bcrypt hash of PIN
    role VARCHAR(20) NOT NULL DEFAULT 'staff', -- 'admin', 'staff'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: categories
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL
);

-- Table 3: menu_items
CREATE TABLE IF NOT EXISTS menu_items (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: customers
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 5: orders
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(100) PRIMARY KEY, -- Unique ID (can be client UUID)
    customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    order_type VARCHAR(50) NOT NULL DEFAULT 'Dine In', -- 'Dine In', 'Take Away'
    subtotal DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0.00,
    total DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'ready', 'completed', 'cancelled'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 6: order_items
CREATE TABLE IF NOT EXISTS order_items (
    id VARCHAR(100) PRIMARY KEY, -- Unique ID (can be client UUID)
    order_id VARCHAR(100) REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id INTEGER REFERENCES menu_items(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    extras JSONB DEFAULT '[]', -- JSON array: [{"name": "Extra Cheese", "price": 20}]
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 7: sales_reports
CREATE TABLE IF NOT EXISTS sales_reports (
    id SERIAL PRIMARY KEY,
    report_date DATE UNIQUE NOT NULL,
    total_orders INTEGER NOT NULL DEFAULT 0,
    total_revenue DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    top_selling_item VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_customers_mobile ON customers(mobile);

-- Seed Initial User
-- Default PIN: 1234
-- Hashed using bcrypt ($2a$10$r94f.n/Zc.Z7t1H8K/H1F.rZl/1f3.p2v9Gg5ZtXv7B6g4V5z.K9G)
INSERT INTO users (username, pin_hash, role)
VALUES ('admin', '$2a$10$r94f.n/Zc.Z7t1H8K/H1F.rZl/1f3.p2v9Gg5ZtXv7B6g4V5z.K9G', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Seed Categories
INSERT INTO categories (id, name, slug) VALUES
(1, 'Shawarma', 'shawarma'),
(2, 'Lays Shawarma', 'lays-shawarma'),
(3, 'Plate Shawarma', 'plate-shawarma'),
(4, 'Mug Shawarma', 'mug-shawarma'),
(5, 'Special Shawarma', 'special-shawarma')
ON CONFLICT (id) DO NOTHING;

-- Seed Menu Items
INSERT INTO menu_items (category_id, name, price, description) VALUES
-- Shawarma (Category 1)
(1, 'Classic Shawarma', 120.00, 'Original slow-roasted chicken shawarma with garlic mayonnaise wrapped in pita bread.'),
(1, 'Spicy Shawarma', 130.00, 'Tender chicken shawarma loaded with red hot chilli and pickled jalapenos.'),
(1, 'Tandoori Shawarma', 140.00, 'Charred tandoori-spiced chicken wrapped with mint yoghurt sauce.'),
(1, 'Mexican Shawarma', 140.00, 'Fajita seasoned chicken shawarma with bell peppers and tangy salsa.'),

-- Lays Shawarma (Category 2)
(2, 'Lays Classic Shawarma', 130.00, 'Crispy Classic Lays potato chips combined with juicy chicken shawarma wrapper.'),
(2, 'Lays Spanish Shawarma', 140.00, 'Sweet and spicy Spanish Tomato Lays layered inside your favourite shawarma.'),
(2, 'Lays Cream & Onion Shawarma', 140.00, 'Cool American Style Cream & Onion Lays paired with shredded garlic chicken.'),
(2, 'Lays Chili Limón Shawarma', 140.00, 'Zesty Chili Limón Lays crunch added to chicken shawarma.'),
(2, 'Lays BBQ Shawarma', 140.00, 'Smoky sweet Lays BBQ crunch combined with garlic chicken.'),

-- Plate Shawarma (Category 3)
(3, 'Plate Classic Shawarma', 160.00, 'Deconstructed chicken shawarma served on a plate with pita bread, pickle, and dips.'),
(3, 'Plate Special Shawarma', 180.00, 'Plate shawarma served with loaded fries, extra pickled veggies, and signature sauce.'),
(3, 'Plate Cheese Blast Shawarma', 200.00, 'Plate shawarma topped with melted mozzarella and Cheddar cheese sauce.'),

-- Mug Shawarma (Category 4)
(4, 'Mug Classic Shawarma', 150.00, 'Unique layers of chicken shawarma, fries, and sauce served hot in a mug.'),
(4, 'Mug Spicy Shawarma', 160.00, 'Layered spicy chicken shawarma in a mug with peri-peri drizzle.'),
(4, 'Mug Peri Peri Shawarma', 160.00, 'Fiery peri-peri chicken and seasoned fries layered inside a mug.'),
(4, 'Mug BBQ Shawarma', 160.00, 'Barbecue chicken shawarma layered with cheese in a signature mug.'),
(4, 'Mug Schezwan Shawarma', 160.00, 'Spicy schezwan chicken, noodles/fries, and cabbage layer served in a mug.'),
(4, 'Mug Mexican Shawarma', 160.00, 'Salsa, Mexican seasoned chicken, and nachos crumbles served layered in a mug.'),

-- Special Shawarma (Category 5)
(5, 'Booto Special Shawarma', 190.00, 'Chef''s secret spice marinated double chicken shawarma loaded with double cheese.'),
(5, 'Monster Shawarma', 220.00, 'Giant loaded shawarma with triple chicken, fries, cabbage, and three signature sauces.'),
(5, 'Cheese Loader Shawarma', 210.00, 'For cheese lovers: double mozzarella cheese inside and melted cheese poured on top.')
ON CONFLICT (name) DO NOTHING;
