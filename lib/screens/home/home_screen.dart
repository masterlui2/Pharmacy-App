import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/data/medicine_catalog.dart';
import 'package:pharmacy_marketplace_app/models/cart_item.dart';
import 'package:pharmacy_marketplace_app/models/medicine_item.dart';
import 'package:pharmacy_marketplace_app/screens/cart/cart_screen.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/add_to_cart_sheet.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_bottom_nav.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_categories_strip.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_featured_products.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_header.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_promo_banner.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<CartItem> _cartItems;
  final Set<String> _wishlist = <String>{};

  @override
  void initState() {
    super.initState();
    _cartItems = medicineCatalog.take(3).map((medicine) {
      return CartItem(medicine: medicine, quantity: 1);
    }).toList();
  }

  int get _cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

  void _onNavSelected(int index) {
    setState(() {
      _selectedIndex = index == 1 ? 1 : 0;
    });
  }

  void _openCart() {
    setState(() => _selectedIndex = 1);
  }

  void _openHome() {
    setState(() => _selectedIndex = 0);
  }

  void _showAddToCartSheet(MedicineItem medicine) {
    var quantity = 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AddToCartSheet(
              medicine: medicine,
              quantity: quantity,
              onDecrease: () {
                if (quantity > 1) {
                  setModalState(() => quantity--);
                }
              },
              onIncrease: () => setModalState(() => quantity++),
              onConfirm: () {
                Navigator.pop(context);
                _addToCart(medicine, quantity);
                _showAddToCartSnackBar(medicine, quantity);
              },
            );
          },
        );
      },
    );
  }

  void _showAddToCartSnackBar(MedicineItem medicine, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$quantity x ${medicine.name} added to cart'),
      ),
    );
  }

  void _addToCart(MedicineItem medicine, int quantity) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.medicine.name == medicine.name,
      );

      if (existingIndex >= 0) {
        final currentItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = currentItem.copyWith(
          quantity: currentItem.quantity + quantity,
        );
        return;
      }

      _cartItems = [
        ..._cartItems,
        CartItem(medicine: medicine, quantity: quantity),
      ];
    });
  }

  void _increaseCartItem(int index) {
    setState(() {
      final item = _cartItems[index];
      _cartItems[index] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  void _decreaseCartItem(int index) {
    setState(() {
      final item = _cartItems[index];
      if (item.quantity == 1) {
        return;
      }
      _cartItems[index] = item.copyWith(quantity: item.quantity - 1);
    });
  }

  void _removeCartItem(int index) {
    setState(() {
      _cartItems = List<CartItem>.from(_cartItems)..removeAt(index);
    });
  }

  void _toggleWishlist(MedicineItem medicine) {
    setState(() {
      if (_wishlist.contains(medicine.name)) {
        _wishlist.remove(medicine.name);
      } else {
        _wishlist.add(medicine.name);
      }
    });
  }

  Widget _buildHomeBody() {
    final featuredMedicines = medicineCatalog;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(cartCount: _cartCount, onCartTap: _openCart),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: HomePromoBanner(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: HomeSectionHeader(
              title: 'Categories',
              actionLabel: '',
              onTap: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          const SliverToBoxAdapter(child: HomeCategoriesStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: HomeSectionHeader(
              title: 'Bestseller Products',
              actionLabel: 'See all',
              onTap: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: HomeFeaturedProducts(
              medicines: featuredMedicines,
              onAddToCart: _showAddToCartSheet,
              wishlist: _wishlist,
              onToggleWishlist: _toggleWishlist,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F7),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavSelected,
      ),
      body: _selectedIndex == 1
          ? CartScreen(
              items: _cartItems,
              onBack: _openHome,
              onRemove: _removeCartItem,
              onIncrease: _increaseCartItem,
              onDecrease: _decreaseCartItem,
            )
          : _buildHomeBody(),
    );
  }
}
