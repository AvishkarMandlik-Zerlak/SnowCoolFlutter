import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/services/user_api.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/view_user_api.dart';
import '../models/user_model.dart';
import 'user_create_screen.dart';

class UserViewScreen extends StatefulWidget {
  const UserViewScreen({super.key});

  @override
  State<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends State<UserViewScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  final ViewUserApi _api = ViewUserApi();
  final Map<int, bool> _passwordVisibility = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _api.getUsers();
      setState(() {
        _users = users.isNotEmpty ? users : _getDemoUsers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _users = _getDemoUsers();
        _isLoading = false;
      });
      if (mounted) {
        showWarningToast(context, "Using demo user data due to error: $e");
      }
    }
  }

  List<User> _getDemoUsers() {
    return [
      User(id: 1, username: 'demo_user1', password: 'demo123', role: 'Employee', active: true),
      User(id: 2, username: 'admin_demo', password: 'admin456', role: 'Admin', active: false),
      User(id: 3, username: 'test_emp', password: 'test789', role: 'Employee', active: true),
    ];
  }

  Future<void> _toggleUserStatus(User user, bool newStatus) async {
    try {
      final response = await _api.updateUserStatus(user.id, newStatus);
      if (response.success) {
        if (mounted) {
          setState(() {
            user.active = newStatus;
          });
          showSuccessToast(context, "User status updated successfully!");
        }
      } else {
        if (mounted) {
          showErrorToast(context, "Failed to update user status: ${response.message}");
          setState(() {
            user.active = !newStatus; // Revert on failure
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, "Error updating user status: $e");
        setState(() {
          user.active = !newStatus; // Revert on error
        });
      }
    }
  }

  // Helper for permission toggle row (ultra-compact with IconButton)
  Widget _buildPermissionRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0), // Minimal vertical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11, // Smaller text
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
              size: 60, // Compact size to match photo style
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20, // Small splash for tap feel
          ),
        ],
      ),
    );
  }

  // EDIT: Navigate to UserCreateScreen with user data
  Future<void> _editUser(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreateScreen(user: user),
      ),
    );
    _loadUsers(); // Refresh list after edit
  }

  // DELETE: Safe context handling
  Future<void> _deleteUser(User user) async {
    final BuildContext dialogContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userApi = UserApi();
              try {
                final response = await userApi.deleteUser(user.id);
                if (!dialogContext.mounted) return;

                if (response.success) {
                  setState(() {
                    _users.remove(user);
                  });
                  showSuccessToast(context, "User deleted successfully!");
                } else {
                  showErrorToast(context, "Failed to delete user: ${response.message}");
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                showErrorToast(context, "Error deleting user: $e");
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCreateScreen()),
    ).then((_) => _loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
          'View Users',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          top: 16,
          bottom: 80,
        ),
        child: _users.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return _buildUserCard(user, isMobile);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddUser,
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Add User',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        tooltip: 'Add New User',
      ),
    );
  }

  Widget _buildUserCard(User user, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _editUser(user),
                    tooltip: 'Edit User',
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _deleteUser(user),
                    tooltip: 'Delete User',
                  ),
                ],
              ),
              Expanded(child: _buildUserField('Username', user.username, Icons.person, isMobile)),
              const SizedBox(height: 2),
              Expanded(child: _buildPasswordField(user)),
              const SizedBox(height: 2),
              Expanded(child: _buildUserField('Role', user.role, Icons.admin_panel_settings, isMobile)),
              const SizedBox(height: 4),
              _buildPermissionRow('Active', user.active, (newValue) => _toggleUserStatus(user, newValue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserField(String label, String value, IconData icon, bool isMobile) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 14),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: GoogleFonts.inter(fontSize: 12, color: value.isEmpty ? Colors.grey : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(User user) {
    final bool isVisible = _passwordVisibility[user.id] ?? false;
    final String displayPassword = isVisible ? user.password : '*' * user.password.length;

    return Row(
      children: [
        const Icon(Icons.lock, color: Color.fromRGBO(0, 140, 192, 1), size: 14),
        const SizedBox(width: 3),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _passwordVisibility[user.id] = !isVisible;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayPassword, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(width: 4),
                      Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}