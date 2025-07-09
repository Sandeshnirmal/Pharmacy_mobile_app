import 'package:flutter/material.dart';
import 'main.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), // 'X' icon for closing
          onPressed: () {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
          ); }// Go back to the previous screen

        ),
        title: const Text('Scan'),
        centerTitle: true,
        elevation: 0, // Remove shadow from app bar
        backgroundColor: Colors.white, // White app bar
        foregroundColor: Colors.black, // Black icons and text
      ),
      body: Stack(
        children: [
          // Main content area for scanner feed (placeholder)
          // This column will hold the circular icons and the "Place item..." text
          Column(
            children: [
              const SizedBox(height: 40), // Provide some top padding
              // Top row of circular icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircularIcon(Icons.image_outlined, () {
                    print('Gallery tapped');
                    // Handle gallery action
                  }),
                  const SizedBox(width: 20),
                  _buildCircularIcon(Icons.camera_alt_outlined, () {
                    print('Camera tapped');
                    // Handle camera action
                  }, isPrimary: true), // Primary camera icon
                  const SizedBox(width: 20),
                  _buildCircularIcon(Icons.threesixty_outlined, () {
                    print('360 Scan tapped');
                    // Handle 360 scan action
                  }),
                ],
              ),
              // You would typically have the camera preview here
              const SizedBox(height: 100), // Space for camera feed
              Text(
                'Place item in the frame to scan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              // This Expanded widget will push the content above it to the top
              // and allow the bottom buttons to be positioned relative to the bottom of the screen.
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

          // Bottom buttons ("Scan Prescription" and "Capture Strip")
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Increased bottom padding to lift these buttons above the FABs
              padding: const EdgeInsets.only(bottom: 180.0, left: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('Scan Prescription tapped');
                        // Handle scan prescription action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Blue button
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withOpacity(0.4),
                      ),
                      child: const Text(
                        'Scan Prescription',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Space between buttons
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('Capture Strip tapped');
                        // Handle capture strip action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200], // Light grey button
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 2,
                        shadowColor: Colors.grey.withOpacity(0.2),
                      ),
                      child: Text(
                        'Capture Strip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800], // Dark grey text
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons on the right
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0, right: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'gallery_fab', // Unique tag for multiple FABs
                    onPressed: () {
                      print('Bottom Gallery FAB tapped');
                      // Handle gallery action
                    },
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.image_outlined, color: Colors.white),
                    elevation: 4,
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'delete_fab', // Unique tag for multiple FABs
                    onPressed: () {
                      print('Delete tapped');
                      // Handle delete action
                    },
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                    elevation: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIcon(IconData icon, VoidCallback onPressed, {bool isPrimary = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40), // Make it circular
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blueAccent : Colors.grey[200], // Blue for primary, grey for others
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? Colors.blueAccent : Colors.grey[300]!).withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 40, // Larger icon size
          color: isPrimary ? Colors.white : Colors.grey[700], // White for primary, dark grey for others
        ),
      ),
    );
  }
}
