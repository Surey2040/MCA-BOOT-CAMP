import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class OrderFlowScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const OrderFlowScreen({super.key, this.onNavigateTab});

  @override
  State<OrderFlowScreen> createState() => _OrderFlowScreenState();
}

class _OrderFlowScreenState extends State<OrderFlowScreen> {
  int _currentStep = 1; // Steps 1 to 7
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Order? _lastCreatedOrder; // Holds order details on success screen

  // Category image list for Step 2
  final Map<int, String> _categoryImages = {
    1: 'https://images.unsplash.com/photo-1642683263229-bc84d62f0269?w=400&q=80',
    2: 'https://images.unsplash.com/photo-1613904985222-0d534430bdbd?w=400&q=80',
    3: 'assets/images/plate_shawarma.jpg',
    4: 'https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?w=400&q=80',
    5: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
  };

  // Product visual image mapping helper
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

  // Fallback overridden lists to support the exact requested items of Step 3
  List<MenuItem> _getStep3Items(int categoryId, List<MenuItem> databaseItems) {
    // Return database values if category has custom entries, but ensure the prompt's required items are included
    if (categoryId == 2) {
      return [
        MenuItem(id: 101, categoryId: 2, name: 'Lays Roll Shawarma', price: 100.0, description: 'Crispy classic potato lays rolled inside grilled shawarma wrap.'),
        MenuItem(id: 102, categoryId: 2, name: 'Double Lays Roll', price: 110.0, description: 'Double loaded chicken shawarma wrap with spicy classic lays chips.'),
        MenuItem(id: 103, categoryId: 2, name: 'Lays Pocket Shawarma', price: 130.0, description: 'Unique bread pocket stuffed with spicy garlic shawarma and lays chips.'),
        MenuItem(id: 104, categoryId: 2, name: 'Double Lays Pocket Shawarma', price: 140.0, description: 'Loaded double chicken pocket filled with layers of crunchy lays chips.'),
      ];
    } else if (categoryId == 4) {
      return [
        MenuItem(id: 201, categoryId: 4, name: 'Classic Mug', price: 150.0, description: 'Layered chicken shawarma, fries and house garlic dip inside a glass mug.'),
        MenuItem(id: 202, categoryId: 4, name: 'Spicy Mug', price: 150.0, description: 'Fiery peri-peri chicken shawarma layered with red chilli sauces in a mug.'),
        MenuItem(id: 203, categoryId: 4, name: 'Tandoori Mug', price: 150.0, description: 'Tandoori grilled chicken shreds with refreshing mint yogurt sauce inside a mug.'),
        MenuItem(id: 204, categoryId: 4, name: 'Mexican Mug', price: 150.0, description: 'Salsa seasoned chicken, nachos crumbs, and melted cheese loaded in a mug.'),
        MenuItem(id: 205, categoryId: 4, name: 'Schezwan Mug', price: 150.0, description: 'Spicy Schezwan chicken shreds layered with chips and cabbage in a mug.'),
        MenuItem(id: 206, categoryId: 4, name: 'Zombie Mug', price: 150.0, description: 'Ultimate ghost pepper spiced chicken and hot cheese fries layered in a mug.'),
        MenuItem(id: 207, categoryId: 4, name: 'Double Cheese Mug', price: 160.0, description: 'Double cheese sauce and melted mozzarella poured inside loaded chicken mug.'),
      ];
    }
    // Return standard SQLite items otherwise
    return databaseItems.where((item) => item.categoryId == categoryId).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Jump to specific step with UI refresh
  void _navigateToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProv = Provider.of<MenuProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Premium dark POS theme
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP PROGRESS TRACKER BAR (Hidden on Success step 7)
            if (_currentStep < 7) _buildStepProgressTracker(),

            // MAIN INTERACTIVE SCREEN BODY
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildCurrentStepScreen(context, menuProv, cartProv, currencyFormat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PROGRESS INDICATOR HEADER
  Widget _buildStepProgressTracker() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP $_currentStep OF 6',
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(6, (index) {
              final stepNum = index + 1;
              final isActive = stepNum <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive ? AppTheme.accentOrange : const Color(0xFF282828),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: AppTheme.accentOrange.withOpacity(0.5),
                        blurRadius: 4,
                      )
                    ] : [],
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Customer Details';
      case 2: return 'Select Category';
      case 3: return 'Choose Product';
      case 4: return 'Customization';
      case 5: return 'Billing Cart';
      case 6: return 'Order Confirmation';
      default: return 'Order Success';
    }
  }

