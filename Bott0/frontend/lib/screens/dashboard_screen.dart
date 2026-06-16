import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../theme.dart';
import '../services/sync_service.dart';
import '../services/db_helper.dart';
import '../models/customer.dart';
import '../providers/dashboard_provider.dart';

// Import sub screens to bind tabs
import 'order_flow_screen.dart';
import 'order_management_screen.dart';
import 'admin_dashboard_screen.dart';
import 'menu_management_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 2; // Default to New Order tab
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    // Load initial SQLite state and execute startup sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrdersLocal();
      Provider.of<MenuProvider>(context, listen: false).loadMenuLocal();
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final status = await SyncService.isServerOnline();
    if (mounted) {
      setState(() {
        _isOnline = status;
      });
    }
  }

  // Define tab navigation screens
  List<Widget> _getScreens() {
    return [
      DashboardView(onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      OrderManagementScreen(onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      OrderFlowScreen(onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const MenuManagementScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  Text(
                    _currentIndex == 1
                        ? 'POS ORDERS'
                        : _currentIndex == 2
                            ? 'NEW POS ORDER'
                            : _currentIndex == 3
                                ? 'MENU MANAGEMENT'
                                : 'SYSTEM SETTINGS',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
              actions: [
                // Offline/Online Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Chip(
                    avatar: Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: _isOnline ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    label: Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(color: _isOnline ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                // Logout icon
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: const Border(
            top: BorderSide(color: Color(0xFF222222), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _checkConnectivity();
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGold,
          unselectedItemColor: AppTheme.textMuted,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard, color: AppTheme.primaryGold),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${orderProv.pendingOrdersCount}'),
                isLabelVisible: orderProv.pendingOrdersCount > 0,
                backgroundColor: AppTheme.statusPending,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: const Icon(Icons.receipt_long, color: AppTheme.primaryGold),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle, color: AppTheme.primaryGold),
              label: 'New Order',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics, color: AppTheme.primaryGold),
              label: 'Reports',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings, color: AppTheme.primaryGold),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// Inner view for Dashboard Home Screen
class DashboardView extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardView({super.key, required this.onNavigateTab});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isSyncing = false;

  // Seeding backup trigger
  Future<void> _runBackup(BuildContext context) async {
    final isOnline = await SyncService.isServerOnline();
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server offline. Cannot backup to cloud database.')),
        );
      }
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final baseUrl = await SyncService.getBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/settings/backup'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Backup Created'),
            content: const Text('Cloud backup has been compiled successfully on the server filesystem (backend/backups/).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showCustomerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Customer>>(
              future: DbHelper.instance.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }
                final list = snapshot.data ?? [];
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CUSTOMER RELATION DATABASE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryGold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: list.isEmpty
                            ? const Center(
                                child: Text('No customers registered.'),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                                itemBuilder: (context, idx) {
                                  final cust = list[idx];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppTheme.surfaceLight,
                                      child: Icon(Icons.person, color: AppTheme.primaryGold),
                                    ),
                                    title: Text(
                                      cust.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      cust.mobile ?? 'No phone number',
                                      style: const TextStyle(color: AppTheme.textMuted),
                                    ),
                                    trailing: const Icon(Icons.history, color: AppTheme.accentOrange),
                                    onTap: () async {
                                      final orders = await DbHelper.instance.getOrders();
                                      final custOrders = orders.where((o) => o.customerMobile == cust.mobile).toList();
                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('${cust.name} - History'),
                                            content: custOrders.isEmpty
                                                ? const SizedBox(
                                                    height: 100,
                                                    child: Center(child: Text('No purchase records found.')),
                                                  )
                                                : SizedBox(
                                                    width: double.maxFinite,
                                                    height: 300,
                                                    child: ListView.builder(
                                                      itemCount: custOrders.length,
                                                      itemBuilder: (context, index) {
                                                        final ord = custOrders[index];
                                                        return ListTile(
                                                          title: Text(ord.orderNumber ?? 'Invoice'),
                                                          subtitle: Text(DateFormat('dd MMM yyyy').format(ord.createdAt)),
                                                          trailing: Text(
                                                            '₹${ord.total.toStringAsFixed(0)}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.primaryGold,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('CLOSE'),
                                              )
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final dashProv = Provider.of<DashboardProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final currentDateStr = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await orderProv.refreshOrders();
        await dashProv.fetchDashboardData();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP HEADER SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: AppTheme.accentOrange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BOOTO SHAWARMA',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 18,
                                  letterSpacing: 2.0,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome Admin 👨‍🍳',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentDateStr,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: AppTheme.primaryGold, size: 28),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No new notifications today.')),
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.accentOrange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Loading indicator
              if (dashProv.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      color: AppTheme.primaryGold,
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  ),
                ),

              // 2. SUMMARY CARDS (2x2 Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _buildSummaryCard(
                    title: "Today's Sales",
                    value: currencyFormat.format(dashProv.revenue),
                    icon: '💰',
                    subtitle: 'Total Revenue',
                  ),
                  _buildSummaryCard(
                    title: 'Total Orders',
                    value: '${dashProv.totalOrders}',
                    icon: '📦',
                    subtitle: 'Orders Volume',
                  ),
                  _buildSummaryCard(
                    title: 'Pending Orders',
                    value: '${dashProv.pendingOrdersCount}',
                    icon: '⏳',
                    subtitle: 'In Preparation',
                  ),
                  _buildSummaryCard(
                    title: 'Ready Orders',
                    value: '${dashProv.readyOrdersCount}',
                    icon: '✅',
                    subtitle: 'Ready to Serve',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. QUICK ACTIONS GRID
              const Text(
                'QUICK SYSTEM ACTIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  QuickActionButton(
                    label: 'New Order',
                    icon: Icons.add_shopping_cart,
                    color: AppTheme.accentOrange,
                    onTap: () => widget.onNavigateTab(2),
                  ),
                  QuickActionButton(
                    label: 'Orders',
                    icon: Icons.receipt_long,
                    color: Colors.deepPurpleAccent,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                  QuickActionButton(
                    label: 'Menu Editor',
                    icon: Icons.restaurant_menu,
                    color: AppTheme.primaryGold,
                    onTap: () => widget.onNavigateTab(3),
                  ),
                  QuickActionButton(
                    label: 'Sales Report',
                    icon: Icons.analytics,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                  ),
                  QuickActionButton(
                    label: 'Customers',
                    icon: Icons.people_alt_outlined,
                    color: Colors.blueAccent,
                    onTap: () => _showCustomerSheet(context),
                  ),
                  QuickActionButton(
                    label: _isSyncing ? 'Backing up...' : 'Backup DB',
                    icon: _isSyncing ? Icons.sync : Icons.cloud_upload_outlined,
                    color: Colors.amber,
                    onTap: _isSyncing ? () {} : () => _runBackup(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. TOP SELLING ITEMS SECTION
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🥇 TOP SELLING ITEMS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                        Text(
                          'Today',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 20),
                    dashProv.topItems.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No top items logged today.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: () {
                              int maxQty = 1;
                              if (dashProv.topItems.isNotEmpty) {
                                maxQty = (dashProv.topItems.first['quantity_sold'] as num?)?.toInt() ?? 1;
                                if (maxQty <= 0) maxQty = 1;
                              }
                              return List.generate(dashProv.topItems.length, (idx) {
                                final item = dashProv.topItems[idx];
                                final name = item['item_name'] ?? 'Unknown Item';
                                final qty = (item['quantity_sold'] as num?)?.toInt() ?? 0;
                                String medal = '🏅';
                                if (idx == 0) medal = '🥇';
                                if (idx == 1) medal = '🥈';
                                if (idx == 2) medal = '🥉';

                                return TopSellingItemRow(
                                  medal: medal,
                                  name: name,
                                  count: qty,
                                  maxCount: maxQty,
                                );
                              });
                            }(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. CATEGORY SALES SECTION
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '🌯 CATEGORY SALES REVENUE',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                    ),
                    const Divider(color: Colors.grey, height: 20),
                    dashProv.categorySales.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No category sales logged today.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: dashProv.categorySales.map((cat) {
                              final name = cat['category_name'] ?? 'General';
                              final revenue = (cat['revenue'] as num?)?.toDouble() ?? 0.0;

                              String emoji = '🍽';
                              final lowerName = name.toString().toLowerCase();
                              if (lowerName.contains('lays')) {
                                emoji = '🥔';
                              } else if (lowerName.contains('plate')) {
                                emoji = '🍽';
                              } else if (lowerName.contains('mug')) {
                                emoji = '☕';
                              } else if (lowerName.contains('special')) {
                                emoji = '🔥';
                              } else if (lowerName.contains('shawarma')) {
                                emoji = '🌯';
                              }

                              return CategorySalesRow(
                                icon: emoji,
                                name: name,
                                revenue: revenue,
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. PAYMENT SUMMARY CARD
              PaymentSummaryCard(
                cash: dashProv.cashSales,
                upi: dashProv.upiSales,
                card: dashProv.cardSales,
              ),
              const SizedBox(height: 24),

              // 7. RECENT ORDERS SECTION
              const Text(
                '📋 RECENT INCOMING ORDERS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              dashProv.recentOrders.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Card(
                        color: AppTheme.surface,
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No recent orders found.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: dashProv.recentOrders.map((order) {
                        final timeStr = DateFormat('hh:mm a').format(order.createdAt);

                        String itemsDesc = 'POS Order Items';
                        if (order.items.isNotEmpty) {
                          itemsDesc = order.items
                              .map((item) => '${item.quantity}x ${item.itemName}')
                              .join(', ');
                        }

                        String uiStatus = 'pending';
                        if (order.status == 'ready' || order.status == 'completed') {
                          uiStatus = 'ready';
                        } else if (order.status == 'preparing' || order.status == 'cooking') {
                          uiStatus = 'preparing';
                        }

                        return RecentOrderCard(
                          orderNumber: order.orderNumber ?? '#B-${order.id.substring(0, 4).toUpperCase()}',
                          customerName: order.customerName ?? 'Walk-in Customer',
                          items: itemsDesc,
                          time: timeStr,
                          status: uiStatus,
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String icon,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryGold.withOpacity(0.3), width: 1.5),
      ),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF252115), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TopSellingItemRow extends StatelessWidget {
  final String medal;
  final String name;
  final int count;
  final int maxCount;

  const TopSellingItemRow({
    super.key,
    required this.medal,
    required this.name,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxCount > 0 ? (count / maxCount) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
            ),
            child: Text(
              '$count sold',
              style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class CategorySalesRow extends StatelessWidget {
  final String icon;
  final String name;
  final double revenue;

  const CategorySalesRow({
    super.key,
    required this.icon,
    required this.name,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
          Text(
            currencyFormat.format(revenue),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGold),
          ),
        ],
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final double cash;
  final double upi;
  final double card;

  const PaymentSummaryCard({
    super.key,
    required this.cash,
    required this.upi,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final total = cash + upi + card;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryGold.withOpacity(0.4), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2512), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PAYMENT SUMMARY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGold, letterSpacing: 0.5),
                ),
                Text(
                  'TOTAL: ${currencyFormat.format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 24),
            _buildPaymentRow('💵 Cash Collection', cash, total, Colors.green),
            const SizedBox(height: 12),
            _buildPaymentRow('📱 UPI Collection', upi, total, AppTheme.accentOrange),
            const SizedBox(height: 12),
            _buildPaymentRow('💳 Card Collection', card, total, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, double total, Color barColor) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pct = total > 0 ? (amount / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
            Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class RecentOrderCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final String items;
  final String time;
  final String status;

  const RecentOrderCard({
    super.key,
    required this.orderNumber,
    required this.customerName,
    required this.items,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (status.toLowerCase()) {
      case 'preparing':
        statusColor = AppTheme.statusPending;
        statusText = 'Preparing';
        break;
      case 'ready':
      case 'completed':
        statusColor = AppTheme.statusReady;
        statusText = 'Ready';
        break;
      case 'pending':
      default:
        statusColor = AppTheme.accentOrange;
        statusText = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              items,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
