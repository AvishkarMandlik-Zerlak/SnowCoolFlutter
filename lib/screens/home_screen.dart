import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/profile_screen.dart';
import 'package:snow_trading_cool/screens/view_customer_screen.dart';
import 'package:snow_trading_cool/screens/view_user_screen.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import '../services/application_settings_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final LogoutApi _logoutApi = LogoutApi();
  // bool _isLoggingOut = false;
  // bool _showCustomerSubMenu = false;
  // bool _showChallanSubMenu = false;
  String _userRole = 'Employee';
  ImageProvider? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadAppSettingsLogo();
    bool canManageProfiles = TokenManager().canManageProfiles;
    log("canManageProfiles: ${canManageProfiles.toString()}");
    log("canCreateCustomers: ${TokenManager().canCreateCustomers.toString()}");
    log("canManageChallans: ${TokenManager().canManageChallans.toString()}");
  }

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    print('User Role Loaded: $_userRole');
    setState(() {});
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
          _logoImage = MemoryImage(bytes);
        });
      }
    } catch (_) {
      // Fallback to default avatar if loading fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isAdmin = _userRole == 'ADMIN';

    final double horizontalPadding = isMobile ? 16.0 : 24.0;
    final double cardRadius = 12.0;
    final double titleFontSize = 20.0;
    final double countFontSize = isMobile ? 22.0 : 26.0;
    final double labelFontSize = isMobile ? 14.0 : 16.0;
    final double typeFontSize = isMobile ? 14.0 : 16.0;
    final double orderCountFontSize = isMobile ? 18.0 : 22.0;
    final double orderLabelFontSize = isMobile ? 14.0 : 16.0;
    final double iconSize = isMobile ? 16.0 : 18.0;
    final double verticalGap = isMobile ? 6.0 : 8.0;
    final double sectionGap = isMobile ? 12.0 : 16.0;

    bool canManageProfiles = TokenManager().canManageProfiles;
    bool canCreateCustomers = TokenManager().canCreateCustomers;
    bool canManageChallans = TokenManager().canManageChallans;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        leadingWidth: isMobile ? 44 : 48,
        titleSpacing: isMobile ? 6 : 8,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // leading: Builder(
        //   builder: (_) => IconButton(
        //     icon: Icon(
        //       Icons.menu,
        //       color: Colors.white,
        //       size: isMobile ? 22 : 24,
        //     ),
        //     onPressed: () => ShowSideMenu(context),//_showSideMenu(context),
        //   ),
        // ),
        title: Text(
          'SnowCool Trading CO.',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (canManageProfiles || isAdmin)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 8 : 12),
              child: PopupMenuButton<String>(
                color: Colors.white,
                icon: CircleAvatar(
                  radius: isMobile ? 16 : 18,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _logoImage,
                  child: _logoImage == null
                      ? Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isMobile ? 20 : 22,
                        )
                      : null,
                ),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else if (value == 'view_users') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserViewScreen()),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (canManageProfiles || isAdmin)
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profile'),
                      ),
                    ),
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'view_users',
                      child: ListTile(
                        leading: Icon(Icons.group),
                        title: Text('View Users'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      drawer: ShowSideMenu(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: verticalGap),
            Text(
              'Total Inventory',
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF515151),
                // color: Colors.white,
              ),
            ),
            SizedBox(height: verticalGap),
            Container(
              width: double.infinity,
              // height: isMobile ? 62 : 70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // color: Color.fromRGBO(0, 140, 192, 1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color.fromRGBO(0, 140, 192, 1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '1000',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 20 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(0, 140, 192, 1),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Empty',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.inventory_2_rounded,
                        size: 40,
                        color: Color.fromRGBO(0, 140, 192, 1),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  _buildTypeRow('Small Regular', '2000', typeFontSize),
                  _buildTypeRow('Small Floron', '2000', typeFontSize),
                  _buildTypeRow('Big Regular', '2000', typeFontSize),
                  _buildTypeRow('Big Floron', '2000', typeFontSize),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: sectionGap),
            Text(
              'Customers',
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF515151),
                // color: Colors.white,
              ),
            ),
            SizedBox(height: verticalGap),
            GestureDetector(
              onTap: () {
                setState(() {
                  log(canCreateCustomers.toString());
                  if (canCreateCustomers || isAdmin) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ViewCustomerScreenFixed(),
                      ),
                    );
                  }
                });
              },
              child: Container(
                height: isMobile ? 56 : 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  // color: Color.fromRGBO(0, 140, 192, 1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: Color.fromRGBO(0, 140, 192, 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '1000',
                              style: GoogleFonts.inter(
                                fontSize: countFontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(0, 140, 192, 1),
                              ),
                            ),
                            Text(
                              'Customers',
                              style: GoogleFonts.inter(
                                fontSize: labelFontSize,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color.fromRGBO(0, 140, 192, 1),
                      size: iconSize,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: sectionGap),
            if (canManageChallans || isAdmin)
              Text(
                'Orders/Challans',
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF515151),
                  // color: Colors.white,
                ),
              ),
            SizedBox(height: verticalGap),
            if (canManageChallans || isAdmin)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ViewChallanScreen(type: "received"),
                          ),
                        );
                      },
                      child: _buildOrderCard(
                        '1000',
                        'Received',
                        orderCountFontSize,
                        orderLabelFontSize,
                        cardRadius,
                        isMobile,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ViewChallanScreen(type: "Delivered"),
                          ),
                        );
                      },
                      child: _buildOrderCard(
                        '1000',
                        'Delivered',
                        orderCountFontSize,
                        orderLabelFontSize,
                        cardRadius,
                        isMobile,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRow(String title, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: fontSize + 2,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    String count,
    String label,
    double countSize,
    double labelSize,
    double radius,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 52 : 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        // color: Color.fromRGBO(0, 140, 192, 1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Color.fromRGBO(0, 140, 192, 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.inter(
                      fontSize: countSize,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: labelSize,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            // color: Colors.grey,
            color: Color.fromRGBO(0, 140, 192, 1),
            size: isMobile ? 16 : 18,
          ),
        ],
      ),
    );
  }
}
