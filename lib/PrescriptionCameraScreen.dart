// Prescription Camera Screen for AI Integration
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/api_service.dart';
import 'PrescriptionResultScreen.dart';

class PrescriptionCameraScreen extends StatefulWidget {
  const PrescriptionCameraScreen({super.key});

  @override
  State<PrescriptionCameraScreen> createState() =>
      _PrescriptionCameraScreenState();
}

class _PrescriptionCameraScreenState extends State<PrescriptionCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isProcessing = false;

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });

        Fluttertoast.showToast(
          msg: "Photo captured successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to capture photo: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        Fluttertoast.showToast(
          msg: "Image selected successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to select image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _uploadPrescription() async {
    if (_selectedImage == null) {
      Fluttertoast.showToast(
        msg: "Please select or capture a prescription image first",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload prescription
      final uploadResult = await _apiService.uploadPrescription(
        _selectedImage!,
      );

      if (uploadResult.isSuccess) {
        final uploadResponse = uploadResult.data!;

        setState(() {
          _isUploading = false;
          _isProcessing = true;
        });

        Fluttertoast.showToast(
          msg: "Upload successful! AI is processing...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Wait for AI processing
        await _waitForProcessing(int.parse(uploadResponse.prescriptionId));
      } else {
        setState(() {
          _isUploading = false;
        });

        Fluttertoast.showToast(
          msg: "Upload failed: ${uploadResult.error}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      Fluttertoast.showToast(
        msg: "Upload error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _waitForProcessing(int prescriptionId) async {
    const maxAttempts = 20; // 40 seconds with 2-second intervals
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        final statusResult = await _apiService.getPrescriptionStatus(
          prescriptionId.toString(),
        );

        if (statusResult.isSuccess) {
          final status = statusResult.data!;

          // Check if processing is complete
          if (status.isReady) {
            // Processing complete, get suggestions
            final suggestionsResult = await _apiService.getMedicineSuggestions(
              prescriptionId.toString(),
            );

            setState(() {
              _isProcessing = false;
            });

            if (suggestionsResult.isSuccess) {
              // Navigate to results screen
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrescriptionResultScreen(
                      prescriptionId: prescriptionId,
                      suggestions: suggestionsResult.data!,
                    ),
                  ),
                );
              }
              return;
            } else {
              Fluttertoast.showToast(
                msg: "Failed to get suggestions: ${suggestionsResult.error}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
              return;
            }
          }

          // Check if processing failed
          if (status.status == 'Rejected' || status.status == 'Failed') {
            setState(() {
              _isProcessing = false;
            });

            Fluttertoast.showToast(
              msg: "Processing failed. Please try with a clearer image.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
            return;
          }

          // Still processing, continue waiting
        } else {
          // Status check failed, continue trying
        }

        // Wait 2 seconds before checking again
        await Future.delayed(const Duration(seconds: 2));
        attempts++;
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });

        Fluttertoast.showToast(
          msg: "Processing error: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
    }

    // Timeout
    setState(() {
      _isProcessing = false;
    });

    Fluttertoast.showToast(
      msg: "AI processing timeout. Please try again.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _retakePicture() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prescription Processing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Take a clear photo of your prescription or select from gallery. Our system will extract medicines and suggest available products.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Image Display or Upload Options
            if (_selectedImage != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Selected Prescription',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading || _isProcessing
                                  ? null
                                  : _retakePicture,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading || _isProcessing
                                  ? null
                                  : _pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading || _isProcessing
                              ? null
                              : _uploadPrescription,
                          icon: _isUploading || _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(
                            _isUploading
                                ? 'Uploading...'
                                : _isProcessing
                                ? 'AI Processing...'
                                : 'Upload & Process',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              InkWell(
                                onTap: _takePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Take Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              InkWell(
                                onTap: _pickFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library,
                                    size: 48,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Choose from Gallery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tips Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tips for Best Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Ensure good lighting'),
                    const Text('• Keep prescription flat and straight'),
                    const Text('• Make sure text is clearly visible'),
                    const Text('• Avoid shadows and reflections'),
                    const Text('• Use high resolution images'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
