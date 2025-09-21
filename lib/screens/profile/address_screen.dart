import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pharmacy/services/auth_service.dart';
import '../../models/address.dart';
import '../../services/api_service.dart';

// Extension to capitalize the first letter of a string
extension StringCasingExtension on String {
  String capitalize() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> addresses = [];
  bool isLoading = true;
  final ApiService _apiService = ApiService();
  final AuthService authService = AuthService();

  String? _currentUserId;
  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndLoadAddresses();
  }

  Future<void> _fetchCurrentUserAndLoadAddresses() async {
    final User = await authService.getCurrentUser();

    if (User != null && User.containsKey('id')) {
      _currentUserId = User['id'] as String;
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    if (_currentUserId == null) {
      _showError("No user ID found ");
    }

    try {
      setState(() => isLoading = true);
      final response = await _apiService.getAddresses();

      if (response["success"]) {
        final userAddresses = (response['data'] as List)
            .where(
              (addressJson) => addressJson['user'] as String == _currentUserId,
            )
            .map((json) => Address.fromJson(json))
            .toList();

        setState(() {
          addresses = userAddresses;
        });
      } else {
        _showError(response['error'] ?? "Failed to load addresses ");
      }
    } catch (error) {
      _showError("error loading addresses $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAddressDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : addresses.isEmpty
          ? _buildEmptyState()
          : _buildAddressList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No addresses found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first address to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(
                address.type == 'home'
                    ? Icons.home
                    : address.type == 'work'
                    ? Icons.work
                    : Icons.location_on,
                color: Colors.white,
              ),
            ),
            title: Text(
              address.type.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(address.fullAddress),
                if (address.landmark != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Landmark: ${address.landmark}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${address.city}, ${address.state} - ${address.pincode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditAddressDialog(address);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(address);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAddressDialog() {
    _showAddressDialog(null);
  }

  void _showEditAddressDialog(Address address) {
    _showAddressDialog(address);
  }

  void _showAddressDialog(Address? existingAddress) {
    final isEditing = existingAddress != null;
    final formKey = GlobalKey<FormState>();

    String type = existingAddress?.type ?? 'home';
    String street = existingAddress?.street ?? '';
    String city = existingAddress?.city ?? '';
    String state = existingAddress?.state ?? '';
    String pincode = existingAddress?.pincode ?? '';
    String? landmark = existingAddress?.landmark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Address Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => type = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: street,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                  onSaved: (value) => street = value!,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: city,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Required' : null,
                        onSaved: (value) => city = value!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: state,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Required' : null,
                        onSaved: (value) => state = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: pincode,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Required';
                    if (value!.length != 6) return 'Invalid pincode';
                    return null;
                  },
                  onSaved: (value) => pincode = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: landmark,
                  decoration: const InputDecoration(
                    labelText: 'Landmark (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) =>
                      landmark = value?.isEmpty == true ? null : value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);

                final addressData = {
                  'address_type': type
                      .capitalize(), // Changed field name and capitalized
                  'address_line1': street, // Changed field name
                  'city': city,
                  'state': state,
                  'pincode': pincode,
                  'landmark': landmark,
                  'is_default': false, // Added default value
                  'address_line2': '', // Added empty string for optional field
                };

                if (isEditing) {
                  await _updateAddress(existingAddress.id, addressData);
                } else {
                  await _addAddress(addressData);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await _apiService.addAddress(addressData);
      if (response['success']) {
        _showSuccess('Address added successfully');
        _loadAddresses();
      } else {
        _showError(response['error'] ?? 'Failed to add address');
      }
    } catch (e) {
      _showError('Error adding address: $e');
    }
  }

  Future<void> _updateAddress(int id, Map<String, dynamic> addressData) async {
    try {
      final response = await _apiService.updateAddress(id, addressData);
      if (response['success']) {
        _showSuccess('Address updated successfully');
        _loadAddresses();
      } else {
        _showError(response['error'] ?? 'Failed to update address');
      }
    } catch (e) {
      _showError('Error updating address: $e');
    }
  }

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
          'Are you sure you want to delete this ${address.type} address?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAddress(address.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(int id) async {
    try {
      final response = await _apiService.deleteAddress(id);
      if (response['success']) {
        _showSuccess('Address deleted successfully');
        _loadAddresses();
      } else {
        _showError(response['error'] ?? 'Failed to delete address');
      }
    } catch (e) {
      _showError('Error deleting address: $e');
    }
  }
}
