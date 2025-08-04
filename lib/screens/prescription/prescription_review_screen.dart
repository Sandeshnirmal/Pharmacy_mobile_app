// // Prescription Review Screen - Complete Flow
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/api_service.dart';
// import '../../models/api_response.dart';
// import '../../models/prescription_model.dart';
// import '../../models/product_model.dart';
// import '../../utils/api_logger.dart';
// import '../orders/order_confirmation_screen.dart';

// class PrescriptionReviewScreen extends StatefulWidget {
//   final int prescriptionId;
//   final String prescriptionImageUrl;

//   const PrescriptionReviewScreen({
//     super.key,
//     required this.prescriptionId,
//     required this.prescriptionImageUrl,
//   });

//   @override
//   State<PrescriptionReviewScreen> createState() => _PrescriptionReviewScreenState();
// }

// class _PrescriptionReviewScreenState extends State<PrescriptionReviewScreen> {
//   final ApiService _apiService = ApiService();
  
//   PrescriptionModel? _prescription;
//   List<ProductModel> _extractedMedicines = [];
//   List<ProductModel> _selectedMedicines = [];
//   Map<int, int> _quantities = {};
  
//   bool _isLoading = true;
//   bool _isProcessing = false;
//   String? _error;
//   String _verificationStatus = 'pending';

//   @override
//   void initState() {
//     super.initState();
//     _loadPrescriptionData();
//     _startStatusPolling();
//   }

//   Future<void> _loadPrescriptionData() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });

//       // Get prescription status
//       final statusResponse = await _apiService.getPrescriptionStatus(widget.prescriptionId);
      
//       if (statusResponse.isSuccess && statusResponse.data != null) {
//         final status = statusResponse.data!['status'];
//         setState(() {
//           _verificationStatus = status;
//         });

//         // If verified, get extracted medicines
//         if (status == 'verified' || status == 'processed') {
//           final medicinesResponse = await _apiService.getPrescriptionProducts(widget.prescriptionId);
          
//           if (medicinesResponse.isSuccess && medicinesResponse.data != null) {
//             final medicines = medicinesResponse.data!['products'] as List;
//             setState(() {
//               _extractedMedicines = medicines
//                   .map((medicine) => ProductModel.fromJson(medicine))
//                   .toList();
              
//               // Initialize quantities
//               for (var medicine in _extractedMedicines) {
//                 _quantities[medicine.id] = 1;
//               }
//             });
//           }
//         }
//       }

//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load prescription data: $e';
//         _isLoading = false;
//       });
//       ApiLogger.logError('Prescription review error: $e');
//     }
//   }

//   void _startStatusPolling() {
//     // Poll status every 10 seconds if still processing
//     Future.delayed(const Duration(seconds: 10), () {
//       if (mounted && (_verificationStatus == 'pending' || _verificationStatus == 'processing')) {
//         _loadPrescriptionData();
//         _startStatusPolling();
//       }
//     });
//   }

//   Future<void> _proceedToOrder() async {
//     if (_selectedMedicines.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select at least one medicine'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       // Create order from prescription
//       final orderItems = _selectedMedicines.map((medicine) {
//         return {
//           'product_id': medicine.id,
//           'quantity': _quantities[medicine.id] ?? 1,
//           'unit_price': medicine.price,
//         };
//       }).toList();

//       final orderData = {
//         'prescription_id': widget.prescriptionId,
//         'items': orderItems,
//         'is_prescription_order': true,
//         'order_type': 'prescription',
//       };

//       final response = await _apiService.createPrescriptionOrder(orderData);
      
