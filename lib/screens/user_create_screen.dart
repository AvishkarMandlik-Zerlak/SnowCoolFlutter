import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../models/user_model.dart';
import '../services/user_api.dart';

class UserCreateScreen extends StatefulWidget {
  final User? user;
  const UserCreateScreen({super.key, this.user});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Employee';
  bool _isLoading = false;
  bool _active = true;
  bool _canCreateCustomer = false;
  bool _canManageGoodsItems = false;
  bool _canManageChallans = false;
  bool _canManageProfiles = false;
  bool _canManageSettings = false;
  bool _canManagePassbook = false; // ← NEW FIELD
  bool _showPassword = false;

  final UserApi _userApi = UserApi();
  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final user = widget.user!;
      _usernameController.text = user.username;
      _selectedRole = ['Employee', 'Admin'].contains(user.role)
          ? user.role
          : 'Employee';
      _active = user.active;
      _canCreateCustomer = user.canCreateCustomer ?? false;
      _canManageGoodsItems = user.canManageGoods ?? false;
      _canManageChallans = user.canManageChallans ?? false;
      _canManageProfiles = user.canManageProfiles ?? false;
      _canManageSettings = user.canManageSettings ?? false;
      _canManagePassbook = user.canManagePassbook ?? false; // ← NEW
      _passwordController.clear();
    }
  }

  Future<void> _submitUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await _userApi.createOrUpdateUser(
        id: _isEditing ? widget.user!.id as int? : null,
        username: _usernameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? '___SKIP_PASSWORD___'
            : _passwordController.text.trim(),
        role: _selectedRole,
        active: _active,
        canCreateCustomer: _canCreateCustomer,
        canManageGoodsItems: _canManageGoodsItems,
        canManageChallans: _canManageChallans,
        canManageProfiles: _canManageProfiles,
        canManageSettings: _canManageSettings,
        canManagePassbook: _canManagePassbook, // ← NEW
      );
      if (response.success && mounted) {
        showSuccessToast(
          context,
          _isEditing ? 'User updated successfully!' : 'User created successfully!',
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        showErrorToast(context, "Error: ${response.message}");
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, "Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        title: Text(
          _isEditing ? 'Edit User' : 'Create User',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: 8,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Update user details'
                          : 'Add a new user to the system',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Username',
                      _usernameController,
                      Icons.person,
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildRoleDropdown(),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      'Active',
                      _active,
                      (v) => setState(() => _active = v),
                    ),
                    _buildPermissionRow(
                      'Can Create Customer',
                      _canCreateCustomer,
                      (v) => setState(() => _canCreateCustomer = v),
                    ),
                    _buildPermissionRow(
                      'Can Manage Goods',
                      _canManageGoodsItems,
                      (v) => setState(() => _canManageGoodsItems = v),
                    ),
                    _buildPermissionRow(
                      'Can Manage Challans',
                      _canManageChallans,
                      (v) => setState(() => _canManageChallans = v),
                    ),
                    _buildPermissionRow(
                      'Can Manage Profiles',
                      _canManageProfiles,
                      (v) => setState(() => _canManageProfiles = v),
                    ),
                    _buildPermissionRow(
                      'Can Manage Settings',
                      _canManageSettings,
                      (v) => setState(() => _canManageSettings = v),
                    ),
                    _buildPermissionRow(
                      'Can Manage Passbook',
                      _canManagePassbook,
                      (v) => setState(() => _canManagePassbook = v),
                    ), // ← NEW ROW
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update User' : 'Create User',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/oxygen cylinder.json',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isEditing ? "Updating User..." : "Creating User...",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please wait",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Reusable text field
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isRequired, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Password field
  Widget _buildPasswordField() {
    final hintText = _isEditing ? 'Leave blank to keep current password' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.lock, color: Color.fromRGBO(0, 140, 192, 1), size: 16),
            SizedBox(width: 4),
            Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text('*', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                size: 18,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (value) {
            if (!_isEditing && (value == null || value.isEmpty)) {
              return 'Please enter password';
            }
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      items: const [
        DropdownMenuItem(value: 'Employee', child: Text('Employee')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
      ],
      onChanged: (value) => setState(() => _selectedRole = value ?? 'Employee'),
    );
  }

  // Helper for permission toggle row
  Widget _buildPermissionRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(!value),
            icon: Icon(
              value ? Icons.toggle_on : Icons.toggle_off,
              color: value ? const Color.fromRGBO(0, 140, 192, 1) : Colors.grey,
              size: 60,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}