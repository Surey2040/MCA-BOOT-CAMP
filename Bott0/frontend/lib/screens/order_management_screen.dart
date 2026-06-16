import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../models/order.dart';

class OrderManagementScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const OrderManagementScreen({super.key, this.onNavigateTab});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Search & Filter State
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  
  String _selectedOrderType = 'All'; // 'All', 'Dine In', 'Take Away'
  String _selectedDateFilter = 'All'; // 'All', 'Today', 'Yesterday'
  String _filterCustomerName = '';
  String _filterMobile = '';

  // Mock Shawarma Image mapping for rich visuals
  String _getItemImage(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('classic')) {
      return 'https://images.unsplash.com/photo-1642683263229-bc84d62f0269?w=300&q=80';
    } else if (name.contains('spicy') || name.contains('tandoori') || name.contains('chili')) {
      return 'https://images.unsplash.com/photo-1561651823-34fed022540e?w=300&q=80';
    } else if (name.contains('lays') || name.contains('roll') || name.contains('spanish') || name.contains('onion')) {
      return 'https://images.unsplash.com/photo-1613904985222-0d534430bdbd?w=300&q=80';
    } else if (name.contains('plate')) {
      return 'assets/images/plate_shawarma.jpg';
    } else if (name.contains('mug')) {
      return 'https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?w=300&q=80';
    } else if (name.contains('special') || name.contains('monster') || name.contains('cheese')) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300&q=80';
    }
    return 'https://images.unsplash.com/photo-1642683263229-bc84d62f0269?w=300&q=80'; // general shawarma
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter logic helper
  List<Order> _getFilteredOrders(List<Order> orderList) {
    return orderList.where((o) {
      // 1. Search Bar Query (Order number, customer name, mobile)
      if (_searchQuery.isNotEmpty) {
        final numMatch = o.orderNumber != null && o.orderNumber!.toLowerCase().contains(_searchQuery);
        final nameMatch = o.customerName != null && o.customerName!.toLowerCase().contains(_searchQuery);
        final mobMatch = o.customerMobile != null && o.customerMobile!.contains(_searchQuery);
        if (!numMatch && !nameMatch && !mobMatch) return false;
      }
      
      // 2. Order Type Filter
      if (_selectedOrderType != 'All' && o.orderType != _selectedOrderType) {
        return false;
      }
      
      // 3. Date Filter
      if (_selectedDateFilter != 'All') {
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final orderDateStr = o.createdAt.toIso8601String().substring(0, 10);
        if (_selectedDateFilter == 'Today' && orderDateStr != todayStr) {
          return false;
        }
        if (_selectedDateFilter == 'Yesterday') {
          final yestStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
          if (orderDateStr != yestStr) return false;
        }
      }
      
      // 4. Customer Name Filter
      if (_filterCustomerName.isNotEmpty && 
          !(o.customerName != null && o.customerName!.toLowerCase().contains(_filterCustomerName.toLowerCase()))) {
        return false;
      }
      
      // 5. Mobile Filter
      if (_filterMobile.isNotEmpty && 
          !(o.customerMobile != null && o.customerMobile!.contains(_filterMobile))) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Check if an order is priority: large, VIP, or delayed
  bool _isPriorityOrder(Order order) {
    if (order.total >= 500) return true; // Large order
    if (order.customerName?.toLowerCase().contains('vip') ?? false) return true; // VIP
    // Delayed pending order (> 15 minutes)
    if (order.status == 'pending' && 
        DateTime.now().difference(order.createdAt).inMinutes >= 15) {
      return true;
    }
    return false;
  }

  // Get matching badge string for priority
  String _getPriorityBadgeText(Order order) {
    if (order.customerName?.toLowerCase().contains('vip') ?? false) return '👑 VIP CUSTOMER';
    if (order.status == 'pending' && 
        DateTime.now().difference(order.createdAt).inMinutes >= 15) {
      return '⚠️ DELAYED PENDING';
    }
    if (order.total >= 500) return '🔥 LARGE ORDER';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Apply filtering on categorized orders
    final pendingFiltered = _getFilteredOrders(orderProv.pendingOrders);
    final preparingFiltered = _getFilteredOrders(orderProv.preparingOrders);
    final readyFiltered = _getFilteredOrders(orderProv.readyOrders);
    final cancelledFiltered = _getFilteredOrders(orderProv.cancelledOrders);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Real Premium Dark Background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP BRAND HEADER
            _buildBrandHeader(),

            // 2. SEARCH BAR DRAWER (Expands / Collapses)
            _buildExpandableSearchBar(),

            // 3. QUICK ACTIONS BAR
            _buildQuickActionsRow(context, orderProv),

            // 4. GLASSMORPHIC TAB NAVIGATION
            _buildTabSelector(
              pendingCount: pendingFiltered.length,
              preparingCount: preparingFiltered.length,
              readyCount: readyFiltered.length,
              cancelledCount: cancelledFiltered.length,
            ),

            // 5. LIST OF INCOMING ORDERS
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(pendingFiltered, currencyFormat, 'pending'),
                  _buildOrderList(preparingFiltered, currencyFormat, 'preparing'),
                  _buildOrderList(readyFiltered, currencyFormat, 'ready'),
                  _buildOrderList(cancelledFiltered, currencyFormat, 'cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOTO SHAWARMA',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                  ),
                  Text(
                    'Order Desk Management',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Search Toggle
              IconButton(
                icon: Icon(
                  _isSearchExpanded ? Icons.search_off : Icons.search,
                  color: _isSearchExpanded ? AppTheme.accentOrange : AppTheme.primaryGold,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (!_isSearchExpanded) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              // Filter Toggle
              IconButton(
                icon: const Icon(Icons.tune, color: AppTheme.primaryGold),
                onPressed: () => _showFilterBottomSheet(context),
              ),
              // Notification Badge Icon
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryGold),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('POS Alert: All orders are synchronized locally.'),
                          backgroundColor: Color(0xFF1E1E1E),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _isSearchExpanded ? 72 : 0,
      curve: Curves.easeInOut,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          color: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search Invoice ID, Mobile, or Name...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, OrderProvider orderProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F0F0F),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // New Order Button
            _buildActionChip(
              icon: Icons.add,
              label: 'NEW ORDER',
              color: AppTheme.accentOrange,
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Navigate to tab 2 (New Order Flow)
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use Bottom Nav bar to start a New Order')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            // Sync / Refresh
            _buildActionChip(
              icon: Icons.sync,
              label: 'REFRESH',
              color: AppTheme.primaryGold,
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                        ),
                        SizedBox(width: 12),
                        Text('Syncing with Booto Cloud Server...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
                await orderProv.refreshOrders();
              },
            ),
            const SizedBox(width: 8),
            // Export Orders
            _buildActionChip(
              icon: Icons.cloud_download_outlined,
              label: 'EXPORT',
              color: Colors.blueAccent,
              onTap: () => _simulateExportDialog(context, orderProv),
            ),
            const SizedBox(width: 8),
            // Print Reports
            _buildActionChip(
              icon: Icons.assessment_outlined,
              label: 'REPORTS',
              color: Colors.teal,
              onTap: () => _simulateReportsDialog(context, orderProv),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector({
    required int pendingCount,
    required int preparingCount,
    required int readyCount,
    required int cancelledCount,
  }) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryGold,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primaryGold,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: [
          Tab(
            child: _buildTabItem('⏳ Pending', pendingCount, AppTheme.statusPending),
          ),
          Tab(
            child: _buildTabItem('👨‍🍳 Preparing', preparingCount, AppTheme.accentOrange),
          ),
          Tab(
            child: _buildTabItem('✅ Ready', readyCount, AppTheme.statusReady),
          ),
          Tab(
            child: _buildTabItem('❌ Cancelled', cancelledCount, AppTheme.statusCancelled),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int count, Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(List<Order> orderList, NumberFormat format, String statusTab) {
    if (orderList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusTab == 'pending'
                  ? Icons.hourglass_empty
                  : statusTab == 'preparing'
                      ? Icons.restaurant
                      : statusTab == 'ready'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
              size: 52,
              color: AppTheme.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No ${statusTab.toUpperCase()} Orders Found',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try clearing search filters or wait for new orders.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderList.length,
      itemBuilder: (context, idx) {
        final order = orderList[idx];
        return _buildOrderCard(context, order, format);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, NumberFormat format) {
    final hasPriority = _isPriorityOrder(order);
    final priorityText = _getPriorityBadgeText(order);
    
    // Status border and glow colors
    Color statusAccent = AppTheme.statusPending;
    if (order.status == 'preparing') statusAccent = AppTheme.accentOrange;
    if (order.status == 'ready') statusAccent = AppTheme.statusReady;
    if (order.status == 'cancelled') statusAccent = AppTheme.statusCancelled;

    // Outer card glow effect
    final borderGlowColor = hasPriority 
        ? const Color(0xFFFF1744) 
        : statusAccent.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616), // Dark Glassmorphic Card surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPriority 
              ? const Color(0xFFFF1744).withOpacity(0.7) 
              : statusAccent.withOpacity(0.25), 
          width: hasPriority ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderGlowColor.withOpacity(0.12),
            blurRadius: hasPriority ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOrderDetailsBottomSheet(context, order, format),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD UPPER ROW: ID, Badge, Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.orderNumber ?? '#ORD-${order.id.substring(0, 4).toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Synced Status indicator
                          if (!order.synced)
                            const Tooltip(
                              message: 'Unsynced Local Order',
                              child: Icon(Icons.cloud_upload, color: AppTheme.statusPending, size: 16),
                            ),
                        ],
                      ),
                      Text(
                        DateFormat('hh:mm a').format(order.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // HIGH PRIORITY BADGE IF REQUIRED
                  if (hasPriority && priorityText.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on, color: Color(0xFFFF1744), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            priorityText,
                            style: const TextStyle(
                              color: Color(0xFFFF1744),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // CUSTOMER DATA ROW
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 14,
                        child: Icon(
                          order.orderType == 'Dine In' ? Icons.restaurant : Icons.takeout_dining,
                          size: 14,
                          color: statusAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.customerName ?? 'Walk-In Customer'} (${order.customerMobile ?? 'No Mobile'})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Order Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.8),
                        ),
                        child: Text(
                          order.orderType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF282828), height: 20),

                  // CORE ORDERED ITEMS GRID + IMAGE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Unsplash Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: (() {
                            final imgUrl = _getItemImage(order.items.isNotEmpty ? (order.items.first.itemName ?? '') : '');
                            return imgUrl.startsWith('http')
                                ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.black,
                                      child: const Icon(Icons.restaurant_menu, color: AppTheme.primaryGold, size: 24),
                                    ),
                                  )
                                : Image.asset(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.black,
                                      child: const Icon(Icons.restaurant_menu, color: AppTheme.primaryGold, size: 24),
                                    ),
                                  );
                          })(),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bullet items List
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppTheme.primaryGold, fontSize: 13)),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: '${item.itemName ?? "Shawarma item"} ',
                                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: 'x${item.quantity}',
                                            style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Total Amount aligned to the bottom right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            format.format(order.total),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: statusAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CARD LOWER ACTION BUTTONS BASED ON STATE
                  _buildCardAction(context, order),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction(BuildContext context, Order order) {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    switch (order.status) {
      case 'pending':
        return ElevatedButton.icon(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Starting Preparation for Order ${order.orderNumber ?? order.id.substring(0, 4)}')),
            );
            await orderProv.updateStatus(order.id, 'preparing');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('START PREPARING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
        );
      case 'preparing':
        return ElevatedButton.icon(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order ${order.orderNumber ?? order.id.substring(0, 4)} Marked Ready!')),
            );
            await orderProv.updateStatus(order.id, 'ready');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('MARK READY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
        );
      case 'ready':
        return Row(
          children: [
            // Print Receipt
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => _simulatePrintBill(context, order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('PRINT BILL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(width: 10),
            // Complete Order
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Completing Order ${order.orderNumber ?? order.id.substring(0, 4)}!')),
                  );
                  await orderProv.updateStatus(order.id, 'completed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('COMPLETE ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              ),
            ),
          ],
        );
      case 'cancelled':
        return OutlinedButton.icon(
          onPressed: () => _showOrderDetailsBottomSheet(context, order, NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
            side: const BorderSide(color: Color(0xFF333333), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('VIEW DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // --- FILTER MODAL BOTTOM SHEET ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
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
                        'FILTER POS ORDERS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Order Type Option Filter
                      const Text('ORDER TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['All', 'Dine In', 'Take Away'].map((type) {
                          final isSelected = _selectedOrderType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryGold,
                              backgroundColor: const Color(0xFF1E1E1E),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setStateSheet(() {
                                    _selectedOrderType = type;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Date Filters
                      const Text('DATE RECEIVED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['All', 'Today', 'Yesterday'].map((date) {
                          final isSelected = _selectedDateFilter == date;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(date),
                              selected: isSelected,
                              selectedColor: AppTheme.accentOrange,
                              backgroundColor: const Color(0xFF1E1E1E),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setStateSheet(() {
                                    _selectedDateFilter = date;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Customer Filter Text Field
                      const Text('CUSTOMER NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter customer name...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        controller: TextEditingController(text: _filterCustomerName),
                        onChanged: (val) => _filterCustomerName = val.trim(),
                      ),
                      const SizedBox(height: 20),

                      // Customer Mobile Filter Field
                      const Text('MOBILE NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter mobile number...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        controller: TextEditingController(text: _filterMobile),
                        onChanged: (val) => _filterMobile = val.trim(),
                      ),
                      const SizedBox(height: 28),

                      // Apply and Reset Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setStateSheet(() {
                                  _selectedOrderType = 'All';
                                  _selectedDateFilter = 'All';
                                  _filterCustomerName = '';
                                  _filterMobile = '';
                                });
                                setState(() {});
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text('RESET ALL', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {}); // Refresh main screen with sheet selections
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                              ),
                              child: const Text('APPLY FILTERS', style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ],
                      )
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

  // --- FULL RECEIPT PRINT PREVIEW MODAL ---
  void _simulatePrintBill(BuildContext context, Order order) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.print, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('Thermal Printer Draft', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    '*** BOOTO SHAWARMA ***',
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  ),
                ),
                const Center(
                  child: Text(
                    'PH: 9876543210 | GSTIN: 33AAAAA1111A1Z1',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black),
                  ),
                ),
                const Center(
                  child: Text(
                    'Kitchen POS Receipt',
                    style: TextStyle(fontFamily: 'monospace', fontStyle: FontStyle.italic, fontSize: 10, color: Colors.black),
                  ),
                ),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                Text('Order ID : ${order.orderNumber ?? order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                Text('Cashier  : Booto Admin', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                Text('Type     : ${order.orderType}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                Text('Date     : ${DateFormat('dd-MMM-yyyy hh:mm a').format(order.createdAt)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                Text('Customer : ${order.customerName ?? "Walk-In"}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black))),
                    Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black), textAlign: TextAlign.center)),
                    Expanded(flex: 1, child: Text('Amt', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black), textAlign: TextAlign.right)),
                  ],
                ),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName ?? 'Item', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                            if (item.extras.isNotEmpty)
                              Text('+ ${item.extras.map((e) => e.name).join(", ")}', style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text(format.format(item.total), style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                    Text(format.format(order.subtotal), style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax (5%):', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                    Text(format.format(order.total - order.subtotal + order.discount), style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                    Text('-${format.format(order.discount)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
                  ],
                ),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                    Text(format.format(order.total), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                  ],
                ),
                const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                const Center(
                  child: Text(
                    'Thank You! Visit Again.',
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bill Receipt Printed Successfully on POS Thermal Printer!'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('PRINT DRAFT', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE DETAILS BOTTOM SHEET ---
  void _showOrderDetailsBottomSheet(BuildContext context, Order order, NumberFormat format) {
    // Local selectable payment method simulation
    String selectedPaymentMethod = 'UPI'; // Default mock indicator

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // Status based values
            int timelineIndex = 0;
            if (order.status == 'preparing') timelineIndex = 1;
            if (order.status == 'ready') timelineIndex = 2;
            if (order.status == 'completed') timelineIndex = 3;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top indicator bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Invoice ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.orderNumber ?? '#ORD-${order.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryGold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: order.status == 'pending'
                                  ? AppTheme.statusPending.withOpacity(0.15)
                                  : order.status == 'preparing'
                                      ? AppTheme.accentOrange.withOpacity(0.15)
                                      : order.status == 'ready'
                                          ? AppTheme.statusReady.withOpacity(0.15)
                                          : AppTheme.statusCancelled.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: order.status == 'pending'
                                    ? AppTheme.statusPending
                                    : order.status == 'preparing'
                                        ? AppTheme.accentOrange
                                        : order.status == 'ready'
                                            ? AppTheme.statusReady
                                            : AppTheme.statusCancelled,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: order.status == 'pending'
                                    ? AppTheme.statusPending
                                    : order.status == 'preparing'
                                        ? AppTheme.accentOrange
                                        : order.status == 'ready'
                                            ? AppTheme.statusReady
                                            : AppTheme.statusCancelled,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF2E2E2E), height: 30),

                      // Customer Metadata Card
                      _buildDetailSectionTitle('CUSTOMER & ORDER INFO'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoDetailRow(Icons.person, 'Customer Name', order.customerName ?? 'Walk-In Customer'),
                            const SizedBox(height: 10),
                            _buildInfoDetailRow(Icons.phone_android, 'Mobile Number', order.customerMobile ?? 'No number provided'),
                            const SizedBox(height: 10),
                            _buildInfoDetailRow(Icons.restaurant, 'Order Dining Type', order.orderType),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ordered Items List
                      _buildDetailSectionTitle('ORDERED FOOD ITEMS'),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, idx) {
                          final item = order.items[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.02)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _getItemImage(item.itemName ?? ''),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.black,
                                      child: const Icon(Icons.fastfood, color: AppTheme.primaryGold, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName ?? 'Menu item',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                      ),
                                      if (item.extras.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '+ ${item.extras.map((e) => "${e.name} (+${format.format(e.price)})").join(", ")}',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                      if (item.specialInstructions.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Note: "${item.specialInstructions}"',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Qty ${item.quantity}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      format.format(item.total),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Payment Method Pill Selectors
                      _buildDetailSectionTitle('BILLING PAYMENT METHOD'),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Cash', 'UPI', 'Card'].map((method) {
                          final isSelected = selectedPaymentMethod == method;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setStateSheet(() {
                                  selectedPaymentMethod = method;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryGold : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    method.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Financial Total Calculations
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildFinanceRow('Subtotal', format.format(order.subtotal)),
                            const SizedBox(height: 8),
                            _buildFinanceRow('Discounts Applied', '- ${format.format(order.discount)}', valColor: Colors.green),
                            const SizedBox(height: 8),
                            // Simple mock 5% tax listing
                            _buildFinanceRow('GST Tax (5%)', format.format((order.total - order.subtotal + order.discount).clamp(0, double.infinity))),
                            const Divider(color: Colors.grey, height: 20, thickness: 0.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Final Total Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                Text(
                                  format.format(order.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // VISUAL ORDER STEP TIMELINE
                      _buildDetailSectionTitle('ORDER TIMELINE TRACKER'),
                      const SizedBox(height: 16),
                      _buildTimelineTracker(timelineIndex),
                      const SizedBox(height: 32),

                      // Actions row at base of detail sheet
                      if (order.status != 'completed' && order.status != 'cancelled')
                        ElevatedButton(
                          onPressed: () async {
                            final orderProv = Provider.of<OrderProvider>(context, listen: false);
                            if (order.status == 'pending') {
                              await orderProv.updateStatus(order.id, 'preparing');
                            } else if (order.status == 'preparing') {
                              await orderProv.updateStatus(order.id, 'ready');
                            } else if (order.status == 'ready') {
                              await orderProv.updateStatus(order.id, 'completed');
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: order.status == 'pending'
                                ? AppTheme.accentOrange
                                : order.status == 'preparing'
                                    ? AppTheme.statusReady
                                    : Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            order.status == 'pending'
                                ? '▶ START PREPARING NOW'
                                : order.status == 'preparing'
                                    ? '✅ MARK AS READY'
                                    : '📤 COMPLETE ORDER',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (order.status != 'cancelled' && order.status != 'completed')
                        OutlinedButton(
                          onPressed: () async {
                            final orderProv = Provider.of<OrderProvider>(context, listen: false);
                            await orderProv.updateStatus(order.id, 'cancelled');
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusCancelled,
                            side: const BorderSide(color: AppTheme.statusCancelled),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('CANCEL THIS ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildDetailSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryGold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGold),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFinanceRow(String label, String value, {Color? valColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Text(value, style: TextStyle(color: valColor ?? Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Vertical Timeline Visual Progression
  Widget _buildTimelineTracker(int activeIndex) {
    final steps = [
      {'title': 'Order Received', 'subtitle': 'Order verified on local POS terminal'},
      {'title': 'Preparing Shawarma', 'subtitle': 'Chef loaded grill and carving meat'},
      {'title': 'Ready to Serve', 'subtitle': 'Dine-In tray filled / takeaway packed'},
      {'title': 'Order Completed', 'subtitle': 'Payment confirmed & delivery done'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final isDone = index <= activeIndex;
        final isLast = index == steps.length - 1;
        final color = isDone ? AppTheme.primaryGold : Colors.grey.shade800;
        
        return IntrinsicHeight(
          child: Row(
            children: [
              // Timeline indicators
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.black : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: isDone ? [
                        BoxShadow(
                          color: AppTheme.primaryGold.withOpacity(0.3),
                          blurRadius: 6,
                        )
                      ] : [],
                    ),
                    child: isDone
                        ? const Center(
                            child: Icon(Icons.check, size: 10, color: AppTheme.primaryGold),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: index < activeIndex ? AppTheme.primaryGold : Colors.grey.shade800,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Timeline details text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.white : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[index]['subtitle']!,
                        style: TextStyle(
                          color: isDone ? AppTheme.textMuted : Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- REPORT STATS SIMULATION DIALOG ---
  void _simulateReportsDialog(BuildContext context, OrderProvider orderProv) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment, color: AppTheme.primaryGold),
                  SizedBox(width: 8),
                  Text(
                    'Daily Report Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF333333), height: 24),
              _buildReportItemRow('Total Income Today', format.format(orderProv.todaySales), Colors.green),
              const SizedBox(height: 10),
              _buildReportItemRow('Sales Count Today', '${orderProv.todayOrdersCount} Orders', Colors.blue),
              const SizedBox(height: 10),
              _buildReportItemRow('Average Ticket Size', format.format(orderProv.averageOrderValue), Colors.teal),
              const SizedBox(height: 10),
              _buildReportItemRow('Outstanding Pending', '${orderProv.pendingOrdersCount} Orders', AppTheme.statusPending),
              const SizedBox(height: 10),
              _buildReportItemRow('Completed Serving', '${orderProv.orders.where((o) => o.status == 'completed').length} Orders', AppTheme.statusReady),
              const Divider(color: Color(0xFF333333), height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Print command sent: Booto POS Printer compiled successfully.'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                child: const Text('PRINT PHYSICAL REPORT', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItemRow(String label, String value, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 14),
        ),
      ],
    );
  }

  // --- EXPORT PDF REPORT SIMULATION ---
  void _simulateExportDialog(BuildContext context, OrderProvider orderProv) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Start a brief visual timer inside dialog to mock compile
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context); // close compiler
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export Completed', style: TextStyle(color: Colors.white)),
                  ],
                ),
                content: const Text(
                  'All active POS orders have been compiled into BOOTO_SHAWARMA_ORDERS.csv and saved to your downloads folder.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                    child: const Text('OK', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }
        });

        return Dialog(
          backgroundColor: const Color(0xFF121212),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.accentOrange),
                const SizedBox(height: 20),
                const Text(
                  'Compiling Orders Sheet...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Formatting ${orderProv.orders.length} transaction entries',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