//       if (response.isSuccess && response.data != null) {
//         // Navigate to order confirmation
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => OrderConfirmationScreen(
//                 orderId: response.data!.orderId,
//                 orderNumber: response.data!.orderNumber,
//                 totalAmount: response.data!.totalAmount,
//               ),
//             ),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(response.error ?? 'Failed to create order'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error creating order: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       ApiLogger.logError('Order creation error: $e');
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Prescription Review'),
//         backgroundColor: Colors.teal,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: _buildBody(),
//       bottomNavigationBar: _buildBottomBar(),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: Colors.teal),
//             SizedBox(height: 16),
//             Text('Loading prescription data...'),
//           ],
//         ),
//       );
//     }

//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(_error!, textAlign: TextAlign.center),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _loadPrescriptionData,
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildPrescriptionImage(),
//           const SizedBox(height: 24),
//           _buildVerificationStatus(),
//           const SizedBox(height: 24),
//           if (_verificationStatus == 'verified' || _verificationStatus == 'processed')
//             _buildExtractedMedicines(),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrescriptionImage() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Uploaded Prescription',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.teal,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               width: double.infinity,
//               height: 200,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   widget.prescriptionImageUrl,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       color: Colors.grey.shade100,
//                       child: const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
//                             SizedBox(height: 8),
//                             Text('Image not available', style: TextStyle(color: Colors.grey)),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVerificationStatus() {
//     Color statusColor;
//     IconData statusIcon;
//     String statusText;

//     switch (_verificationStatus) {
//       case 'pending':
//         statusColor = Colors.orange;
//         statusIcon = Icons.hourglass_empty;
//         statusText = 'Pending Verification';
//         break;
//       case 'processing':
//         statusColor = Colors.blue;
//         statusIcon = Icons.sync;
//         statusText = 'Processing with AI';
//         break;
//       case 'verified':
//         statusColor = Colors.green;
//         statusIcon = Icons.check_circle;
//         statusText = 'Verified & Processed';
//         break;
//       case 'rejected':
//         statusColor = Colors.red;
//         statusIcon = Icons.cancel;
//         statusText = 'Rejected';
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusIcon = Icons.help;
//         statusText = 'Unknown Status';
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: statusColor.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(statusIcon, color: statusColor, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     statusText,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: statusColor,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _getStatusDescription(),
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (_verificationStatus == 'processing')
//               const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getStatusDescription() {
//     switch (_verificationStatus) {
//       case 'pending':
//         return 'Your prescription is in queue for verification';
//       case 'processing':
//         return 'AI is extracting medicines from your prescription';
//       case 'verified':
//         return 'Prescription verified. Review medicines below';
//       case 'rejected':
//         return 'Prescription could not be processed. Please upload a clearer image';
//       default:
//         return 'Status unknown';
//     }
//   }

//   Widget _buildExtractedMedicines() {
//     if (_extractedMedicines.isEmpty) {
//       return Card(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Icon(Icons.medication, size: 48, color: Colors.grey[400]),
//               const SizedBox(height: 16),
//               const Text(
//                 'No medicines extracted',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'AI could not extract medicines from this prescription',
//                 style: TextStyle(color: Colors.grey[600]),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Extracted Medicines',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.teal,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: _extractedMedicines.length,
//               itemBuilder: (context, index) {
//                 final medicine = _extractedMedicines[index];
//                 final isSelected = _selectedMedicines.contains(medicine);
                
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: isSelected ? Colors.teal : Colors.grey.shade300,
//                       width: isSelected ? 2 : 1,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: CheckboxListTile(
//                     value: isSelected,
//                     onChanged: (bool? value) {
//                       setState(() {
//                         if (value == true) {
//                           _selectedMedicines.add(medicine);
//                         } else {
//                           _selectedMedicines.remove(medicine);
//                         }
//                       });
//                     },
//                     title: Text(
//                       medicine.name,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('${medicine.strength} • ${medicine.form}'),
//                         Text('₹${medicine.price.toStringAsFixed(2)}'),
//                         if (isSelected) ...[
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               const Text('Quantity: '),
//                               IconButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     if (_quantities[medicine.id]! > 1) {
//                                       _quantities[medicine.id] = _quantities[medicine.id]! - 1;
//                                     }
//                                   });
//                                 },
//                                 icon: const Icon(Icons.remove),
//                                 iconSize: 20,
//                               ),
//                               Text('${_quantities[medicine.id]}'),
//                               IconButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     _quantities[medicine.id] = _quantities[medicine.id]! + 1;
//                                   });
//                                 },
//                                 icon: const Icon(Icons.add),
//                                 iconSize: 20,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ],
//                     ),
//                     activeColor: Colors.teal,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomBar() {
//     if (_verificationStatus != 'verified' && _verificationStatus != 'processed') {
//       return const SizedBox.shrink();
//     }

//     final totalAmount = _selectedMedicines.fold<double>(
//       0.0,
//       (sum, medicine) => sum + (medicine.price * (_quantities[medicine.id] ?? 1)),
//     );

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withValues(alpha: 0.3),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${_selectedMedicines.length} items selected',
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//                 Text(
//                   '₹${totalAmount.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.teal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _isProcessing ? null : _proceedToOrder,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: _isProcessing
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text('Proceed to Order'),
//           ),
//         ],
//       ),
//     );
//   }
// }
