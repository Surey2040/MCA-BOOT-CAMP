import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../services/sync_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _activeRange = 'today'; // 'today', 'yesterday', 'weekly', 'monthly'
  bool _isLoading = false;
  bool _isOffline = false;

  // Remote data holders
  double _revenue = 0.0;
  int _totalOrders = 0;
  double _averageOrder = 0.0;
  String _topSellingItem = 'N/A';
  List<dynamic> _categorySales = [];
  List<dynamic> _itemSales = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isOnline = await SyncService.isServerOnline();
      if (isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final response = await http.get(Uri.parse('$baseUrl/reports?range=$_activeRange'));
        
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          setState(() {
            _isOffline = false;
            _revenue = (data['revenue'] as num).toDouble();
            _totalOrders = data['totalOrders'] as int;
            _averageOrder = double.parse(data['averageOrder'].toString());
            _topSellingItem = data['topSellingItem'] as String;
            _categorySales = data['categorySales'] as List;
            _itemSales = data['itemSales'] as List;
          });
        }
      } else {
        // Fallback: local SQLite calculations (using memory state inside OrderProvider)
        _calculateReportsLocally();
      }
    } catch (e) {
      print('Reports fetch error: $e');
      _calculateReportsLocally();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateReportsLocally() {
    if (!mounted) return;
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    
    // Fallback: local calculations based on local orders
    setState(() {
      _isOffline = true;
      _revenue = orderProv.todaySales;
      _totalOrders = orderProv.todayOrdersCount;
      _averageOrder = orderProv.averageOrderValue;
      
      final topItems = orderProv.localTopSellingItems;
      _topSellingItem = topItems.isNotEmpty ? (topItems.first['name'] as String) : 'N/A';
      
      // Stub basic local item metrics for list displays
      _categorySales = [];
      _itemSales = topItems.map((e) => {
        'item_name': e['name'],
        'quantity_sold': e['quantity'],
        'revenue': 0.0 // not compiled locally
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Range Tabs
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRangeButton('today', 'Today'),
                _buildRangeButton('yesterday', 'Yesterday'),
                _buildRangeButton('weekly', 'Weekly'),
                _buildRangeButton('monthly', 'Monthly'),
              ],
            ),
          ),

          // Offline Warning Banner
          if (_isOffline)
            Container(
              color: AppTheme.statusPending.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.statusPending, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing offline local stats. Connect to server for full reports.',
                      style: TextStyle(fontSize: 12, color: AppTheme.statusPending, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard('REVENUE', currencyFormat.format(_revenue), Icons.monetization_on, Colors.green),
                            _buildStatCard('ORDERS COUNT', '$_totalOrders', Icons.receipt, AppTheme.primaryGold),
                            _buildStatCard('AVG ORDER VALUE', currencyFormat.format(_averageOrder), Icons.calculate, Colors.teal),
                            _buildStatCard('TOP ITEM', _topSellingItem, Icons.star, AppTheme.accentOrange),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section: Category Sales
                        if (_categorySales.isNotEmpty) ...[
                          const Text(
                            'SALES BY CATEGORY',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 13, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _categorySales.length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                              itemBuilder: (context, idx) {
                                final cat = _categorySales[idx];
                                return ListTile(
                                  title: Text(cat['category_name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${cat['quantity_sold']} units sold'),
                                  trailing: Text(
                                    currencyFormat.format((cat['revenue'] as num).toDouble()),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section: Item Sales
                        const Text(
                          'SALES BY ITEM',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: _itemSales.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(child: Text('No item sales logs compiled.')),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _itemSales.length,
                                  separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                                  itemBuilder: (context, idx) {
                                    final item = _itemSales[idx];
                                    final qty = item['quantity_sold'] ?? item['quantity'] ?? 0;
                                    final rev = (item['revenue'] as num?)?.toDouble() ?? 0.0;
                                    
                                    return ListTile(
                                      title: Text(item['item_name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('$qty units sold'),
                                      trailing: rev > 0 
                                          ? Text(
                                              currencyFormat.format(rev),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRangeButton(String rangeKey, String label) {
    final isActive = _activeRange == rangeKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.textDark : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isActive,
      selectedColor: AppTheme.primaryGold,
      backgroundColor: AppTheme.surfaceLight,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeRange = rangeKey;
          });
          _fetchReportData();
        }
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
