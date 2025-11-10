import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/setting_screen.dart';
import 'package:snow_trading_cool/screens/user_create_screen.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  final ProfileApi _profileApi = ProfileApi();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {

      print('ProfileScreen: Loading profile for user id=${TokenManager().getId()}');    
      final response = await _profileApi.getProfile(TokenManager().getId());


      if (response.success && response.data != null) {
        setState(() {
          _profileData = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          showWarningToast(context, 'Profile not Found');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showWarningToast(context, "Using demo user data due to error: $e");
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isEditing = !_isEditing);
    if (!_isEditing) {
      showSuccessToast(context, "Profile updated successfully!");
    }
  }

  void _navigateToUserCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCreateScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileApplicationSettingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToUserCreate,
            tooltip: 'Create User',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileField('Full Name', _profileData['name'] ?? '', Icons.person),
                const SizedBox(height: 16),
                _buildProfileField('Email', _profileData['email'] ?? '', Icons.email),
                const SizedBox(height: 16),
                _buildProfileField('Phone', _profileData['phone'] ?? '', Icons.phone),
                const SizedBox(height: 16),
                _buildProfileField('Address', _profileData['address'] ?? '', Icons.location_on, isMultiLine: true),
                const SizedBox(height: 16),
                _buildProfileField('Company', _profileData['company'] ?? '', Icons.business),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon, {bool isMultiLine = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextFormField(
                    initialValue: value,
                    maxLines: isMultiLine ? 3 : 1,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                    onChanged: (newValue) {
                      _profileData[label.toLowerCase()] = newValue;
                    },
                  )
                : Text(
                    value.isEmpty ? 'Not set' : value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: value.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
