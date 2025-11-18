import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/create_customer_screen.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/screens/passbook.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import 'package:snow_trading_cool/widgets/loader.dart';

class ViewCustomerScreenFixed extends StatefulWidget {
  const ViewCustomerScreenFixed({super.key});

  @override
  State<ViewCustomerScreenFixed> createState() =>
      _ViewCustomerScreenFixedState();
}

class _ViewCustomerScreenFixedState extends State<ViewCustomerScreenFixed> {
  final CustomerApi _api = CustomerApi();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _customers = [];
  String _searchQuery = '';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 🔹 Fetch paginated customers from backend
  Future<void> _fetchCustomers({int page = 0}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getCustomersPage(
        page: page,
        size: _rowsPerPage,
      );
      final customers = response.content;

      setState(() {
        _customers = customers
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'contactNumber': c.contactNumber,
                'email': c.email ?? '',
                'address': c.address ?? '',
              },
            )
            .toList();

        _currentPage = response.number;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorToast(context, "Failed to load customers");
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((customer) {
      final name = (customer['name'] ?? '').toString().toLowerCase();
      final contact = (customer['contactNumber'] ?? '')
          .toString()
          .toLowerCase();
      final email = (customer['email'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          contact.contains(query) ||
          email.contains(query);
    }).toList();
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    final name = TextEditingController(text: customer['name'] ?? '');
    final mobile = TextEditingController(text: customer['contactNumber'] ?? '');
    final email = TextEditingController(text: customer['email'] ?? '');
    final address = TextEditingController(text: customer['address'] ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: mobile,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != true) return;

    try {
      final resp = await _api.updateCustomer(
        customer['id'],
        name.text,
        mobile.text,
        email.text,
        address.text,
      );
      if (resp.success) {
        await _fetchCustomers(page: _currentPage);
        if (mounted)
          showSuccessToast(context, "Customer updated successfully!");
      } else {
        if (mounted) showErrorToast(context, 'Update failed: ${resp.message}');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, 'Error: $e');
    }
  }

  Future<void> _deleteCustomer(int customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final resp = await _api.deleteCustomer(customerId);
      if (resp.success) {
        await _fetchCustomers(page: _currentPage);
        if (mounted)
          showSuccessToast(context, "Customer deleted successfully!");
      } else {
        if (mounted) showErrorToast(context, 'Delete failed: ${resp.message}');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, 'Error: $e');
    }
  }

  String _userRole = 'Employee';

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'ADMIN';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Customers',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leadingWidth: 96,
        leading: Row(
          children: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.menu), // color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),

            if (isAdmin)
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                icon: Icon(Icons.home),
              ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateCustomerScreen(),
                ),
              );
            },
            child: Container(
              height: 30,
              // width: 110,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // color: const Color.fromRGBO(0, 140, 192, 1),
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  "Create Customer",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      drawer: ShowSideMenu(),
      body: RefreshIndicator(
        onRefresh: () => _fetchCustomers(page: _currentPage),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // 🔍 Search box
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: isMobile ? screenWidth - 32 : 250,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search),
                                      labelText:
                                          'Search by name, contact, or email',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    height: 50,
                                    color: Colors.grey.shade50,
                                    child: const Center(
                                      child: Text(
                                        'Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color.fromRGBO(0, 140, 192, 1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ..._filteredData.map((row) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PassBookScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(row['name'] ?? 'N/A'),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),

                              // Data columns
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 700,
                                    child: Column(
                                      children: [
                                        // Header
                                        Container(
                                          height: 50,
                                          color: Colors.grey.shade50,
                                          child: const Row(
                                            children: [
                                              SizedBox(
                                                width: 150,
                                                child: Center(
                                                  child: Text(
                                                    'Mobile Number',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        0,
                                                        140,
                                                        192,
                                                        1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 200,
                                                child: Center(
                                                  child: Text(
                                                    'Email',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        0,
                                                        140,
                                                        192,
                                                        1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 200,
                                                child: Center(
                                                  child: Text(
                                                    'Address',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        0,
                                                        140,
                                                        192,
                                                        1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 150,
                                                child: Center(
                                                  child: Text(
                                                    'Actions',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                        0,
                                                        140,
                                                        192,
                                                        1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Rows
                                        ..._filteredData.map((row) {
                                          return Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 150,
                                                  child: Center(
                                                    child: Text(
                                                      row['contactNumber'] ??
                                                          'N/A',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Center(
                                                    child: Text(
                                                      row['email'] ?? 'N/A',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Center(
                                                    child: Text(
                                                      row['address'] ?? 'N/A',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 150,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          CupertinoIcons
                                                              .square_pencil_fill,
                                                          color: Color.fromRGBO(
                                                            0,
                                                            140,
                                                            192,
                                                            1,
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _editCustomer(row),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          CupertinoIcons
                                                              .bin_xmark_fill,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          final id =
                                                              int.tryParse(
                                                                row['id']
                                                                    .toString(),
                                                              ) ??
                                                              0;
                                                          _deleteCustomer(id);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pagination footer (no extra space below)
                  Container(
                    color: const Color(0xFFB3E0F2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: _currentPage > 0
                              ? () => _fetchCustomers(page: _currentPage - 1)
                              : null,
                        ),
                        Text('Page ${_currentPage + 1} of $_totalPages'),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: _currentPage < _totalPages - 1
                              ? () => _fetchCustomers(page: _currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading) customLoader(),
          ],
        ),
      ),
    );
  }
}
