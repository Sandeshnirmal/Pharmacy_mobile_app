import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'LoginScreen.dart';
import 'RegisterScreen.dart';
import 'ProfileDetailsScreen.dart';
import 'screens/profile/my_orders_screen.dart';
import 'services/auth_service.dart';
import 'screens/profile/prescription_history_screen.dart';
import 'screens/profile/address_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'main.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();

  // Sample user data - in real app, this would come from API/authentication
  Map<String, dynamic>? _userProfile;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final userData = await _authService.getCurrentUser();
        setState(() {
          _isAuthenticated = true;
          _userProfile =
              userData ??
              {
                'first_name': 'John',
                'last_name': 'Doe',
                'email': 'vjsanthakumar@gmail.com',
                'phone': '+91 9876543210',
              };
        });
      } else {
        setState(() {
          _isAuthenticated = false;
          _userProfile = null;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _userProfile = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.logout();
      setState(() {
        _isAuthenticated = false;
        _userProfile = null;
      });

      Fluttertoast.showToast(
        msg: 'Logged out successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Logout failed: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () =>
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PharmacyHomePage(),
              ),
            )
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
          : !_isAuthenticated
          ? _buildLoginPrompt()
          : _buildAuthenticatedProfile(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.shade200, width: 2),
              ),
              child: Icon(
                Icons.person_outline,
                size: 60,
                color: Colors.teal.shade600,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Pharmacy App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to access your profile, orders, and personalized recommendations',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                'Create New Account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedProfile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // User Profile Section
          Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  '${_userProfile?['first_name']?[0] ?? 'U'}${_userProfile?['last_name']?[0] ?? ''}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_userProfile?['first_name'] ?? ''} ${_userProfile?['last_name'] ?? ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userProfile?['email'] ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile?['phone'] ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // View Full Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Full Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildOptionTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: 'View your order history',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildOptionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildOptionTile(
                  icon: Icons.medical_services_outlined,
                  title: 'Prescriptions',
                  subtitle: 'View uploaded prescriptions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrescriptionHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildOptionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Invoices',
                  subtitle: 'View your invoices',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Invoices')),
                          body: const Center(
                            child: Text('Invoices screen - coming soon!'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildOptionTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences and privacy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.teal.shade600, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  // void _showFeatureComingSoon(String feature) {
  //   Fluttertoast.showToast(
  //     msg: '$feature feature coming soon!',
  //     toastLength: Toast.LENGTH_SHORT,
  //     gravity: ToastGravity.BOTTOM,
  //     backgroundColor: Colors.teal,
  //     textColor: Colors.white,
  //   );
  // }
}
