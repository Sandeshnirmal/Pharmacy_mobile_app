import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/auth_service.dart';
import 'models/user_profile_model.dart';
import 'EditProfileScreen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _userProfile = UserProfile.fromJson(userData);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading profile: $e',
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
        title: const Text('Profile Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.teal),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userProfile: _userProfile!),
                  ),
                );
                if (result == true) {
                  _loadUserProfile(); // Reload profile after edit
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
          : _userProfile == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load profile',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Personal Information
          _buildSection(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Full Name', _userProfile!.fullName),
              _buildInfoRow('Email', _userProfile!.email),
              _buildInfoRow('Phone', _userProfile!.phone ?? 'Not provided'),
              _buildInfoRow('Date of Birth', _userProfile!.dateOfBirth ?? 'Not provided'),
              _buildInfoRow('Gender', _userProfile!.gender ?? 'Not provided'),
              _buildInfoRow('Blood Group', _userProfile!.bloodGroup ?? 'Not provided'),
            ],
          ),

          const SizedBox(height: 16),

          // Address Information
          _buildSection(
            title: 'Address Information',
            icon: Icons.location_on_outlined,
            children: [
              _buildInfoRow('Address', _userProfile!.address ?? 'Not provided'),
              _buildInfoRow('City', _userProfile!.city ?? 'Not provided'),
              _buildInfoRow('State', _userProfile!.state ?? 'Not provided'),
              _buildInfoRow('PIN Code', _userProfile!.pincode ?? 'Not provided'),
              _buildInfoRow('Country', _userProfile!.country ?? 'Not provided'),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Contact
          _buildSection(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            children: [
              _buildInfoRow('Contact Name', _userProfile!.emergencyContactName ?? 'Not provided'),
              _buildInfoRow('Contact Number', _userProfile!.emergencyContact ?? 'Not provided'),
            ],
          ),

          const SizedBox(height: 16),

          // Medical Information
          _buildSection(
            title: 'Medical Information',
            icon: Icons.medical_information_outlined,
            children: [
              _buildListRow('Allergies', _userProfile!.allergies),
              _buildListRow('Chronic Conditions', _userProfile!.chronicConditions),
              _buildListRow('Current Medications', _userProfile!.currentMedications),
              _buildInfoRow('Insurance Provider', _userProfile!.insuranceProvider ?? 'Not provided'),
              _buildInfoRow('Insurance Number', _userProfile!.insuranceNumber ?? 'Not provided'),
            ],
          ),

          const SizedBox(height: 16),

          // Account Information
          _buildSection(
            title: 'Account Information',
            icon: Icons.account_circle_outlined,
            children: [
              _buildInfoRow('Account Status', _userProfile!.isVerified ? 'Verified' : 'Unverified'),
              _buildInfoRow('Member Since', _formatDate(_userProfile!.createdAt)),
              _buildInfoRow('Last Updated', _formatDate(_userProfile!.updatedAt)),
              _buildInfoRow('Preferred Language', _userProfile!.preferredLanguage),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          // Profile Image
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: _userProfile!.profileImage != null
                    ? NetworkImage(_userProfile!.profileImage!)
                    : null,
                child: _userProfile!.profileImage == null
                    ? Text(
                        _userProfile!.initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      )
                    : null,
              ),
              if (_userProfile!.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile!.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile!.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_userProfile!.age > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Text(
                'Age: ${_userProfile!.age} years',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Text(
                    'None',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
