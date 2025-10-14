import 'package:flutter/material.dart';

// Import screens from organized folders
import '../screens/splash_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/auth/login_screen.dart';
// import '../screens/home/home_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/order_confirmation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/address_screen.dart';
import '../screens/profile/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String mainNavigation = '/main';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderSuccess = '/order-success';
  static const String profile = '/profile';
  static const String address = '/address';
  static const String settings = '/settings';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // case home:
      //   return MaterialPageRoute(builder: (_) => const HomeScreen());

      case mainNavigation:
        return MaterialPageRoute(builder: (_) => const MainNavigation());

      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());

      case productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final product = args?['product'];
        if (product == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundScreen());
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );

      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case orderDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: args?['orderId'] ?? 0),
        );

      case orderConfirmation:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            orderId: args?['orderId'] ?? 0,
            orderNumber: args?['orderNumber'] ?? 'N/A',
            totalAmount: args?['totalAmount'] ?? 0.0,
          ),
        );

      case orderSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            order: args?['order'] ?? {},
            payment: args?['payment'] ?? {},
          ),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case address:
        return MaterialPageRoute(builder: (_) => const AddressScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}

// Order Success Screen
class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> payment;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Successful'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green[600]),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Order ID: ${order['id'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Payment ID: ${payment['payment_id'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mainNavigation,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue Shopping'),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.orderDetail,
                  arguments: {'orderId': order['id']},
                );
              },
              child: const Text('View Order Details'),
            ),
          ],
        ),
      ),
    );
  }
}

// Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('The requested page could not be found.'),
          ],
        ),
      ),
    );
  }
}
