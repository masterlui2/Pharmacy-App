import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pharmacy_marketplace_app/core/config/maps_config.dart';
import 'package:pharmacy_marketplace_app/data/medicine_catalog.dart';
import 'package:pharmacy_marketplace_app/models/cart_item.dart';
import 'package:pharmacy_marketplace_app/models/delivery_address.dart';
import 'package:pharmacy_marketplace_app/models/medicine_item.dart';
import 'package:pharmacy_marketplace_app/screens/cart/cart_screen.dart';
import 'package:pharmacy_marketplace_app/screens/chat/chat_screen.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/add_to_cart_sheet.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_bottom_nav.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_categories_strip.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_featured_products.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_header.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_promo_banner.dart';
import 'package:pharmacy_marketplace_app/screens/home/widgets/home_section_header.dart';
import 'package:pharmacy_marketplace_app/screens/profile/profile_screen.dart';
import 'package:pharmacy_marketplace_app/screens/wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _davaoLatitude = 7.0731;
  static const double _davaoLongitude = 125.6128;
  static const double _maxDeliveryRadiusKm = 25;

  int _selectedIndex = 0;
  late List<CartItem> _cartItems;
  final Set<String> _wishlist = <String>{};
  DeliveryAddress _deliveryAddress = const DeliveryAddress(
    recipientName: 'Juan Dela Cruz',
    phoneNumber: '09171234567',
    addressLabel: 'Home',
    streetAddress: 'Door 4, Juna Subdivision',
    barangay: 'Matina',
    city: 'Davao City',
    notes: 'Call upon arrival',
  );
  PaymentMethod _paymentMethod = PaymentMethod.gcash;
  bool _isLocating = false;
  double? _deliveryDistanceKm;

  @override
  void initState() {
    super.initState();
    _cartItems = medicineCatalog.take(3).map((medicine) {
      return CartItem(medicine: medicine, quantity: 1);
    }).toList();
  }

  int get _cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

  List<MedicineItem> get _wishlistedItems => medicineCatalog
      .where((medicine) => _wishlist.contains(medicine.name))
      .toList(growable: false);

  double get _deliveryFee {
    final distanceKm = _deliveryDistanceKm;
    if (distanceKm == null) {
      return 79;
    }
    if (distanceKm <= 5) {
      return 49;
    }
    if (distanceKm <= 10) {
      return 79;
    }
    if (distanceKm <= 18) {
      return 119;
    }
    if (distanceKm <= _maxDeliveryRadiusKm) {
      return 159;
    }
    return 0;
  }

  bool get _isDeliveryAvailable {
    final distanceKm = _deliveryDistanceKm;
    return distanceKm == null || distanceKm <= _maxDeliveryRadiusKm;
  }

  void _onNavSelected(int index) {
    setState(() => _selectedIndex = index);
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

  void _updateAddress(DeliveryAddress address) {
    setState(() => _deliveryAddress = address);
  }

  void _updatePaymentMethod(PaymentMethod method) {
    setState(() => _paymentMethod = method);
  }

  Future<void> _locateUser() async {
    setState(() => _isLocating = true);

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission was not granted.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _davaoLatitude,
        _davaoLongitude,
      );
      final detectedBarangay = _nearestDavaoArea(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _deliveryDistanceKm = distanceMeters / 1000;
        _deliveryAddress = _deliveryAddress.copyWith(
          addressLabel: 'Current location',
          streetAddress:
              'Auto-detected coordinates ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          barangay: detectedBarangay,
          city: 'Davao City',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDeliveryAvailable
                  ? 'Location set near $detectedBarangay. Delivery fee updated.'
                  : 'Location detected outside the Davao delivery radius.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to detect your current location.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  String _nearestDavaoArea(double latitude, double longitude) {
    final areas = <String, ({double lat, double lng})>{
      'Poblacion District': (lat: 7.0719, lng: 125.6127),
      'Buhangin': (lat: 7.1254, lng: 125.6428),
      'Matina': (lat: 7.0561, lng: 125.5933),
      'Toril': (lat: 7.0122, lng: 125.4973),
      'Mintal': (lat: 7.0846, lng: 125.5187),
      'Bajada': (lat: 7.0925, lng: 125.6134),
      'Lanang': (lat: 7.1077, lng: 125.6525),
    };

    var nearest = 'Davao City';
    var nearestDistance = double.infinity;

    for (final entry in areas.entries) {
      final areaDistance = Geolocator.distanceBetween(
        latitude,
        longitude,
        entry.value.lat,
        entry.value.lng,
      );
      if (areaDistance < nearestDistance) {
        nearestDistance = areaDistance;
        nearest = entry.key;
      }
    }

    return nearest;
  }

  void _checkout() {
    final message = _isDeliveryAvailable
        ? 'Checkout ready with ${_paymentMethod.label} via PayMongo.${MapsConfig.isConfigured ? '' : ' Add your Google Maps key in lib/core/config/app_api_keys.dart for live maps integration.'}'
        : 'This address is outside the Davao delivery radius.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return CartScreen(
          items: _cartItems,
          onBack: _openHome,
          onRemove: _removeCartItem,
          onIncrease: _increaseCartItem,
          onDecrease: _decreaseCartItem,
          address: _deliveryAddress,
          onAddressChanged: _updateAddress,
          onLocateUser: _locateUser,
          isLocating: _isLocating,
          deliveryDistanceKm: _deliveryDistanceKm,
          deliveryFee: _deliveryFee,
          isDeliveryAvailable: _isDeliveryAvailable,
          maxDeliveryRadiusKm: _maxDeliveryRadiusKm,
          paymentMethod: _paymentMethod,
          onPaymentMethodChanged: _updatePaymentMethod,
          onCheckout: _checkout,
        );
      case 2:
        return WishlistScreen(
          items: _wishlistedItems,
          onAddToCart: (medicine) {
            _addToCart(medicine, 1);
            _showAddToCartSnackBar(medicine, 1);
          },
          onRemove: _toggleWishlist,
        );
      case 3:
        return const ChatScreen();
      case 4:
        return ProfileScreen(
          address: _deliveryAddress,
          paymentMethod: _paymentMethod,
          deliveryFee: _deliveryFee,
          isDeliveryAvailable: _isDeliveryAvailable,
        );
      default:
        return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F7),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavSelected,
      ),
      body: _buildBody(),
    );
  }
}
