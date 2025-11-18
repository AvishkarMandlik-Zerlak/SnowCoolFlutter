import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/customer_api.dart';
import 'view_customer_screen.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final depositOpeningBalanceController = TextEditingController();
  bool _isLoading = false;
  final CustomerApi _api = CustomerApi();
  String? _selectedType = 'Daily';

  // Local controllers/state for each row
  final TextEditingController qtyController = TextEditingController();
  String? selectedSign = '+'; // default +

  // Add this map to store sign and qty for each goods
  final Map<String, String> _goodsSignMap = {}; // goods.id → "+" or "-"
  final Map<String, String> _goodsQtyMap = {}; // goods.id → "10"
  final Map<String, TextEditingController> _qtyControllers = {};

  List<GoodsDTO> allGoods = [];
  bool _goodsLoading = true;
  final List<Map<String, dynamic>> _productEntries = [];
  // List<GoodsDTO> goods = [];

  bool challanTypeSelected = true;

  // Error messages state
  String? _nameError;
  String? _mobileError;
  String? _emailError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    _fetchGoods();
  }

  @override
  void dispose() {
    depositOpeningBalanceController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _qtyControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // FETCH GOODS FROM API
  Future<void> _fetchGoods() async {
    try {
      setState(() => _goodsLoading = true);
      // Replace with your actual API call
      final List<GoodsDTO> fetchedGoods = await GoodsApi().getAllGoods();

      setState(() {
        allGoods = fetchedGoods;
        _goodsLoading = false;

        // Initialize defaults for all goods
        for (var goods in fetchedGoods) {
          final id = goods.id.toString(); // assuming GoodsDTO has String/int id
          _goodsSignMap[id] ??= '+';
          _goodsQtyMap[id] ??= '';
          _qtyControllers[id] ??= TextEditingController();
        }
      });
    } catch (e) {
      showErrorToast(context, 'Failed to fetch goods: $e');
      setState(() => _goodsLoading = false);
    }
  }

  // Mobile validator
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    final cleaned = value.trim();
    if (cleaned.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[5-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile must start with 5, 6, 7, 8, or 9';
    }
    return null;
  }

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final email = value.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Auto-convert email to lowercase
  void _onEmailChanged(String value) {
    final lower = value.toLowerCase();
    if (value != lower) {
      _emailController.value = TextEditingValue(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
    }
    _updateEmailError(lower);
  }

  void _updateNameError(String value) {
    setState(() {
      _nameError = value.trim().isEmpty ? 'Please enter customer name' : null;
    });
  }

  void _updateMobileError(String value) {
    setState(() {
      _mobileError = _validateMobile(value);
    });
  }

  void _updateEmailError(String value) {
    setState(() {
      _emailError = _validateEmail(value);
    });
  }

  void _updateAddressError(String value) {
    setState(() {
      _addressError = value.trim().isEmpty ? 'Please enter address' : null;
    });
  }

  bool _isFormValid() {
    return _nameError == null &&
        _mobileError == null &&
        _emailError == null &&
        _addressError == null &&
        _nameController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  Future<void> _submitCustomer() async {
    // Reset errors first
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter customer name'
          : null;
      _mobileError = _validateMobile(_mobileController.text);
      _emailError = _validateEmail(_emailController.text);
      _addressError = _addressController.text.trim().isEmpty
          ? 'Please enter address'
          : null;
    });

    // If any required field has error → stop
    if (_nameError != null ||
        _mobileError != null ||
        _emailError != null ||
        _addressError != null) {
      showErrorToast(context, "Please fix the errors above");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare selected goods (only those with valid qty > 0)
      final List<Map<String, dynamic>> selectedGoods = [];
      for (var goods in allGoods) {
        final String id = goods.id.toString();
        final String qtyText = _goodsQtyMap[id] ?? '';
        final int? qty = int.tryParse(qtyText);

        if (qty != null && qty > 0) {
          selectedGoods.add({
            'goods_id': goods.id,
            'sign': _goodsSignMap[id] ?? '+',
            'quantity': qty,
          });
        }
      }

      // Prepare deposit (optional)
      final double? deposit = double.tryParse(
        depositOpeningBalanceController.text.trim(),
      );
      final double? depositAmount = (deposit == null || deposit == 0)
          ? null
          : deposit;

      // Reminder type (optional, but you have default 'Daily')
      final String reminderType = _selectedType ?? 'Daily';

      // Call API
      final response = await _api.createCustomer(
        name: _nameController.text.trim(),
        contactNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        reminder: reminderType,
        deposite: depositAmount,
        items: selectedGoods.isEmpty ? null : selectedGoods,
      );

      if (!mounted) return;

      if (response.success == true) {
        showSuccessToast(context, "Customer created successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ViewCustomerScreenFixed()),
        );
      } else {
        showErrorToast(
          context,
          response.message ?? "Failed to create customer",
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorToast(context, "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGoodsSelectionTable() {
    if (_goodsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allGoods.isEmpty) {
      return const Center(child: Text("No goods available"));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(150),
            columnWidths: const {
              0: FixedColumnWidth(150),
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(120),
            },
            border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(238, 238, 238, 1),
                ),
                children: [
                  _headerCell("Product"),
                  _headerCell("+/-"),
                  _headerCell("Qty"),
                ],
              ),

              // goods item
              ...allGoods.map((goods) {
                final String goodsId = goods.id
                    .toString();

                return TableRow(
                  decoration: BoxDecoration(
                    color: allGoods.indexOf(goods) % 2 == 0
                        ? Colors.white
                        : Colors.grey.shade50,
                  ),
                  children: [
                    // Product Name
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      child: Text(
                        goods.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // +/- Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _goodsSignMap[goodsId],
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: "+", child: Text("+")),
                              DropdownMenuItem(value: "-", child: Text("-")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _goodsSignMap[goodsId] = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    // Quantity Field
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _qtyControllers[goodsId],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "0",
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          errorText:
                              _qtyControllers[goodsId]!.text.isNotEmpty &&
                                  int.tryParse(
                                        _qtyControllers[goodsId]!.text,
                                      ) ==
                                      0
                              ? "Enter valid qty"
                              : null,
                          errorStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _goodsQtyMap[goodsId] = value;
                          });
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          'Create Customer',
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
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a new customer to the system',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                label: 'Customer Name',
                controller: _nameController,
                icon: Icons.person,
                errorText: _nameError,
                onChanged: _updateNameError,
              ),
              const SizedBox(height: 16),

              // Mobile Field
              _buildTextField(
                label: 'Mobile',
                controller: _mobileController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                errorText: _mobileError,
                onChanged: _updateMobileError,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              //set reminder
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_alarm,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Set Reminder",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: isMobile
                          ? screenWidth * 0.4
                          : 200, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            hint: const Text('Select Type'),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(fontSize: 14),
                            items: ['Daily', 'Weekly', 'Monthly']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Email Field
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: _onEmailChanged,
              ),
              const SizedBox(height: 16),

              // Address Field
              _buildTextField(
                label: 'Address',
                controller: _addressController,
                icon: Icons.location_on,
                isMultiLine: true,
                errorText: _addressError,
                onChanged: _updateAddressError,
              ),
              const SizedBox(height: 16),

              // Deposite opening balance
              _buildTextField(
                label: 'Deposit Opening Balance',
                controller: depositOpeningBalanceController,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                compulsary: false,
              ),
              const SizedBox(height: 16),

              // Goods Selection Table
              _buildGoodsSelectionTable(),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Create Customer',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 18,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool isMultiLine = false,
    String? errorText,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    bool compulsary = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            if (compulsary)
              Text(
                '*',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
              keyboardType ??
              (isMultiLine ? TextInputType.multiline : TextInputType.text),
          maxLines: isMultiLine ? 3 : 1,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : const Color.fromRGBO(0, 140, 192, 1),
              ),
            ),
            errorText: null, // We show error below manually
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
        // Dynamic Error Message with Animation
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: AnimatedOpacity(
              opacity: errorText.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (errorText != null) const SizedBox(height: 8),
      ],
    );
  }
}
