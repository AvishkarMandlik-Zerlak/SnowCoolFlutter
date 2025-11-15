import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:lottie/lottie.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/loader.dart';

class ChallanScreen extends StatefulWidget {
  final Map<String, dynamic>? challanData;

  const ChallanScreen({super.key, this.challanData});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final ChallanApi _api = ChallanApi();
  final CustomerApi _customerApi = CustomerApi();
  final GoodsApi _goodsApi = GoodsApi();

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController locationController =
      TextEditingController(); // Now used as Customer Address
  final TextEditingController transporterController = TextEditingController();
  final TextEditingController vehicleDriverDetailsController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  late final TextEditingController dateController;
  final TextEditingController _emailController = TextEditingController();

  // ---------- Dynamic Product Controllers ----------
  List<GoodsDTO> goods = [];
  bool _goodsLoading = true;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _srNoControllers = {};

  // ---------- State ----------
  bool challanTypeSelected = true;
  int? selectedCustomerId;
  String type = "RECEIVED";
  int? _challanId;

  // FIXED: Using GlobalKey for perfect overlay positioning
  final GlobalKey _customerFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isSearching = false;

  // Inline errors
  String? _vehicleNumberError;
  String? _driverDetailsError;
  String? _mobileNumberError;
  String? _emailError;

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );

    _challanId = _safeParseId(widget.challanData?['id']);

    _loadGoods().then((_) {
      if (_challanId != null) {
        _loadChallanForEdit();
      }
    });
  }

  int? _safeParseId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  Future<void> _loadGoods() async {
    try {
      final list = await _goodsApi.getAllGoods();
      setState(() {
        goods = list;
        _goodsLoading = false;
        for (final g in goods) {
          _qtyControllers[g.name] = TextEditingController();
          _srNoControllers[g.name] = TextEditingController();
        }
      });
    } catch (e) {
      showErrorToast(context, "Failed to load goods: $e");
      setState(() => _goodsLoading = false);
    }
  }

  Future<void> _loadChallanForEdit() async {
    if (_challanId == null) return;
    setState(() => _loading = true);

    try {
      final data = await _api.getChallan(_challanId!);
      if (data == null) throw Exception("Challan not found");

      setState(() {
        selectedCustomerId = data['customerId'] as int?;
        customerNameController.text = data['customerName'] ?? '';
        mobileNumberController.text = data['contactNumber'] ?? '';
        customerEmailController.text =
            (data['customerEmail'] ?? data['email'] ?? '').toLowerCase();
        locationController.text =
            data['customerAddress'] ?? data['siteLocation'] ?? '';

        transporterController.text = data['transporter'] ?? '';
        vehicleNumberController.text = data['vehicleNumber'] ?? '';

        vehicleDriverDetailsController.text =
            '${data['driverName'] ?? ''} - ${data['driverNumber'] ?? ''}'
                .trim()
                .replaceAll(RegExp(r'\s+'), ' ');

        dateController.text = data['date'] ?? dateController.text;
        type = data['challanType'] ?? 'RECEIVED';
        challanTypeSelected = type == 'RECEIVED';

        // Clear previous values
        for (final ctrl in _qtyControllers.values) ctrl.clear();
        for (final ctrl in _srNoControllers.values) ctrl.clear();

        final List<dynamic> items = data['items'] ?? [];
        for (var item in items) {
          final productName = item['name'] as String?;
          final qty = item['qty']?.toString() ?? '';
          final srNo = item['srNo'] as String?;

          if (productName != null && _qtyControllers.containsKey(productName)) {
            _qtyControllers[productName]!.text = qty;
            _srNoControllers[productName]!.text = srNo ?? '';
          }
        }

        _validateVehicleNumber(vehicleNumberController.text);
        _validateDriverDetails(vehicleDriverDetailsController.text);
        _validateMobileNumber(mobileNumberController.text);
        _validateEmail(customerEmailController.text);
      });
    } catch (e) {
      showErrorToast(context, "Failed to load challan: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    showErrorToast(context, message);
  }

  void _onCustomerSearchChanged(String query) async {
    final trimmed = query.trim();
    _removeOverlay();
    if (trimmed.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<CustomerDTO> results = [];

      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        results = await _customerApi.searchCustomers(contactNumber: trimmed);
      } else if (trimmed.contains('@')) {
        results = await _customerApi.searchCustomers(email: trimmed);
      } else {
        results = await _customerApi.searchCustomers(name: trimmed);
      }

      if (!mounted) return;
      _showOverlay(results);
    } catch (e) {
      _showError('Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showOverlay(List<CustomerDTO> results) {
    _removeOverlay();

    final RenderBox? renderBox =
        _customerFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final double width =
        renderBox?.size.width ?? MediaQuery.of(context).size.width * 0.9;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final double top = offset.dy + (renderBox?.size.height ?? 55);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx,
            top: top,
            width: width,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No customers found",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, i) {
                          final c = results[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              c.contactNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              selectCustomer(c);
                              _removeOverlay();
                            },
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void selectCustomer(CustomerDTO customer) {
    setState(() {
      selectedCustomerId = customer.id;
      customerNameController.text = customer.name;
      mobileNumberController.text = customer.contactNumber;
      customerEmailController.text = (customer.email ?? '').toLowerCase();
      locationController.text = customer.address ?? '';
      _validateMobileNumber(customer.contactNumber);
      _validateEmail(customerEmailController.text);
    });
    _removeOverlay();
  }

  void _validateVehicleNumber(String value) {
    final cleaned = value.trim().toUpperCase();
    final p1 = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$');
    final p2 = RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$');

    setState(() {
      if (cleaned.isEmpty) {
        _vehicleNumberError = null;
      } else if (p1.hasMatch(cleaned) || p2.hasMatch(cleaned)) {
        _vehicleNumberError = null;
        if (value != cleaned) {
          vehicleNumberController.text = cleaned;
          vehicleNumberController.selection = TextSelection.fromPosition(
            TextPosition(offset: cleaned.length),
          );
        }
      } else {
        _vehicleNumberError = 'Use format: MH12AB1234 or 22BH1234AA';
      }
    });
  }

  void _validateDriverDetails(String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _driverDetailsError = null;
        return;
      }
      if (!trimmed.contains('-')) {
        _driverDetailsError = 'Use format: Name - 9876543210';
        return;
      }
      final parts = trimmed.split('-').map((e) => e.trim()).toList();
      if (parts.length < 2) {
        _driverDetailsError = 'Name and number must be separated by hyphen';
        return;
      }
      final name = parts[0];
      final numberPart = parts
          .sublist(1)
          .join('')
          .replaceAll(RegExp(r'[^0-9]'), '');

      if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(name)) {
        _driverDetailsError = 'Driver name: letters & spaces only';
        return;
      }
      if (numberPart.length != 10) {
        _driverDetailsError = 'Driver mobile must be 10 digits';
        return;
      }
      if (!RegExp(r'^[5-9]').hasMatch(numberPart)) {
        _driverDetailsError = 'Driver mobile must start with 5–9';
        return;
      }

      _driverDetailsError = null;
      final formatted = '$name - $numberPart';
      if (formatted != trimmed) {
        vehicleDriverDetailsController.text = formatted;
        vehicleDriverDetailsController.selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
      }
    });
  }

  void _validateMobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (value.isEmpty) {
        _mobileNumberError = null;
      } else if (digits.length == 10 && RegExp(r'^[5-9]').hasMatch(digits)) {
        _mobileNumberError = null;
        if (digits != value) {
          mobileNumberController.text = digits;
          mobileNumberController.selection = TextSelection.fromPosition(
            TextPosition(offset: digits.length),
          );
        }
      } else {
        _mobileNumberError =
            'Mobile number must be 10 digits and start with 5–9';
      }
    });
  }

  void _validateEmail(String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _emailError = null;
      } else if (trimmed != trimmed.toLowerCase()) {
        _emailError = 'Email must be in lowercase';
      } else if (RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(trimmed)) {
        _emailError = null;
      } else {
        _emailError = 'Enter a valid email address';
      }
    });
  }

  bool isFormValid() {
    for (var g in goods) {
      final qty = _qtyControllers[g.name]!.text.trim();
      final sr = _srNoControllers[g.name]!.text.trim();

      final qtyNum = int.tryParse(qty) ?? 0;
      final srNum = int.tryParse(sr) ?? 0;

      final qtyFilled = qtyNum > 0;
      final srFilled = srNum > 0;

      if (qtyFilled != srFilled) return false; // One filled, other not
    }
    return true;
  }

  Future<void> _saveChallanData() async {
    if (_saving) return;
    setState(() => _saving = true);

    final customerName = customerNameController.text.trim();
    final customerAddress = locationController.text.trim();
    final transporter = transporterController.text.trim();
    final vehicleNumber = vehicleNumberController.text.trim().toUpperCase();
    final driverDetails = vehicleDriverDetailsController.text.trim();
    final mobileNumber = mobileNumberController.text.trim();
    final challanDate = dateController.text;
    final customerEmail = customerEmailController.text.trim().toLowerCase();

    if (!driverDetails.contains('-')) {
      _showError('Driver: Name - 9876543210');
      setState(() => _saving = false);
      return;
    }
    final dParts = driverDetails.split('-').map((e) => e.trim()).toList();
    if (dParts.length < 2) {
      _showError('Separate name & number with hyphen');
      setState(() => _saving = false);
      return;
    }
    final driverName = dParts[0];
    final driverNumber = dParts
        .sublist(1)
        .join('')
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(driverName)) {
      _showError('Driver name: letters only');
      setState(() => _saving = false);
      return;
    }
    if (driverNumber.length != 10) {
      _showError('Driver mobile: 10 digits');
      setState(() => _saving = false);
      return;
    }
    if (!RegExp(r'^[5-9]').hasMatch(driverNumber)) {
      _showError('Driver mobile must start with 5–9');
      setState(() => _saving = false);
      return;
    }

    if (customerName.isEmpty) {
      _showError('Enter customer name');
      setState(() => _saving = false);
      return;
    }
    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(customerName)) {
      _showError('Customer name: letters only');
      setState(() => _saving = false);
      return;
    }
    if (transporter.isEmpty) {
      _showError('Enter transporter name');
      setState(() => _saving = false);
      return;
    }
    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(transporter)) {
      _showError('Transporter: letters only');
      setState(() => _saving = false);
      return;
    }
    if (vehicleNumber.isEmpty) {
      _showError('Enter vehicle number');
      setState(() => _saving = false);
      return;
    }
    final vp1 = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$');
    final vp2 = RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$');
    if (!(vp1.hasMatch(vehicleNumber) || vp2.hasMatch(vehicleNumber))) {
      _showError('Invalid vehicle number');
      setState(() => _saving = false);
      return;
    }
    if (customerAddress.isEmpty) {
      _showError('Enter customer address (Location)');
      setState(() => _saving = false);
      return;
    }

    final mobileDigits = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobileDigits.length != 10) {
      _showError('Mobile number must be 10 digits');
      setState(() => _saving = false);
      return;
    }
    if (!RegExp(r'^[5-9]').hasMatch(mobileDigits)) {
      _showError('Mobile number must start with 5–9');
      setState(() => _saving = false);
      return;
    }
    if (customerEmail.isNotEmpty &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(customerEmail)) {
      _showError('Enter a valid email address');
      setState(() => _saving = false);
      return;
    }
    if (customerEmail.isNotEmpty &&
        customerEmail != customerEmail.toLowerCase()) {
      _showError('Email must be in lowercase');
      setState(() => _saving = false);
      return;
    }
    isFormValid();

    final List<Map<String, dynamic>> items = [];
    for (final g in goods) {
      final qtyText = _qtyControllers[g.name]!.text.trim();
      final srText = _srNoControllers[g.name]!.text.trim();

      if (qtyText.isEmpty && srText.isEmpty) continue;

      final qty = int.tryParse(qtyText) ?? 0;
      if (qty == 0) {
        _showError('${g.name} Qty must be ≥ 1');
        setState(() => _saving = false);
        return;
      }
      if (srText.isEmpty) {
        _showError('${g.name} Sr No required');
        setState(() => _saving = false);
        return;
      }

      items.add({'name': g.name, 'qty': qty, 'srNo': srText});
    }

    if (items.isEmpty) {
      _showError('At least one product required');
      setState(() => _saving = false);
      return;
    }

    setState(() => _loading = true);
    try {
      bool success;

      if (_challanId == null) {
        success = await _api.createChallan(
          customerId: selectedCustomerId,
          customerName: customerName,
          challanType: type,
          location: customerAddress,
          transporter: transporter,
          vehicleNumber: vehicleNumber,
          driverName: driverName,
          driverNumber: driverNumber,
          contactNumber: mobileDigits,
          items: items,
          date: challanDate,
          email: customerEmail,
          address: customerAddress,
        );
        if (success) {
          showSuccessToast(context, "Challan saved successfully");
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ViewChallanScreen()),
            (route) => false,
          );
        } else {
          _showError('Failed to save challan');
        }
      } else {
        success = await _api.updateChallan(
          challanId: _challanId!,
          customerId: selectedCustomerId,
          customerName: customerName,
          challanType: type,
          location: customerAddress,
          transporter: transporter,
          vehicleNumber: vehicleNumber,
          driverName: driverName,
          driverNumber: driverNumber,
          contactNumber: mobileDigits,
          items: items,
          date: challanDate,
          email: customerEmail,
          address: customerAddress,
        );
        if (success) {
          showSuccessToast(context, "Challan updated successfully");
          Navigator.pop(context, true);
        } else {
          _showError('Failed to update challan');
        }
      }
    } catch (e) {
      _showError('Operation failed: $e');
    } finally {
      setState(() {
        _loading = false;
        _saving = false;
      });
    }
  }

  void _clearAllFields() {
    setState(() {
      _loading = false;
      _saving = false;
      _challanId = null;
      selectedCustomerId = null;
      customerNameController.clear();
      locationController.clear();
      transporterController.clear();
      vehicleDriverDetailsController.clear();
      vehicleNumberController.clear();
      mobileNumberController.clear();
      customerEmailController.clear();
      _emailController.clear();

      for (final ctrl in _qtyControllers.values) ctrl.clear();
      for (final ctrl in _srNoControllers.values) ctrl.clear();

      dateController.text = DateTime.now().toIso8601String().split('T').first;
      _vehicleNumberError = null;
      _driverDetailsError = null;
      _mobileNumberError = null;
      _emailError = null;
      type = "RECEIVED";
      challanTypeSelected = true;
    });
    _removeOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    customerNameController.dispose();
    locationController.dispose();
    transporterController.dispose();
    vehicleDriverDetailsController.dispose();
    vehicleNumberController.dispose();
    mobileNumberController.dispose();
    customerEmailController.dispose();
    dateController.dispose();
    _emailController.dispose();
    for (final ctrl in _qtyControllers.values) ctrl.dispose();
    for (final ctrl in _srNoControllers.values) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width * 0.04,
      vertical: 8,
    );

    final isEditMode = _challanId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Challan" : "New Challan"),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          // color: Color.fromRGBO(0, 140, 192, 1),
          color: Colors.white,
        ),
      ),
      body: GestureDetector(
        onTap: () {
          _removeOverlay();
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomerSearchField(),
                          const SizedBox(height: 12),
                          _buildChallanTypeRow(),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Date",
                            controller: dateController,
                            hint: "Auto-filled (yyyy-MM-dd)",
                            enabled: true,
                            prefixIcon: const Icon(Icons.calendar_month),
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                dateController.text = "${pickedDate.toLocal()}"
                                    .split(' ')[0];
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Customer Address",
                            controller: locationController,
                            hint: "Enter customer address (Location)",
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Vehicle Number",
                            controller: vehicleNumberController,
                            hint: "e.g., MH12AB1234 or 22BH1234AA",
                            onChanged: _validateVehicleNumber,
                            errorText: _vehicleNumberError,
                            enabled: true,
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Transporter",
                            controller: transporterController,
                            hint: "Enter Transporter Details",
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Driver Details",
                            controller: vehicleDriverDetailsController,
                            hint: "e.g., Name - 9876543210",
                            onChanged: _validateDriverDetails,
                            errorText: _driverDetailsError,
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Mobile Number",
                            controller: mobileNumberController,
                            hint: "e.g., 9876543210 (starts with 5–9)",
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: _validateMobileNumber,
                            errorText: _mobileNumberError,
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "E-Mail",
                            controller: customerEmailController,
                            hint: "e.g., example@domain.com (lowercase only)",
                            enabled: true,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              final lower = value.toLowerCase();
                              if (value != lower) {
                                customerEmailController.text = lower;
                                customerEmailController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: lower.length),
                                    );
                              }
                              _validateEmail(lower);
                            },
                            errorText: _emailError,
                          ),
                          const SizedBox(height: 16),
                          _buildProductTable(),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(isEditMode),
                ],
              ),
            ),

            if (_loading) customLoader(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Customer Name",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: _customerFieldKey,
          controller: customerNameController,
          onChanged: _onCustomerSearchChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
          ],
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            hintText: "Search by name or mobile...",
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color.fromRGBO(156, 156, 156, 1),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color.fromRGBO(156, 156, 156, 1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? errorText,
    required bool enabled,
    Future<Null> Function()? onTap,
    Icon? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          enabled: enabled,
          onTap: onTap,
          readOnly: onTap != null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            prefixIcon: prefixIcon,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color.fromRGBO(156, 156, 156, 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: enabled
                    ? const Color.fromRGBO(156, 156, 156, 1)
                    : Colors.grey.shade300,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChallanTypeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          "Challan Type",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 16),
        _typeBtn("Received", true, "RECEIVED"),
        const SizedBox(width: 16),
        _typeBtn("Delivered", false, "DELIVERED"),
      ],
    );
  }

  Widget _typeBtn(String label, bool selected, String val) {
    return GestureDetector(
      onTap: () => setState(() {
        challanTypeSelected = selected;
        type = val;
      }),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: const Color.fromRGBO(0, 140, 192, 1),
              ),
              shape: BoxShape.circle,
              color: challanTypeSelected == selected
                  ? const Color.fromRGBO(0, 140, 192, 1)
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    if (_goodsLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (goods.isEmpty) {
      return Text("Goods Not Found");
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(238, 238, 238, 1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(0.8),
          2: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(238, 238, 238, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: ["Product", "QTY", "Sr. No"]
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 9, 115, 156),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...goods.map((g) => _dynamicRow(g)),
        ],
      ),
    );
  }

  TableRow _dynamicRow(GoodsDTO g) {
    final qtyCtrl = _qtyControllers[g.name]!;
    final srCtrl = _srNoControllers[g.name]!;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            g.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        _numField(qtyCtrl, srCtrl), // ← Pass srCtrl
        _srNoField(srCtrl, qtyCtrl), // ← Pass qtyCtrl
      ],
    );
  }
  
  Widget _numField(
    TextEditingController qtyCtrl,
    TextEditingController srCtrl,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        void listener() => setState(() {});
        qtyCtrl.removeListener(listener);
        srCtrl.removeListener(listener);
        qtyCtrl.addListener(listener);
        srCtrl.addListener(listener);

        final srText = srCtrl.text.trim();
        final qtyText = qtyCtrl.text.trim();

        final bool srFilled =
            srText.isNotEmpty &&
            int.tryParse(srText) != null &&
            int.tryParse(srText)! > 0;
        final bool qtyValid =
            qtyText.isNotEmpty &&
            int.tryParse(qtyText) != null &&
            int.tryParse(qtyText)! > 0;

        final bool showError = srFilled && !qtyValid;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(8),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromRGBO(238, 238, 238, 1),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentBlue, width: 2.0),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              errorText: showError ? '' : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  String? _getSrNoErrorText(String value) {
    // Allow empty
    if (value.trim().isEmpty) {
      return null;
    }

    final int? num = int.tryParse(value);
    if (num == null) {
      return 'Invalid number';
    }

    if (num == 0) {
      return ''; //'Sr No cannot be 0';
    }

    return null; // Valid
  }

  Widget _srNoField(
    TextEditingController srCtrl,
    TextEditingController qtyCtrl,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        void listener() => setState(() {});
        srCtrl.removeListener(listener);
        qtyCtrl.removeListener(listener);
        srCtrl.addListener(listener);
        qtyCtrl.addListener(listener);

        final qtyText = qtyCtrl.text.trim();
        final srText = srCtrl.text.trim();

        final bool qtyFilled =
            qtyText.isNotEmpty &&
            int.tryParse(qtyText) != null &&
            int.tryParse(qtyText)! > 0;
        final bool srValid =
            srText.isNotEmpty &&
            int.tryParse(srText) != null &&
            int.tryParse(srText)! > 0;

        final bool showError = qtyFilled && !srValid;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: TextField(
            controller: srCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(8),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromRGBO(238, 238, 238, 1),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentBlue, width: 2.0),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              errorText: showError ? '' : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isEditMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearAllFields,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 9, 115, 156),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    "Reset",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 9, 115, 156),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _saveChallanData,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color.fromARGB(255, 9, 115, 156),
                ),
                child: _saving
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Center(
                        child: Text(
                          isEditMode ? "Update" : "Save",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