  // STEP SWITCHER
  Widget _buildCurrentStepScreen(
    BuildContext context,
    MenuProvider menuProv,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    switch (_currentStep) {
      case 1: return _buildStep1CustomerDetails(context, cartProv);
      case 2: return _buildStep2SelectCategory(context, menuProv);
      case 3: return _buildStep3SelectProduct(context, menuProv, cartProv, format);
      case 4: return _buildStep4Customization(context, cartProv, format);
      case 5: return _buildStep5CartSummary(context, cartProv, format);
      case 6: return _buildStep6Confirmation(context, cartProv, format);
      case 7: return _buildStep7SuccessScreen(context, cartProv, format);
      default: return _buildStep1CustomerDetails(context, cartProv);
    }
  }

  // ==========================================
  // STEP 1: CUSTOMER DETAILS SCREEN
  // ==========================================
  Widget _buildStep1CustomerDetails(BuildContext context, CartProvider cartProv) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Street Food Branding Logo
          _buildBrandBrandingLogo(),
          const SizedBox(height: 32),

          // Glassmorphic Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.03),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assignment_ind, color: AppTheme.primaryGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'BOOKING DETAILS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name input
                const Text('Customer Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter name (e.g. Rahul K.)',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGold, size: 20),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                  ),
                ),
                const SizedBox(height: 20),

                // Mobile Input
                const Text('Mobile Number (Optional)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: const Icon(Icons.phone_android_outlined, color: AppTheme.primaryGold, size: 20),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                  ),
                ),
                const SizedBox(height: 24),

                // Dine In / Take Away Choice Selectors
                const Text('ORDER DINING TYPE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDiningTypeCard(
                        label: 'Dine In',
                        icon: Icons.restaurant,
                        isSelected: cartProv.orderType == 'Dine In',
                        onTap: () => cartProv.setOrderType('Dine In'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDiningTypeCard(
                        label: 'Take Away',
                        icon: Icons.takeout_dining,
                        isSelected: cartProv.orderType == 'Take Away',
                        onTap: () => cartProv.setOrderType('Take Away'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Action Button
          ElevatedButton(
            onPressed: () {
              // Set Details inside provider (defaulting customer details if empty)
              final name = _nameController.text.trim().isEmpty ? 'Walk-In Customer' : _nameController.text.trim();
              final mobile = _mobileController.text.trim();
              cartProv.setCustomerDetails(name, mobile);
              
              // Proceed
              _navigateToStep(2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CONTINUE TO MENU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiningTypeCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = isSelected ? AppTheme.accentOrange : const Color(0xFF282828);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF251A15) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activeColor, width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.accentOrange.withOpacity(0.08),
              blurRadius: 6,
            )
          ] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentOrange : AppTheme.textMuted, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandBrandingLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFFC107)]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.local_fire_department, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          'BOOTO SHAWARMA',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 22,
                letterSpacing: 2.0,
              ),
        ),
        const Text(
          'FAST-FOOD POS SYSTEM',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: CATEGORY SELECTOR SCREEN
  // ==========================================
  Widget _buildStep2SelectCategory(BuildContext context, MenuProvider menuProv) {
    if (menuProv.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    // Static display list for counts
    final Map<int, String> categoryTitles = {
      1: 'Shawarma',
      2: 'Lays Shawarma',
      3: 'Plate Shawarma',
      4: 'Mug Shawarma',
      5: 'Special Shawarma',
    };

    final Map<int, String> categoryCounts = {
      1: '4 Items Available',
      2: '4 Items Available',
      3: '3 Items Available',
      4: '7 Items Available',
      5: '3 Items Available',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF121212),
        child: OutlinedButton(
          onPressed: () => _navigateToStep(1),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
            side: const BorderSide(color: Color(0xFF333333)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('BACK TO CUSTOMER DETAILS'),
        ),
      ),
      body: ListView.builder(
        key: const ValueKey('step2'),
        padding: const EdgeInsets.all(20),
        itemCount: menuProv.categories.length,
        itemBuilder: (context, idx) {
          final cat = menuProv.categories[idx];
          final imageUrl = _categoryImages[cat.id] ?? 'https://images.unsplash.com/photo-1642683263229-bc84d62f0269?w=400&q=80';
          
          return GestureDetector(
            onTap: () {
              menuProv.selectCategory(cat.id);
              _navigateToStep(3);
            },
            child: Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: (imageUrl.startsWith('http') ? NetworkImage(imageUrl) : AssetImage(imageUrl)) as ImageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.srcOver),
                ),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          categoryTitles[cat.id] ?? cat.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryCounts[cat.id] ?? 'Multiple items available',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.black45,
                      radius: 20,
                      child: Icon(Icons.arrow_forward_ios, color: AppTheme.primaryGold, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // STEP 3: SELECT PRODUCT SCREEN
  // ==========================================
  Widget _buildStep3SelectProduct(
    BuildContext context,
    MenuProvider menuProv,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    final selectedCatId = menuProv.selectedCategoryId ?? 1;
    final items = _getStep3Items(selectedCatId, menuProv.menuItems);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF121212),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _navigateToStep(2),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Color(0xFF333333)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('BACK TO CATEGORY'),
              ),
            ),
            if (cartProv.cartItems.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToStep(5),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: Text('VIEW CART (${cartProv.cartItems.length})'),
                ),
              ),
            ],
          ],
        ),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No products available inside category.'))
          : GridView.builder(
              key: const ValueKey('step3'),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final imageUrl = _getItemImage(item.name);
                
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withOpacity(0.02),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Food Image Thumbnail
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              imageUrl.startsWith('http')
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : Image.asset(imageUrl, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    format.format(item.price),
                                    style: const TextStyle(
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Text Info + Add Button
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  cartProv.configureActiveItem(item);
                                  _navigateToStep(4); // Customize
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  foregroundColor: AppTheme.primaryGold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: AppTheme.primaryGold, width: 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(double.infinity, 36),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 14),
                                    SizedBox(width: 4),
                                    Text('ADD ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ==========================================
  // STEP 4: CUSTOMIZATION SCREEN
  // ==========================================
  Widget _buildStep4Customization(
    BuildContext context,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    final item = cartProv.activeMenuItem;
    if (item == null) {
      return const Center(child: Text('No product selected for customization.'));
    }

    final imageUrl = _getItemImage(item.name);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF121212),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  cartProv.clearCart(); // resets configure
                  _notesController.clear();
                  _navigateToStep(3);
                },
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
                onPressed: () {
                  cartProv.addActiveItemToCart();
                  _notesController.clear();
                  _navigateToStep(5); // Go to Cart summary
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        key: const ValueKey('step4'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected product preview card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: imageUrl.startsWith('http')
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Image.asset(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(item.price),
                          style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity selector row
            const Text('CHOOSE QUANTITY', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentOrange, size: 28),
                        onPressed: () => cartProv.updateActiveQuantity(cartProv.activeQuantity - 1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${cartProv.activeQuantity}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.statusReady, size: 28),
                        onPressed: () => cartProv.updateActiveQuantity(cartProv.activeQuantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Extras section list
            const Text('SELECT EXTRA ADD-ONS', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Column(
              children: cartProv.availableExtras.map((extra) {
                final isChecked = cartProv.activeExtras.any((e) => e.name == extra.name);
                return GestureDetector(
                  onTap: () => cartProv.toggleActiveExtra(extra),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isChecked ? const Color(0xFF251F14) : const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isChecked ? AppTheme.primaryGold : Colors.white.withOpacity(0.04),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(extra.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text(
                              '+ ${format.format(extra.price)}',
                              style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              isChecked ? Icons.check_circle : Icons.radio_button_off,
                              color: isChecked ? AppTheme.primaryGold : Colors.grey.shade700,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Cooking Instruction special notes
            const Text('SPECIAL INSTRUCTIONS / NOTES', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. No Onion, Extra Spicy, Mayo on side...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282828))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGold)),
              ),
              onChanged: (val) => cartProv.updateActiveSpecialInstructions(val),
            ),
            const SizedBox(height: 24),

            // Active Total Calculation row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Item Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    format.format(cartProv.activeItemTotal),
                    style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 5: BILLING CART SUMMARY
  // ==========================================
  Widget _buildStep5CartSummary(
    BuildContext context,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF121212),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _navigateToStep(2); // Go select category again
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD MORE ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: cartProv.cartItems.isEmpty
                    ? null
                    : () {
                        _navigateToStep(6); // Go confirmation
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusReady,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.assignment_turned_in, size: 16),
                label: const Text('PROCEED TO ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
      body: cartProv.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade700),
                  const SizedBox(height: 12),
                  const Text('Cart is empty. Please add items.', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : SingleChildScrollView(
              key: const ValueKey('step5'),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // List of Cart items
                  const Text('ITEMS ADDED', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProv.cartItems.length,
                    itemBuilder: (context, idx) {
                      final item = cartProv.cartItems[idx];
                      final imageUrl = _getItemImage(item.itemName ?? '');
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.startsWith('http')
                                  ? Image.network(imageUrl, width: 44, height: 44, fit: BoxFit.cover)
                                  : Image.asset(imageUrl, width: 44, height: 44, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName ?? 'MenuItem',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                  if (item.extras.isNotEmpty)
                                    Text(
                                      '+ Extras: ${item.extras.map((e) => e.name).join(", ")}',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                                    ),
                                  if (item.specialInstructions.isNotEmpty)
                                    Text(
                                      'Note: "${item.specialInstructions}"',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Qty ${item.quantity}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  format.format(item.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.statusCancelled, size: 20),
                              onPressed: () => cartProv.removeCartItem(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Discount Field Row
                  const Text('APPLY BILL DISCOUNT', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Discount Amount (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        SizedBox(
                          width: 100,
                          height: 38,
                          child: TextField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '₹0.0',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF282828))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryGold)),
                            ),
                            onChanged: (val) {
                              final discount = double.tryParse(val) ?? 0.0;
                              cartProv.setDiscount(discount);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing aggregate summary list
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildFinanceRow('Subtotal', format.format(cartProv.subtotal)),
                        const SizedBox(height: 8),
                        _buildFinanceRow('Discount Deduction', '- ${format.format(cartProv.discount)}', valColor: Colors.green),
                        const SizedBox(height: 8),
                        _buildFinanceRow('GST Tax (5%)', format.format((cartProv.total * 0.05).clamp(0, double.infinity))),
                        const Divider(color: Colors.grey, height: 20, thickness: 0.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Final Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            Text(
                              format.format(cartProv.total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // STEP 6: ORDER CONFIRMATION
  // ==========================================
  Widget _buildStep6Confirmation(
    BuildContext context,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    // Generate temporary order number for display in preview receipt before checkout completes
    final tempOrderNum = '#ORD${DateFormat("yyMMdd").format(DateTime.now())}-${(DateTime.now().millisecond).toString().padLeft(3, '0')}';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF121212),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _navigateToStep(5); // Go back to cart
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusCancelled,
                  side: const BorderSide(color: AppTheme.statusCancelled),
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
                  // Run checkout transaction
                  final resultOrder = await cartProv.checkout();
                  if (resultOrder != null && context.mounted) {
                    setState(() {
                      _lastCreatedOrder = resultOrder;
                    });
                    
                    // Reload local lists in Provider
                    Provider.of<OrderProvider>(context, listen: false).loadOrdersLocal();
                    
                    // Proceed to Success tab
                    _navigateToStep(7);
                    
                    // Clear inputs
                    _nameController.clear();
                    _mobileController.clear();
                    _discountController.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction failed. Cart is empty or SQLite DB error.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusReady,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        key: const ValueKey('step6'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'POS RECEIPT PREVIEW',
              style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Thermal printed styled box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      '*** BOOTO SHAWARMA ***',
                      style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Draft Receipt Invoice',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54),
                    ),
                  ),
                  const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                  _buildReceiptTextRow('Invoice No', tempOrderNum),
                  _buildReceiptTextRow('Customer', cartProv.customerName.isEmpty ? 'Walk-In Customer' : cartProv.customerName),
                  _buildReceiptTextRow('Mobile', cartProv.customerMobile.isEmpty ? '-' : cartProv.customerMobile),
                  _buildReceiptTextRow('Dining', cartProv.orderType),
                  _buildReceiptTextRow('Time', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
                  const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                  const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text('Price', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black), textAlign: TextAlign.right)),
                    ],
                  ),
                  const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                  ...cartProv.cartItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.itemName ?? 'FoodItem', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black)),
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
                  _buildReceiptFinanceRow('Subtotal', format.format(cartProv.subtotal)),
                  _buildReceiptFinanceRow('Discount', '- ${format.format(cartProv.discount)}'),
                  _buildReceiptFinanceRow('GST Tax (5%)', format.format(cartProv.total * 0.05)),
                  const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                  _buildReceiptFinanceRow('NET TOTAL', format.format(cartProv.total), isBold: true),
                  const Text('--------------------------------', style: TextStyle(color: Colors.black, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54)),
          Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReceiptFinanceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'monospace', fontSize: isBold ? 11 : 10, color: Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: isBold ? 11 : 10, color: Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ==========================================
  // STEP 7: ORDER SUCCESS SCREEN
  // ==========================================
  Widget _buildStep7SuccessScreen(
    BuildContext context,
    CartProvider cartProv,
    NumberFormat format,
  ) {
    final orderNum = _lastCreatedOrder?.orderNumber ?? '#ORD1025';
    final orderTotal = _lastCreatedOrder?.total ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          key: const ValueKey('step7'),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Glowing Neon Checkmark Circle Animation
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1B5E20).withOpacity(0.2),
                          border: Border.all(color: AppTheme.statusReady, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.statusReady.withOpacity(0.3 * val),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.done_all,
                          color: AppTheme.statusReady,
                          size: 52,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Title Success Message
              const Text(
                'ORDER SUCCESSFULLY CREATED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Overview specifications card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    _buildSuccessDetailRow('Invoice Reference', orderNum, color: AppTheme.primaryGold),
                    const Divider(color: Color(0xFF282828), height: 20),
                    _buildSuccessDetailRow('Customer Name', _lastCreatedOrder?.customerName ?? 'Walk-In Customer'),
                    const Divider(color: Color(0xFF282828), height: 20),
                    _buildSuccessDetailRow('Total Paid', format.format(orderTotal)),
                    const Divider(color: Color(0xFF282828), height: 20),
                    _buildSuccessDetailRow('Preparation Time', '15 Minutes', color: AppTheme.accentOrange),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Actions Buttons
              ElevatedButton.icon(
                onPressed: () {
                  // Switch main page navigation tabs to Orders (index 1)
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                  
                  // Reset steps
                  _navigateToStep(1);
                  _lastCreatedOrder = null;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text('VIEW ALL POS ORDERS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  cartProv.clearCart();
                  setState(() {
                    _lastCreatedOrder = null;
                  });
                  _navigateToStep(1); // Go back customer details
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF333333)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('CREATE NEW POS ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
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
}
