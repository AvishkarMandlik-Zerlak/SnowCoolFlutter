import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/setting_screen.dart';
import 'package:snow_trading_cool/screens/user_create_screen.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/profile_api.dart';
import '../services/application_settings_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _originalProfileData = {};
  final ProfileApi _profileApi = ProfileApi();
  ApplicationSettingsDTO? _appSettings;
  ImageProvider? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppSettingsLogo();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final int id = TokenManager().getId() ?? ProfileApi.defaultProfileId;
      print('ProfileScreen: Loading profile for user id=$id');
      final response = await _profileApi.getProfile(id);
      if (response.success && response.data != null) {
        // Map backend fields to UI fields
        final data = response.data!;
        setState(() {
          _profileData = {
            'name': data['name'] ?? data['businessName'] ?? '',
            'email': data['email'] ?? data['emailId'] ?? '',
            'phone': data['phone'] ?? data['mobileNumber'] ?? '',
            'address': data['address'] ?? '',
            'company': data['company'] ?? data['businessName'] ?? '',
          };
          _originalProfileData = Map<String, dynamic>.from(_profileData);
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

  Future<void> _loadAppSettingsLogo() async {
    try {
      final token = TokenManager().getToken();
      if (token == null || token.isEmpty) return;
      final api = ApplicationSettingsApi(token: token);
      final settings = await api.getSettings();
      if (!mounted) return;
      if (settings?.logoBase64 != null && settings!.logoBase64!.isNotEmpty) {
        final bytes = base64Decode(settings.logoBase64!);
        setState(() {
          _appSettings = settings;
          _logoImage = MemoryImage(bytes);
        });
      }
    } catch (e) {
      // Silently ignore; fallback icon will show
    }
  }

  Future<void> _updateProfile() async {
    if (_isEditing) {
      // Check for valid token before updating
      final token = TokenManager().getToken();
      if (token == null || token.isEmpty) {
        showWarningToast(
          context,
          "You are not logged in. Please log in again.",
        );
        return;
      }
      // Save profile to backend
      final int id = TokenManager().getId() ?? ProfileApi.defaultProfileId;
      final response = await _profileApi.updateProfile(
        id,
        _profileData,
        oldProfile: _originalProfileData,
      );
      if (response.success) {
        showSuccessToast(context, "Profile updated successfully!");
        // Optionally reload profile from backend
        await _loadProfile();
      } else {
        showWarningToast(
          context,
          response.message ?? "Failed to update profile",
        );
      }
    }
    setState(() => _isEditing = !_isEditing);
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
      MaterialPageRoute(
        builder: (context) => const ProfileApplicationSettingScreen(),
      ),
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
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _logoImage,
                    child: _logoImage == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileField(
                  'Business Name',
                  _profileData['name'] ?? '',
                  Icons.person,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  'Email',
                  _profileData['email'] ?? '',
                  Icons.email,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  'Phone',
                  _profileData['phone'] ?? '',
                  Icons.phone,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  'Address',
                  _profileData['address'] ?? '',
                  Icons.location_on,
                  isMultiLine: true,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String value,
    IconData icon, {
    bool isMultiLine = false,
  }) {
    String _keyForLabel(String l) {
      switch (l) {
        case 'Business Name':
          return 'name';
        case 'Email':
          return 'email';
        case 'Phone':
          return 'phone';
        case 'Address':
          return 'address';
        default:
          return l.trim().toLowerCase();
      }
    }

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
                Icon(
                  icon,
                  color: const Color.fromRGBO(0, 140, 192, 1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextFormField(
                    initialValue: value,
                    maxLines: isMultiLine ? 3 : 1,
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    onChanged: (newValue) {
                      _profileData[_keyForLabel(label)] = newValue;
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
