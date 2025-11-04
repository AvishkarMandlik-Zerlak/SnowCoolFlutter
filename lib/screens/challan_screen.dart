import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

class ChallanScreen extends StatefulWidget {
  const ChallanScreen({super.key});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final ChallanApi _api = ChallanApi();
  final CustomerApi _customerApi = CustomerApi();
  final GoodsApi _goodsApi = GoodsApi(); // <-- NEW

  // ---------- Controllers ----------
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController transporterController = TextEditingController();
  final TextEditingController vehicleDriverDetailsController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController customerAddressController =
      TextEditingController();

  late final TextEditingController dateController;

  // ---------- Dynamic Product Controllers ----------
  List<GoodsDTO> goods = [];
  bool _goodsLoading = true;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _srNoControllers = {};

  // ---------- State ----------
  bool challanTypeSelected = true;
  int? selectedCustomerId;
  String type = "RECEIVE";

  List<CustomerDTO> searchResults = [];
  bool showDropdown = false;
  bool _loading = false;
  bool _saving = false;

  // Inline errors
  String? _vehicleNumberError;
  String? _driverDetailsError;
  String? _mobileNumberError;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    _loadGoods(); // Load dynamic products
  }

  // ---------- Load Goods ----------
  Future<void> _loadGoods() async {
    final list = await _goodsApi.getAllGoods();
    setState(() {
      goods = list;
      _goodsLoading = false;
      // Initialize controllers for each good
      for (final g in goods) {
        _qtyControllers[g.name] = TextEditingController();
        _srNoControllers[g.name] = TextEditingController();
      }
    });
  }

  void _showError(String message) {
    showErrorToast(context, message);
  }

  // ---------- Customer Search ----------
  Future<void> searchCustomer(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        showDropdown = false;
        searchResults = [];
      });
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);

    try {
      final results = await _customerApi.searchCustomers(query.trim());
      setState(() {
        searchResults = results;
        showDropdown = results.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        searchResults = [];
        showDropdown = false;
        _loading = false;
      });
      _showError('Search error: $e');
    }
  }

  void selectCustomer(CustomerDTO customer) {
    setState(() {
      selectedCustomerId = customer.id;
      customerNameController.text = customer.name;
      mobileNumberController.text = customer.contactNumber;
      customerEmailController.text = customer.email ?? '';
      customerAddressController.text = customer.address ?? '';
      showDropdown = false;
      _validateMobileNumber(customer.contactNumber);
    });
  }

  // ---------- Validators ----------
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

  // ---------- SAVE ----------
  Future<void> _saveChallanData() async {
    if (_saving) return;
    setState(() => _saving = true);

    final customerName = customerNameController.text.trim();
    final location = locationController.text.trim();
    final transporter = transporterController.text.trim();
    final vehicleNumber = vehicleNumberController.text.trim().toUpperCase();
    final driverDetails = vehicleDriverDetailsController.text.trim();
    final mobileNumber = mobileNumberController.text.trim();
    final challanDate = dateController.text;

    // Extract driver name & number
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

    // Basic validation
    if (customerName.isEmpty) return _showError('Enter customer name');
    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(customerName))
      return _showError('Customer name: letters only');
    if (transporter.isEmpty) return _showError('Enter transporter name');
    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(transporter))
      return _showError('Transporter: letters only');
    if (vehicleNumber.isEmpty) return _showError('Enter vehicle number');
    final vp1 = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$');
    final vp2 = RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$');
    if (!(vp1.hasMatch(vehicleNumber) || vp2.hasMatch(vehicleNumber)))
      return _showError('Invalid vehicle number');
    if (location.isEmpty) return _showError('Enter location');
    if (selectedCustomerId == null) return _showError('Select a customer');
    final mobileDigits = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobileDigits.length != 10)
      return _showError('Mobile number must be 10 digits');
    if (!RegExp(r'^[5-9]').hasMatch(mobileDigits))
      return _showError('Mobile number must start with 5–9');

    // ---------- Dynamic Product Validation ----------
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

      items.add({'product': g.name, 'quantity': qty, 'serialNumber': srText});
    }

    if (items.isEmpty) {
      _showError('At least one product required');
      setState(() => _saving = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final success = await _api.challanData(
        selectedCustomerId!,
        customerName,
        type,
        location,
        transporter,
        vehicleNumber,
        driverName,
        driverNumber,
        mobileNumber,
        // Pass dummy values for old static fields (will be ignored in API)
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        challanDate,
      );

      if (success) {
        showSuccessToast(context, "Challan saved successfully");
        _clearAllFields();
      }
    } catch (e) {
      _showError('Save failed: $e');
    } finally {
      setState(() {
        _loading = false;
        _saving = false;
      });
    }
  }

  // ---------- Reset ----------
  void _clearAllFields() {
    setState(() {
      _loading = false;
      _saving = false;
      selectedCustomerId = null;
      customerNameController.clear();
      locationController.clear();
      transporterController.clear();
      vehicleDriverDetailsController.clear();
      vehicleNumberController.clear();
      mobileNumberController.clear();
      customerEmailController.clear();
      customerAddressController.clear();

      // Clear dynamic product fields
      for (final ctrl in _qtyControllers.values) ctrl.clear();
      for (final ctrl in _srNoControllers.values) ctrl.clear();

      dateController.text = DateTime.now().toIso8601String().split('T').first;
      _vehicleNumberError = null;
      _driverDetailsError = null;
      _mobileNumberError = null;
    });
  }

  @override
  void dispose() {
    customerNameController.dispose();
    locationController.dispose();
    transporterController.dispose();
    vehicleDriverDetailsController.dispose();
    vehicleNumberController.dispose();
    mobileNumberController.dispose();
    customerEmailController.dispose();
    customerAddressController.dispose();
    dateController.dispose();

    // Dispose dynamic controllers
    for (final ctrl in _qtyControllers.values) ctrl.dispose();
    for (final ctrl in _srNoControllers.values) ctrl.dispose();

    super.dispose();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width * 0.04,
      vertical: 8,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Received/Delivered Challan"),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color.fromRGBO(0, 140, 192, 1),
        ),
      ),
      body: Padding(
        padding: padding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabeledField(
                      label: "Customer Name",
                      controller: customerNameController,
                      hint: "Enter Customer Name",
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z\s]'),
                        ),
                      ],
                      onChanged: searchCustomer,
                      enabled: true,
                    ),
                    if (showDropdown)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: BoxConstraints(
                          maxHeight: size.height * 0.25,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: _loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                itemBuilder: (context, i) {
                                  final c = searchResults[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      c.contactNumber,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => selectCustomer(c),
                                  );
                                },
                              ),
                      ),

                    const SizedBox(height: 12),
                    _buildChallanTypeRow(),
                    const SizedBox(height: 12),
                    _buildLabeledField(
                      label: "Location",
                      controller: locationController,
                      hint: "Enter Location",
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
                      label: "Date",
                      controller: dateController,
                      hint: "Auto-filled (yyyy-MM-dd)",
                      enabled: true,
                    ),
                    const SizedBox(height: 16),
                    _buildProductTable(), // Dynamic now
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
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
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
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
              borderSide: BorderSide(color: Color.fromRGBO(156, 156, 156, 1)),
              borderRadius: BorderRadius.all(Radius.circular(8)),
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
      spacing: 10,
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
        // const SizedBox(width: 16),
        _typeBtn("Received", true, "RECEIVE"),
        // const SizedBox(width: 16),
        _typeBtn("Delivery", false, "DELIVER"),
      ],
    );
  }

  Widget _typeBtn(String label, bool selected, String val) {
    return GestureDetector(
      onTap: () => setState(() => {challanTypeSelected = selected, type = val}),
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

  // ---------- Dynamic Product Table ----------
  Widget _buildProductTable() {
    if (_goodsLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (goods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No products available',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(238, 238, 238, 1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(0.7), 1: FlexColumnWidth(0.5)},
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(238, 238, 238, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: ["Product", "QTY (≥1)", "Sr. No"]
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
        _numField(qtyCtrl),
        _numField(srCtrl),
      ],
    );
  }

  Widget _numField(TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromRGBO(238, 238, 238, 1),
              width: 1.5,
            ),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromRGBO(238, 238, 238, 1),
              width: 2.0,
            ),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearAllFields,
              child: Container(
                height: 46,
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
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color.fromARGB(255, 9, 115, 156),
                ),
                child: _saving
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(
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

// Uppercase formatter
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
