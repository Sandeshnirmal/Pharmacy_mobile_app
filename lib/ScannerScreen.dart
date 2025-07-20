import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'main.dart';
import 'services/prescription_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'PrescriptionProcessingScreen.dart';
import 'LoginScreen.dart';

/// ScannerScreen - For prescription scanning and medicine discovery
/// This screen is used to scan prescriptions to find and discover medicines,
/// NOT for order authentication. For order prescription upload, use OrderPrescriptionUploadScreen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  bool _isUploading = false;
  List<Map<String, dynamic>> _recentPrescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadRecentPrescriptions();
  }

  Future<void> _loadRecentPrescriptions() async {
    // Load recent prescriptions from the service
    // This would be implemented with the actual API call
    setState(() {
      _recentPrescriptions = [
        {
          'id': 1,
          'date': '2024-01-15',
          'status': 'Processed',
          'medicines_count': 3,
          'doctor': 'Dr. Smith'
        },
        {
          'id': 2,
          'date': '2024-01-10',
          'status': 'Processing',
          'medicines_count': 2,
          'doctor': 'Dr. Johnson'
        },
      ];
    });
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Check and request camera permission
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _showPermissionDeniedDialog('Camera');
          return;
        }
      }

      if (cameraStatus.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog('Camera');
        return;
      }

      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImagePreview();
      }
    } catch (e) {
      print('Camera error: $e');
      Fluttertoast.showToast(
        msg: 'Error accessing camera. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Check and request storage permission for older Android versions
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          if (result.isDenied) {
            _showPermissionDeniedDialog('Storage');
            return;
          }
        }

        if (storageStatus.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog('Storage');
          return;
        }
      }

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImagePreview();
      }
    } catch (e) {
      print('Gallery error: $e');
      Fluttertoast.showToast(
        msg: 'Error accessing gallery. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showImagePreview() {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('Prescription Preview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Error loading image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Make sure the prescription is clear and all text is readable',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Is this image clear and readable?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
              });
            },
            child: const Text(
              'Retake',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadPrescription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Upload & Process'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPrescription() async {
    if (_selectedImage == null) return;

    // Check authentication first
    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Show upload progress
      _showUploadProgressDialog();

      // Real prescription upload using API
      final uploadResult = await _apiService.uploadPrescription(_selectedImage!);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        if (uploadResult.isSuccess) {
          final uploadResponse = uploadResult.data!;

          Fluttertoast.showToast(
            msg: 'Prescription uploaded successfully! Processing with AI...',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Navigate to prescription processing screen with real ID
          _showProcessingScreen(uploadResponse.prescriptionId);
        } else {
          Fluttertoast.showToast(
            msg: 'Upload failed: ${uploadResult.error}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog if open

        Fluttertoast.showToast(
          msg: 'Upload error: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'You need to be logged in to upload prescriptions. Please login or create an account to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showUploadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Uploading Prescription...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your image',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessingScreen(int prescriptionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionProcessingScreen(
          prescriptionId: prescriptionId,
        ),
      ),
    );
  }

  void _showFeatureComingSoon(String feature) {
    Fluttertoast.showToast(
      msg: '$feature feature coming soon!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.teal,
      textColor: Colors.white,
    );
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'This app needs $permissionType permission to upload prescription images. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (permissionType == 'Camera') {
                _pickImageFromCamera();
              } else {
                _pickImageFromGallery();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Denied'),
        content: Text(
          '$permissionType permission has been permanently denied. Please enable it in app settings to upload prescription images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

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
                    _pickImageFromGallery();
                  }),
                  const SizedBox(width: 20),
                  _buildCircularIcon(Icons.camera_alt_outlined, () {
                    _pickImageFromCamera();
                  }, isPrimary: true), // Primary camera icon
                  const SizedBox(width: 20),
                  _buildCircularIcon(Icons.qr_code_scanner, () {
                    _showFeatureComingSoon('QR Code Scanner');
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
                        _pickImageFromCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Blue button
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
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
                        shadowColor: Colors.grey.withValues(alpha: 0.2),
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
              color: (isPrimary ? Colors.blueAccent : Colors.grey[300]!).withValues(alpha: 0.4),
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
