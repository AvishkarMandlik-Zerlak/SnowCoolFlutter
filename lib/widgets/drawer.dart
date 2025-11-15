import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/addinventoryscreen.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/screens/create_customer_screen.dart';
import 'package:snow_trading_cool/screens/login_screen.dart';
import 'package:snow_trading_cool/screens/passbook.dart';
import 'package:snow_trading_cool/screens/profile_screen.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/screens/view_customer_screen.dart';
import 'package:snow_trading_cool/services/logout_api.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

class ShowSideMenu extends StatefulWidget {
  const ShowSideMenu({super.key});

  @override
  State<ShowSideMenu> createState() => _ShowSideMenuState();
}

class _ShowSideMenuState extends State<ShowSideMenu> {
  final LogoutApi _logoutApi = LogoutApi();

  bool _isLoggingOut = false;
  bool _showCustomerSubMenu = false;
  bool _showChallanSubMenu = false;
  String _userRole = 'Employee';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    print('User Role Loaded: $_userRole');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'ADMIN';
    bool canManageSettings = TokenManager().canManageSettings;
    bool canManagePassbook = TokenManager().canManagePassbook;
    bool canManageCustomers = TokenManager().canCreateCustomers;
    bool canManageChallans = TokenManager().canManageChallans;
    bool canManageGoodsItems = TokenManager().canManageGoodsItems;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final panelWidth = isMobile
        ? screenWidth * 0.7
        : (screenWidth * 0.5).clamp(260.0, screenWidth);

    return AnimatedBuilder(
      animation: ModalRoute.of(context)!.animation!,
      builder: (context, child) {
        final animation = ModalRoute.of(context)!.animation!;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(
                16,
              ), // Radius for professional look
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: SafeArea(
                  child: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      // final isAdmin = _userRole == 'ADMIN';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Professional Header with Logo centered & Name below left-aligned (responsive)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                // topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Logo centered at top
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 20 : 30,
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo.jpg',
                                      width: isMobile ? 50 : 80,
                                      height: isMobile ? 50 : 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: isMobile ? 50 : 80,
                                                height: isMobile ? 50 : 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.business,
                                                  color: Colors.grey[600],
                                                  size: isMobile ? 30 : 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Name below, left-aligned
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SnowCool Trading Co.',
                                        style: GoogleFonts.inter(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rest of menu items (same as original, but with better padding)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (canManageChallans || isAdmin)
                                    ListTile(
                                      title: const Text('Challan'),
                                      trailing: Icon(
                                        _showChallanSubMenu
                                            ? Icons.remove
                                            : Icons.add,
                                        color: const Color(0xFF008CC0),
                                      ),
                                      onTap: () => setStateDialog(
                                        () => _showChallanSubMenu =
                                            !_showChallanSubMenu,
                                      ),
                                    ),
                                  if (_showChallanSubMenu) ...[
                                    _subMenu('Create Challan', () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ChallanScreen(),
                                        ),
                                      );
                                    }),
                                    _subMenu('View Challan', () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ViewChallanScreen(),
                                        ),
                                      );
                                    }),
                                  ],
                                  const Divider(height: 1),
                                  if (canManageCustomers || isAdmin)
                                    ListTile(
                                      title: const Text('Customers'),
                                      trailing: Icon(
                                        _showCustomerSubMenu
                                            ? Icons.remove
                                            : Icons.add,
                                        color: const Color(0xFF008CC0),
                                      ),
                                      onTap: () => setStateDialog(
                                        () => _showCustomerSubMenu =
                                            !_showCustomerSubMenu,
                                      ),
                                    ),
                                  if (_showCustomerSubMenu) ...[
                                    _subMenu('Create Customer', () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateCustomerScreen(),
                                        ),
                                      );
                                    }),
                                    _subMenu('View Customers', () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ViewCustomerScreenFixed(),
                                        ),
                                      );
                                    }),
                                  ],
                                  const Divider(height: 1),
                                  if (canManagePassbook || isAdmin)
                                    ListTile(
                                      title: const Text('View Passbook'),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF008CC0),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PassBookScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  const Divider(height: 1),
                                  if (canManageGoodsItems || isAdmin)
                                    ListTile(
                                      tileColor: Colors.white,
                                      // enabled: isAdmin,
                                      title: Text('Items/Goods'),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF008CC0),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const Addinventoryscreen(),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Divider(height: 1),
                          // Bottom Row - Responsive: Full Settings ListTile in tablet, Icon only in mobile
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                // Logout takes most space
                                Expanded(
                                  child: ListTile(
                                    title: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    leading: const Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                    ),
                                    onTap: () {
                                      // Navigator.pop(context);
                                      _showLogoutConfirmation(context);
                                    },
                                  ),
                                ),
                                // Settings - conditional based on mode
                                if (canManageSettings || isAdmin)
                                  if (isMobile)
                                    // Mobile: Only icon
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings,
                                        size: 28,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    // Tablet: Full ListTile with text
                                    Expanded(
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.settings,
                                          color: Colors.black,
                                        ),
                                        title: const Text('Settings'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ProfileScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _isLoggingOut = true);
    try {
      String? token = TokenManager().getToken();
      log(token.toString());

      if (token != null && token != 'demo-token-local-only') {
        await _logoutApi.logout(token); // Remote logout
      } else {
        _logoutApi.logoutLocally(); // Local logout (no await if sync)
      }

      TokenManager().clearToken();

      if (mounted) {
        showSuccessToast(context, "Logged out successfully");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Even on error, clear token and go to login
      TokenManager().clearToken();
      if (mounted) {
        showWarningToast(context, "Logged out locally due to error");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted && Navigator.canPop(context) == false) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _showLogoutConfirmation(BuildContext parentcontext) {
    showDialog(
      context: parentcontext,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(parentcontext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoggingOut
                ? null
                : () {
                    Navigator.pop(parentcontext);
                    _handleLogout(parentcontext);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008CC0),
            ),
            child: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _subMenu(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        bottom: 4,
      ), // Indent for submenu, professional spacing
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        ),
        onTap: onTap,
        dense: true, // Compact for pro look
      ),
    );
  }
}
