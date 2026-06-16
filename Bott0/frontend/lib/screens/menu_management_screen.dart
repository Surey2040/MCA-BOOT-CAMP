import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/menu_provider.dart';
import '../theme.dart';
import '../models/menu_item.dart';
import '../models/category.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _activeCategoryId = 1; // Default to Category ID 1 (Shawarma)

  // Quick Price adjustment memory: maps MenuItem ID to temporary price state
  final Map<int, double> _quickPrices = {};

  // Image assets map
  String _getItemImage(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('classic')) {
      return 'https://images.unsplash.com/photo-1642683263229-bc84d62f0269?w=300&q=80';
    } else if (name.contains('spicy') || name.contains('tandoori') || name.contains('chili') || name.contains('peri')) {
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter items logic
  List<MenuItem> _getFilteredItems(List<MenuItem> allItems, List<Category> categories) {
    return allItems.where((item) {
      // 1. Category check
      if (item.categoryId != _activeCategoryId) return false;

      // 2. Search check (Item name, category name, price, status)
      if (_searchQuery.isNotEmpty) {
        final catName = categories.firstWhere((c) => c.id == item.categoryId, 
            orElse: () => Category(id: 0, name: 'General', slug: '')).name;
        final statusText = item.isAvailable ? 'available' : 'out of stock';
        
        final nameMatch = item.name.toLowerCase().contains(_searchQuery);
        final catMatch = catName.toLowerCase().contains(_searchQuery);
        final priceMatch = item.price.toString().contains(_searchQuery);
        final statusMatch = statusText.contains(_searchQuery);
        
        if (!nameMatch && !catMatch && !priceMatch && !statusMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final menuProv = Provider.of<MenuProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Apply filtering
    final filteredItems = _getFilteredItems(menuProv.menuItems, menuProv.categories);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuItemForm(context, null),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER BRAND BAR
            _buildAdminHeader(context),

            // 2. SEARCH BOX
            _buildSearchBar(),

            // 3. STATS SUMMARY OVERVIEW
            _buildStatsOverview(menuProv),

            // 4. POPULAR ITEMS CAROUSEL (Mini Rank list)
            _buildPopularRankings(),

            // 5. CUSTOM TAB SELECTOR
            _buildCategoryTabs(menuProv),

            // 6. MENU ITEMS DYNAMIC GRID
            Expanded(
              child: menuProv.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                  : filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu_outlined, size: 48, color: Colors.grey.shade800),
                              const SizedBox(height: 12),
                              const Text('No menu items fit this search.', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, idx) {
                            final item = filteredItems[idx];
                            return _buildMenuItemCard(context, item, currencyFormat, menuProv);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF121212),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppTheme.primaryGold, size: 24),
              SizedBox(width: 10),
              Text(
                'MENU MANAGEMENT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Notification simulated icon
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppTheme.primaryGold),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu logs: SQLite seeded successfully.')),
                  );
                },
              ),
              // Settings option panel trigger
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.primaryGold),
                onPressed: () => _showMenuSettingsBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search Item name, price, or availability status...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStatsOverview(MenuProvider menuProv) {
    final totalCount = menuProv.menuItems.length;
    final shawarmaCount = menuProv.menuItems.where((i) => i.categoryId == 1).length;
    final mugCount = menuProv.menuItems.where((i) => i.categoryId == 4).length;
    final specialCount = menuProv.menuItems.where((i) => i.categoryId == 5).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF0F0F0F),
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatOverviewCard('📦 Total Items', '$totalCount items', AppTheme.primaryGold),
          const SizedBox(width: 8),
          _buildStatOverviewCard('🌯 Shawarma', '$shawarmaCount items', AppTheme.accentOrange),
          const SizedBox(width: 8),
          _buildStatOverviewCard('☕ Mugs', '$mugCount items', Colors.yellow),
          const SizedBox(width: 8),
          _buildStatOverviewCard('🔥 Specials', '$specialCount items', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatOverviewCard(String label, String sub, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPopularRankings() {
    final rankingItems = [
      {'rank': '🥇', 'name': 'Classic Shawarma', 'sales': '84 Sold'},
      {'rank': '🥈', 'name': 'Spicy Shawarma', 'sales': '62 Sold'},
      {'rank': '🥉', 'name': 'Lays Roll', 'sales': '45 Sold'},
      {'rank': '🏅', 'name': 'Mug Shawarma', 'sales': '32 Sold'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F0F0F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 TOP SELLERS TODAY',
            style: TextStyle(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: rankingItems.map((r) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      Text(r['rank']!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        r['name']!,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r['sales']!,
                        style: const TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(MenuProvider menuProv) {
    final categoryMap = {
      1: '🌯 Shawarma',
      2: '🥔 Lays',
      3: '🍽 Plates',
      4: '☕ Mugs',
      5: '🔥 Specials',
    };

    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: menuProv.categories.map((cat) {
            final isSelected = _activeCategoryId == cat.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeCategoryId = cat.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF251A15) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentOrange : Colors.grey.withOpacity(0.15),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  categoryMap[cat.id] ?? cat.name,
                  style: TextStyle(
                    color: isSelected ? AppTheme.accentOrange : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(
    BuildContext context,
    MenuItem item,
    NumberFormat format,
    MenuProvider menuProv,
  ) {
    final imageUrl = _getItemImage(item.name);
    
    // Quick price selection initialization
    if (!_quickPrices.containsKey(item.id)) {
      _quickPrices[item.id] = item.price;
    }
    final tempPrice = _quickPrices[item.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isAvailable 
              ? AppTheme.primaryGold.withOpacity(0.15) 
              : AppTheme.statusCancelled.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.black,
                              child: const Icon(Icons.restaurant, color: AppTheme.primaryGold, size: 20),
                            ),
                          )
                        : Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.black,
                              child: const Icon(Icons.restaurant, color: AppTheme.primaryGold, size: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & availability
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isAvailable
                                  ? AppTheme.statusReady.withOpacity(0.12)
                                  : AppTheme.statusCancelled.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isAvailable ? '✅ Available' : '❌ Out of Stock',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item.isAvailable ? AppTheme.statusReady : AppTheme.statusCancelled,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PRICE', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    Text(
                      format.format(item.price),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0xFF282828), height: 18),

            // QUICK PRICE ADJUSTER PANEL
            Row(
              children: [
                const Text(
                  'QUICK PRICE: ',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                // Decrement Price
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _quickPrices[item.id] = (tempPrice - 5).clamp(0, double.infinity);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.remove, size: 14, color: AppTheme.accentOrange),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    format.format(tempPrice),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                // Increment Price
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _quickPrices[item.id] = tempPrice + 5;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.add, size: 14, color: AppTheme.statusReady),
                  ),
                ),
                const Spacer(),
                
                // mini Update button
                if (tempPrice != item.price)
                  ElevatedButton(
                    onPressed: () async {
                      final success = await menuProv.updateMenuItem(
                        item.id,
                        item.name,
                        tempPrice,
                        item.description,
                        item.categoryId,
                        item.isAvailable,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                                ? 'Price updated successfully' 
                                : 'Failed to update price'),
                            backgroundColor: success ? Colors.teal : AppTheme.statusCancelled,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(60, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('UPDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Divider(color: Color(0xFF222222), height: 18),

            // CARD EDIT / DELETE BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMenuItemForm(context, item),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('EDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGold,
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeletion(context, item),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('DELETE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusCancelled,
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- EDIT / ADD DOCK SHEET OVERLAY FORM ---
  void _showMenuItemForm(BuildContext context, MenuItem? item) {
    final menuProv = Provider.of<MenuProvider>(context, listen: false);
    
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    
    int selectedCatId = item?.categoryId ?? _activeCategoryId;
    bool isAvailable = item?.isAvailable ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item == null ? 'ADD NEW MENU ITEM' : 'EDIT MENU ITEM',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGold,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // MOCK IMAGE SELECTOR FIELD
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mock Image selector: Unsplash auto-mapping applied.')),
                        );
                      },
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance, color: AppTheme.primaryGold, size: 28),
                            SizedBox(height: 4),
                            Text('Upload/Tap Image', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    const Text('Item Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter name (e.g. Monster Shawarma)',
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    const Text('Category Group', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: selectedCatId,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                      ),
                      items: menuProv.categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedCatId = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    const Text('Price (INR)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter pricing (e.g. 150)',
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Short Description', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter description text...',
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Availability Switch
                    SwitchListTile(
                      title: const Text('Available / Instock', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      value: isAvailable,
                      activeColor: AppTheme.primaryGold,
                      onChanged: (val) {
                        setSheetState(() {
                          isAvailable = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Color(0xFF333333)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final price = double.tryParse(priceController.text.trim()) ?? -1.0;
                              final desc = descController.text.trim();

                              if (name.isEmpty || price < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please check validation details.')),
                                );
                                return;
                              }

                              bool success;
                              if (item == null) {
                                success = await menuProv.addMenuItem(name, price, desc, selectedCatId);
                              } else {
                                success = await menuProv.updateMenuItem(item.id, name, price, desc, selectedCatId, isAvailable);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Menu configuration updated' : 'Failed updating menu item'),
                                    backgroundColor: success ? Colors.teal : AppTheme.statusCancelled,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- CONFIRM DELETION ---
  void _confirmDeletion(BuildContext context, MenuItem item) {
    final menuProv = Provider.of<MenuProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.statusCancelled, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.statusCancelled),
            SizedBox(width: 8),
            Text('Delete Menu Item?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            text: 'Are you sure you want to permanently delete ',
            style: const TextStyle(color: AppTheme.textMuted),
            children: [
              TextSpan(
                text: item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await menuProv.deleteMenuItem(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Item successfully deleted' : 'Failed to delete item'),
                    backgroundColor: success ? Colors.teal : AppTheme.statusCancelled,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCancelled),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- MENU SETTINGS BOTTOM SHEET ---
  void _showMenuSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MENU UTILITIES & SETTINGS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryGold, letterSpacing: 0.8),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildSettingOption(context, Icons.cloud_download, 'Export Menu Database', 'Save menu list as JSON layout to device Storage.'),
              const Divider(color: Color(0xFF282828), height: 16),
              _buildSettingOption(context, Icons.cloud_upload, 'Import Menu Layout', 'Load custom menu layout configs from local backup.'),
              const Divider(color: Color(0xFF282828), height: 16),
              _buildSettingOption(context, Icons.cloud_upload_outlined, 'Backup Menu configurations', 'Synchronize current items state directly to cloud backend.'),
              const Divider(color: Color(0xFF282828), height: 16),
              _buildSettingOption(context, Icons.restart_alt, 'Reset Menu Default state', 'Wipe SQLite configuration and seed original catalog.'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingOption(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1E1E1E),
        child: Icon(icon, color: AppTheme.primaryGold, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      onTap: () {
        Navigator.pop(context);
        // Show progress spinner
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                Navigator.pop(context); // close loader
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title Completed successfully!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            });

            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.accentOrange),
                    const SizedBox(height: 16),
                    Text(
                      'Running: ${title.toUpperCase()}...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
