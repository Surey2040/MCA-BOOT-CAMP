# BooTo Shawarma POS System

A complete real-time Android Point of Sale (POS) application and backed server for **BooTo Shawarma**, styled with a dark theme, gold accents, and live synchronization.

---

## Technical Architecture

The codebase is split into two major components:

1. **`backend/`**: A Node.js Express server configured with PostgreSQL, Prisma ORM, and WebSockets (`ws`) for real-time broadcasts.
2. **`android/`**: A native Android POS application built using Kotlin, Jetpack Compose, Dagger Hilt, Room Database, Retrofit (for REST endpoints), and MPAndroidChart for the sales performance analytics.

```
booo/
├── backend/
│   ├── prisma/
│   │   └── schema.prisma         # Database models (Customer, MenuItem, Order, OrderItem)
│   ├── routes/
│   │   ├── menu.js               # Fetches menu items
│   │   ├── orders.js             # Place orders (auto-generates ORD1001...) & update status
│   │   └── reports.js            # Aggregates charts & dashboard statistics
│   ├── .env                      # Database URL configuration
│   ├── server.js                 # Entrypoint containing WebSocket server & pre-seeding
│   └── package.json
└── android/
    ├── build.gradle
    ├── settings.gradle
    └── app/
        ├── build.gradle          # Room, Hilt, OkHttp, Retrofit, MPAndroidChart
        └── src/main/
            ├── AndroidManifest.xml
            └── java/com/booto/shawarma/
                ├── MainActivity.kt        # App bootstrap, custom BottomAppBar navigation
                ├── BooToApplication.kt    # Annotate @HiltAndroidApp
                ├── data/
                │   ├── Entities.kt        # Room entities (Customer, MenuItem, Extra, Order, OrderItem, Admin)
                │   ├── AppDao.kt          # Local Room Database access objects
                │   ├── AppDatabase.kt     # Room database builder & pre-seeding callback
                │   └── Network.kt         # Retrofit interface definitions & requests
                ├── di/
                │   ├── DatabaseModule.kt  # Hilt database bindings
                │   └── NetworkModule.kt   # Hilt OkHttp/Retrofit bindings
                ├── repository/
                │   └── POSRepository.kt   # Local/Remote database sync repository
                ├── ui/
                │   ├── screens/
                │   │   ├── SplashScreen.kt    # Custom Canvas drawn Shawarma & loading animation
                │   │   ├── LoginScreen.kt     # Secure passcode login card
                │   │   ├── DashboardScreen.kt # Stat grid & MPAndroidChart Line Chart integration
                │   │   ├── NewOrderScreen.kt  # Customizer form, extras checker, dynamic cart checkout
                │   │   ├── OrdersScreen.kt    # Tabbed pending/ready order board + bottom detail sheet
                │   │   ├── SalesScreen.kt     # Order transaction logs & total revenue aggregate
                │   │   └── MenuScreen.kt      # Interactive menu catalog
                │   └── theme/
                │       └── Theme.kt           # Color definitions (#0D0D0D, #1A1A1A, #F5A623)
                └── viewmodel/
                    ├── ViewModels.kt      # ViewModels for Dashboard, NewOrder, Orders, Sales, Menu
                    └── LoginViewModel.kt  # ViewModel for PIN code entry & remember-me options
```

---

## Design System

The application strictly enforces a high-fidelity modern UI:
- **Background**: `#0D0D0D` (Pure obsidian black)
- **Cards/Surfaces**: `#1A1A1A` (Elegant charcoal)
- **Accent Theme**: `#F5A623` (Royal Gold)
- **Status Indicators**:
  - Ready: `#4CAF50` (Vibrant green badge)
  - Cancelled: `#E53935` (Crimson red badge)
- **Components**: High-contrast golden outline borders on selected variants, custom virtual PIN cards, glowing canvas vectors, and fluid responsive buttons.

---

## Database Schemas

### 1. PostgreSQL Schema (Prisma)
- **Customer**: `id`, `name`, `mobile` (unique).
- **MenuItem**: `id`, `category`, `name` (unique), `price`, `imageUrl`.
- **Order**: `id` (e.g. `ORD1001`), `customerId`, `type`, `status` (`pending`, `ready`, `completed`, `cancelled`), `total`, `note`.
- **OrderItem**: `id`, `orderId`, `menuItemId`, `itemName`, `quantity`, `price`, `extras` (JSON list).

### 2. Local Database Schema (Room Android)
- Replicates the core transaction tables on the device using native SQLite for complete offline resilience.
- **Admin**: Contains passcode records (`id`, `name`, `pin`). Seeds a default administrator:
  - **Name**: `Admin`
  - **PIN**: `1234`

---

## Running the Application

### 1. Starting the Backend
Prerequisites: PostgreSQL database must be running.

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Setup database connection in `.env`:
   ```env
   DATABASE_URL="postgresql://user:password@localhost:5432/booto_pos?schema=public"
   PORT=5001
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Perform database migrations and client generation:
   ```bash
   npx prisma migrate dev --name init
   npx prisma generate
   ```
5. Launch the backend server:
   ```bash
   npm start
   ```
   *(On first boot, the server automatically populates categories and standard serving items to the database).*

### 2. Compiling the Android App
1. Open the `android/` directory in Android Studio.
2. The network connection maps automatically to `http://10.0.2.2:5001/api/` (matching the Android emulator loopback).
3. Build the Gradle project and launch it on your emulator or connected device.
4. Unlock the terminal using the default PIN code `1234`.
