import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/sync_service.dart';
import '../services/db_helper.dart';
import '../providers/order_provider.dart';
import '../models/customer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _custSearchController = TextEditingController();
  
  List<Customer> _customers = [];
  String _customerQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUrlSettings();
    _loadCustomers();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _custSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUrlSettings() async {
    final url = await SyncService.getBaseUrl();
    _urlController.text = url;
  }

  Future<void> _loadCustomers() async {
    final db = DbHelper.instance;
    final list = await db.getCustomers();
    setState(() {
      _customers = list;
    });
  }

  Future<void> _saveUrlSettings() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await SyncService.setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server API configuration updated successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final filteredCustomers = _customers.where((c) =>
        c.name.toLowerCase().contains(_customerQuery) ||
        (c.mobile != null && c.mobile!.contains(_customerQuery))
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM SETTINGS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Connection Config
            _buildSectionHeader('API CONNECTION SETTINGS'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Server API Endpoint URL',
                        hintText: 'e.g. http://192.168.1.100:5001/api',
                        prefixIcon: Icon(Icons.link, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveUrlSettings,
                      child: const Text('SAVE URL ENDPOINT'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Database Backup & Reset Options
            _buildSectionHeader('DATABASE OPERATIONS'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup, color: AppTheme.primaryGold),
                    title: const Text('Backup Database (Cloud/Local)'),
                    subtitle: const Text('Backs up SQLite and uploads JSON dump to server backups.'),
                    onTap: () => _triggerBackup(context),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore, color: AppTheme.accentOrange),
                    title: const Text('Restore Database'),
                    subtitle: const Text('Overwrites local SQLite with the latest backup state.'),
                    onTap: () => _triggerRestore(context),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppTheme.statusCancelled),
                    title: const Text('Reset Daily Sales Data', style: TextStyle(color: AppTheme.statusCancelled)),
                    subtitle: const Text('Deletes all local and server transactions for today.'),
                    onTap: () => _triggerDailyReset(context, orderProv),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Document Exports
            _buildSectionHeader('EXPORT DATA & REPORTS'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportDocument(context, 'pdf'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('EXPORT PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportDocument(context, 'excel'),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('EXPORT EXCEL'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Customer Database
            _buildSectionHeader('CUSTOMER RELATION MANAGEMENT'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _custSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Customer Profiles...',
                        prefixIcon: Icon(Icons.person_search, color: AppTheme.primaryGold),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _customerQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    filteredCustomers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text('No customers registered.')),
                          )
                        : SizedBox(
                            height: 200,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredCustomers.length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                              itemBuilder: (context, idx) {
                                final cust = filteredCustomers[idx];
                                return ListTile(
                                  title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(cust.mobile ?? 'No phone'),
                                  trailing: const Icon(Icons.history, color: AppTheme.primaryGold),
                                  onTap: () => _viewCustomerHistory(context, cust, currencyFormat),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryGold,
        letterSpacing: 0.5,
      ),
    );
  }

  // Backup flow
  Future<void> _triggerBackup(BuildContext context) async {
    final isOnline = await SyncService.isServerOnline();
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server offline. Cannot backup to cloud database.')),
      );
      return;
    }

    try {
      final baseUrl = await SyncService.getBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/settings/backup'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Backup Created'),
            content: const Text('Cloud backup has been compiled successfully on the server filesystem (backend/backups/).'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      }
    } catch (e) {
      print('Backup error: $e');
    }
  }

  // Restore database
  Future<void> _triggerRestore(BuildContext context) async {
    final isOnline = await SyncService.isServerOnline();
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server offline. Cannot fetch backup data.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text('Warning: This will overwrite SQLite files. Are you sure you want to pull data from server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Trigger sync to force pull database categories and menu structures
              final success = await SyncService.synchronize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Database synchronization pulled successfully.' : 'Failed database pull.')),
                );
              }
            },
            child: const Text('RESTORE NOW'),
          )
        ],
      ),
    );
  }

  // Reset daily sales
  Future<void> _triggerDailyReset(BuildContext context, OrderProvider orderProv) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Daily Sales', style: TextStyle(color: AppTheme.statusCancelled)),
        content: const Text('Caution: This will permanently delete today\'s local SQLite and cloud PostgreSQL orders. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 1. Wipe SQLite
              final db = DbHelper.instance;
              await db.resetDailySalesLocally();
              
              // 2. Clear cloud PostgreSQL if online
              final isOnline = await SyncService.isServerOnline();
              if (isOnline) {
                final baseUrl = await SyncService.getBaseUrl();
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                await http.post(
                  Uri.parse('$baseUrl/settings/reset-daily'),
                  headers: {
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                );
              }

              // Reload local lists
              await orderProv.loadOrdersLocal();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Daily POS orders resetted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            child: const Text('RESET', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // File exports trigger (mocked locally, triggers REST download URL on browser/device)
  void _exportDocument(BuildContext context, String format) async {
    final baseUrl = await SyncService.getBaseUrl();
    final downloadUrl = '$baseUrl/settings/export/$format';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export $format.toUpperCase()'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report file ready for export. Access endpoint download URL:'),
            const SizedBox(height: 12),
            SelectableText(
              downloadUrl,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Customer order history detail overlay dialog
  void _viewCustomerHistory(BuildContext context, Customer customer, NumberFormat format) async {
    final db = DbHelper.instance;
    final orders = await db.getOrders();
    final customerOrders = orders.where((o) => o.customerMobile == customer.mobile).toList();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${customer.name} - History'),
          content: customerOrders.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(child: Text('No purchase records found.')),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: customerOrders.length,
                    itemBuilder: (context, idx) {
                      final order = customerOrders[idx];
                      return ListTile(
                        title: Text(order.orderNumber ?? 'Invoice'),
                        subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)),
                        trailing: Text(
                          format.format(order.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
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
  }
}
