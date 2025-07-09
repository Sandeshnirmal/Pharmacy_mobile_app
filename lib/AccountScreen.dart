import 'package:flutter/material.dart';
import 'main.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
//import 'ProductDetailsScreen.dart'; // Import the ProductDetailsScreen
import 'CategoryPage.dart' ;


import 'CartScreen.dart';
import 'ScannerScreen.dart';
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Profile Section
            Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: const AssetImage(
                      'assets/profile_image.png'), // Replace with your image asset
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ethan Carter',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '+1 (555) 123-4567',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'ethan.carter@email.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Account Options List
            _buildAccountOption(
              icon: Icons.storage,
              title: 'My Order..',
              onTap: () {
                // Handle My Orders tap
                print('My Orders tapped');
              },
            ),
            _buildAccountOption(
              icon: Icons.receipt_long,
              title: 'Uploaded Prescriptio...',
              onTap: () {
                // Handle Uploaded Prescriptions tap
                print('Uploaded Prescriptions tapped');
              },
            ),
            _buildAccountOption(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () {
                // Handle Saved Addresses tap
                print('Saved Addresses tapped');
              },
            ),
            _buildAccountOption(
              icon: Icons.description_outlined,
              title: 'Medical History',
              onTap: () {
                // Handle Medical History tap
                print('Medical History tapped');
              },
            ),
            const SizedBox(height: 40),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle Logout
                    print('Logout tapped');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50], // Light red background
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.red), // Red border
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red, // Red text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0, // Reduced notchMargin from 8.0 to 4.0
        color: Colors.white,
        elevation: 10.0, // Added elevation for a subtle lift
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                // This is the current page, so no navigation needed or pop until this route
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700], // Highlight Home icon as it's the current screen
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryPage()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
            // This is the floating action button for the scanner
            const SizedBox(width: 48), // The space for the FAB
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountScreen()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.teal,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Makes it circular
        ),
        elevation: 8.0, // Added elevation for the FAB
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[700]),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 20,
          endIndent: 20,
          color: Colors.grey[200],
        ),
      ],
    );
  }
