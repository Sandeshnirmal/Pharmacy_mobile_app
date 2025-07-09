import 'package:flutter/material.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
import 'ProductDetailsScreen.dart'; // Import the ProductDetailsScreen
import 'CategoryPage.dart' ;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming 'Inter' font is available or similar
        scaffoldBackgroundColor: Colors.white, // Set default scaffold background to white
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial home screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the PharmacyHomePage after 3 seconds
    // This duration is set to 3 seconds as requested.
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        // Changed navigation target from LoginPage to PharmacyHomePage
        MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // A background color for your splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo for the splash screen
            Image.asset(
              'assets/images/full_logo.png', // Placeholder for your app logo
              height: 300,
              width: 300,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_pharmacy,
                size: 150,
                color: Colors.white, // White icon on teal background
              ),
            ),


            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}


class PharmacyHomePage extends StatefulWidget {
  const PharmacyHomePage({super.key});

  @override
  State<PharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<PharmacyHomePage> {
  int _selectedIndex = 0; // For the bottom navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Sample product data for demonstration
  final List<Map<String, dynamic>> featuredMedicines = [
    {
      'name': 'Cough Syrup',
      'brand': 'Brand A',
      'genericName': 'Dextromethorphan',
      'dosage': '10ml',
      'activeIngredient': 'Dextromethorphan HBr',
      'uses': 'Relieves cough due to minor throat and bronchial irritation.',
      'description': 'A non-drowsy formula for effective cough relief.',
      'howToUse': 'Adults and children 12 years and over: 10 mL every 4 hours. Children 6 to under 12 years: 5 mL every 4 hours.',
      'sideEffects': 'Nausea, dizziness, drowsiness. If symptoms persist, consult a doctor.',
      'imageUrl': 'https://placehold.co/150x150/F0E6D2/000000?text=Cough+Syrup',
      'price': 15.00,
    },
    {
      'name': 'Pain Relief Tablets',
      'brand': 'Brand B',
      'genericName': 'Ibuprofen',
      'dosage': '200mg',
      'activeIngredient': 'Ibuprofen',
      'uses': 'For the temporary relief of minor aches and pains due to headache, muscle ache, backache, minor pain of arthritis, common cold, toothache, and menstrual cramps.',
      'description': 'Fast-acting pain relief for various conditions.',
      'howToUse': 'Adults and children 12 years and over: 1 tablet every 4 to 6 hours while symptoms persist. Do not exceed 6 tablets in 24 hours.',
      'sideEffects': 'Stomach upset, heartburn, nausea. May increase risk of heart attack or stroke.',
      'imageUrl': 'https://placehold.co/150x150/D1E8E4/000000?text=Pain+Relief',
      'price': 8.50,
    },
    {
      'name': 'Vitamins & Supplements',
      'brand': 'Brand C',
      'genericName': 'Multivitamin',
      'dosage': '1 tablet',
      'activeIngredient': 'Various Vitamins & Minerals',
      'uses': 'Supports overall health and well-being.',
      'description': 'A comprehensive blend of essential vitamins and minerals.',
      'howToUse': 'Take one tablet daily with food.',
      'sideEffects': 'Generally well-tolerated. Mild stomach upset may occur.',
      'imageUrl': 'https://placehold.co/150x150/F5E6E6/000000?text=Vitamins',
      'price': 25.00,
    },
    {
      'name': 'First Aid Kit',
      'brand': 'Brand D',
      'genericName': 'Assorted Supplies',
      'dosage': 'N/A',
      'activeIngredient': 'N/A',
      'uses': 'For minor cuts, scrapes, and emergencies.',
      'description': 'Compact kit for immediate care of minor injuries.',
      'howToUse': 'Follow instructions for individual items within the kit.',
      'sideEffects': 'N/A',
      'imageUrl': 'https://placehold.co/150x150/E6F0F5/000000?text=Bandages',
      'price': 30.00,
    },
  ];

  final List<Map<String, dynamic>> everydayMedicines = [
    {
      'name': 'Antacids',
      'brand': 'Brand X',
      'genericName': 'Calcium Carbonate',
      'dosage': 'Tablet',
      'activeIngredient': 'Calcium Carbonate',
      'uses': 'For fast relief of heartburn and indigestion.',
      'description': 'Chewable tablets for quick and effective relief.',
      'howToUse': 'Chew 2-4 tablets as symptoms occur. Do not exceed 10 tablets in 24 hours.',
      'sideEffects': 'Constipation, gas.',
      'imageUrl': 'https://placehold.co/150x150/E0F2F1/000000?text=Antacids',
      'price': 7.00,
    },
    {
      'name': 'Band-Aids',
      'brand': 'Brand Y',
      'genericName': 'Adhesive Bandages',
      'dosage': 'Assorted',
      'activeIngredient': 'N/A',
      'uses': 'Protects minor cuts and scrapes.',
      'description': 'Flexible and durable adhesive bandages.',
      'howToUse': 'Clean wound, apply bandage. Change daily or as needed.',
      'sideEffects': 'Skin irritation in rare cases.',
      'imageUrl': 'https://placehold.co/150x150/FFF3E0/000000?text=Band+Aids',
      'price': 5.00,
    },
    {
      'name': 'Disinfectant Spray',
      'brand': 'Brand Z',
      'genericName': 'Antiseptic Solution',
      'dosage': 'Spray',
      'activeIngredient': 'Benzalkonium Chloride',
      'uses': 'Cleans and disinfects wounds.',
      'description': 'Alcohol-free antiseptic spray for wound care.',
      'howToUse': 'Spray directly onto affected area. Allow to dry.',
      'sideEffects': 'Mild stinging.',
      'imageUrl': 'https://placehold.co/150x150/E8F5E9/000000?text=Disinfectant',
      'price': 10.00,
    },
    {
      'name': 'Digital Thermometer',
      'brand': 'Brand W',
      'genericName': 'Digital Thermometer',
      'dosage': 'N/A',
      'activeIngredient': 'N/A',
      'uses': 'Measures body temperature accurately.',
      'description': 'Fast and accurate digital thermometer with flexible tip.',
      'howToUse': 'Follow instructions provided with the device.',
      'sideEffects': 'N/A',
      'imageUrl': 'https://placehold.co/150x150/FBE9E7/000000?text=Thermometer',
      'price': 18.00,
    },
  ];

  final List<Map<String, dynamic>> coldAndCoughMedicines = [
    {
      'name': 'Cough Drops',
      'brand': 'Brand P',
      'genericName': 'Menthol Lozenges',
      'dosage': 'Lozenge',
      'activeIngredient': 'Menthol',
      'uses': 'Soothes sore throats and coughs.',
      'description': 'Refreshing cough drops for temporary relief.',
      'howToUse': 'Dissolve one lozenge slowly in the mouth every 2 hours as needed.',
      'sideEffects': 'Mild irritation.',
      'imageUrl': 'https://placehold.co/150x150/C8E6C9/000000?text=Cough+Drops',
      'price': 3.00,
    },
    {
      'name': 'Nasal Spray',
      'brand': 'Brand Q',
      'genericName': 'Saline Nasal Spray',
      'dosage': 'Spray',
      'activeIngredient': 'Sodium Chloride',
      'uses': 'Relieves nasal congestion and dryness.',
      'description': 'Natural saline solution for nasal irrigation.',
      'howToUse': 'Spray 1-2 times in each nostril as needed.',
      'sideEffects': 'Mild stinging.',
      'imageUrl': 'https://placehold.co/150x150/BBDEFB/000000?text=Nasal+Spray',
      'price': 9.00,
    },
    {
      'name': 'Vapor Rub',
      'brand': 'Brand R',
      'genericName': 'Topical Decongestant',
      'dosage': 'Topical',
      'activeIngredient': 'Camphor, Menthol, Eucalyptus Oil',
      'uses': 'Relieves cough and nasal congestion.',
      'description': 'Soothing vapor rub for chest and throat.',
      'howToUse': 'Rub a thick layer on chest and throat. Cover with a warm, dry cloth.',
      'sideEffects': 'Skin irritation.',
      'imageUrl': 'https://placehold.co/150x150/FFECB3/000000?text=Vapor+Rub',
      'price': 6.50,
    },
    {
      'name': 'Copla', // Corrected name from 'Fever Reducer' to 'copla' as per user's last input
      'brand': 'Brand S',
      'genericName': 'Acetaminophen',
      'dosage': '500mg',
      'activeIngredient': 'Acetaminophen',
      'uses': 'Reduces fever and relieves minor aches and pains.',
      'description': 'Effective fever reducer and pain reliever.',
      'howToUse': 'Adults: Take 1-2 tablets every 4-6 hours. Do not exceed 8 tablets in 24 hours.',
      'sideEffects': 'Liver damage (with overdose), allergic reactions.',
      'imageUrl': 'https://placehold.co/150x150/F8BBD0/000000?text=Fever+Reducer',
      'price': 7.50,
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure the main page background is white
      appBar: AppBar(
        // AppBar is kept simple, search bar is part of the body for more control
        toolbarHeight: 0, // Hide default app bar
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
              child: Row(
                children: [
                  // First Image (left-aligned by default in a Row)
                  Image.asset(
                    'assets/images/infxmart_logo.png', // Path to your logo image in assets folder
                    height: 50,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_pharmacy, size: 50, color: Colors.teal),
                  ),

                  // Use Expanded to give the center content available space, then Center it
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/infxmart_words.png', // Path to your logo image in assets folder
                        height: 60,
                        width: 140,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_pharmacy, size: 50, color: Colors.teal),
                      ),
                    ),
                  ),
                  const Spacer(), // Pushes content to the right if needed
                ],
              ),
            ),
            const SizedBox(height: 10), // Space between logo and search bar

            // Search Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Removed top padding here as it's handled by logo section
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Lighter grey for search bar background
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // subtle shadow
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.close, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40, // Height for horizontal category list
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    CategoryChip(label: 'Cough'),
                    CategoryChip(label: 'Diabetes'),
                    CategoryChip(label: 'Pain Relief'),
                    CategoryChip(label: 'Vitamins'),
                    CategoryChip(label: 'First Aid'),
                    CategoryChip(label: 'Supplements'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Promotional Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100, // Placeholder color for the banner
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2), // Subtle teal shadow
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // Removed AssetImage to avoid errors if not present, relying on network/errorBuilder
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(
                    'https://placehold.co/400x180/ADD8E6/000000?text=Pharmacy+Banner',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.teal.shade100,
                      child: const Center(
                        child: Text(
                          'Promotional Banner',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Offer Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '15% off',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'On all health products',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Featured Medicines Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Featured Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: featuredMedicines.length,
                itemBuilder: (context, index) {
                  final product = featuredMedicines[index];
                  return ProductCard(
                    imageAsset: product['imageUrl'],
                    productName: product['name'],
                    brandName: product['brand'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Everyday Medicines Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Everyday Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: everydayMedicines.length,
                itemBuilder: (context, index) {
                  final product = everydayMedicines[index];
                  return ProductCard(
                    imageAsset: product['imageUrl'],
                    productName: product['name'],
                    brandName: product['brand'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Cold and Cough Medicine Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Cold and Cough Medicine',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: coldAndCoughMedicines.length,
                itemBuilder: (context, index) {
                  final product = coldAndCoughMedicines[index];
                  return ProductCard(
                    imageAsset: product['imageUrl'],
                    productName: product['name'],
                    brandName: product['brand'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // Modified Bottom Navigation Bar
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
                print('Home tapped (already on Home Screen)');
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.teal, // Highlight Home icon as it's the current screen
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
              color: Colors.grey[700],
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

// Custom Widget for Category Chips
class CategoryChip extends StatelessWidget {
  final String label;

  const CategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600), // Teal text for chips
        ),
        backgroundColor: Colors.teal.shade50, // Light teal background for chips
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.teal.shade100), // Subtle border
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Slightly more padding
      ),
    );
  }
}

// Custom Widget for Product Cards
class ProductCard extends StatelessWidget {
  final String imageAsset;
  final String productName;
  final String brandName;
  final VoidCallback? onTap; // Added onTap callback

  const ProductCard({
    super.key,
    required this.imageAsset,
    required this.productName,
    required this.brandName,
    this.onTap, // Make onTap optional
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // Wrap with GestureDetector to detect taps
      onTap: onTap, // Assign the onTap callback
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
              child: Image.network(
                imageAsset,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brandName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
