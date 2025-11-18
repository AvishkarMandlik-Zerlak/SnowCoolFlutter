import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/loader.dart';
import 'package:collection/collection.dart';

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
  final TextEditingController locationController = TextEditingController();
  final TextEditingController transporterController = TextEditingController();
  final TextEditingController vehicleDriverDetailsController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  late final TextEditingController dateController;
  final TextEditingController purchaseOrderNumberController = TextEditingController();
  final TextEditingController depositeAmountController = TextEditingController();
  final TextEditingController deliveryDetailsController =
      TextEditingController();
  final TextEditingController depositeNarrationController =
      TextEditingController();

  List<GoodsDTO> goods = [];
  bool _goodsLoading = true;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _srNoControllers = {};

  bool _showProductTable = false;
  final List<Map<String, dynamic>> _productEntries = [];

  int? selectedCustomerId;
  String type = "RECEIVED";
  bool challanTypeSelected = true;
  int? _challanId;

  // FIXED: Using GlobalKey for perfect overlay positioning
  final GlobalKey _customerFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isSearching = false;

  // Inline errors
  String? _vehicleNumberError;
  String? _driverDetailsError;

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    _challanId = widget.challanData?['id'] is int
        ? widget.challanData!['id']
        : int.tryParse(widget.challanData?['id'].toString() ?? '');

    _loadGoods().then((_) {
      if (_challanId != null) _loadChallanForEdit();
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
      log(list.toString());
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
      if (data == null) throw Exception("Not found");

      setState(() {
        selectedCustomerId = data['customerId'];
        customerNameController.text = data['customerName'] ?? '';
        locationController.text =
            data['customerAddress'] ?? data['siteLocation'] ?? '';
        transporterController.text = data['transporter'] ?? '';
        vehicleNumberController.text = data['vehicleNumber'] ?? '';
        vehicleDriverDetailsController.text =
            '${data['driverName'] ?? ''} - ${data['driverNumber'] ?? ''}'
                .trim();
        dateController.text = data['date'] ?? dateController.text;
        type = data['challanType'] ?? 'RECEIVED';
        purchaseOrderNumberController.text = data['purchaseOrderNumber'] ?? '';
        depositeAmountController.text = data['depositeAmount']?.toString() ?? '';
        deliveryDetailsController.text = data['deliveryDetails'] ?? '';
        depositeNarrationController.text = data['depositeNarration'] ?? '';

        _productEntries.clear();
        final List items = data['items'] ?? [];
        for (var item in items) {
          final name = item['name'] as String?;
          final goodsItem = goods.firstWhereOrNull((g) => g.name == name);
          if (goodsItem != null) {
            dynamic srNoRaw =
                item['srNo'] ?? item['srNo'];

            String srNoString = '';
            if (srNoRaw is List) {
              srNoString = srNoRaw.join('/');
            } else if (srNoRaw is String) {
              srNoString = srNoRaw;
            }
            // Optional: clean up extra spaces
            srNoString = srNoString.split('/').map((s) => s.trim()).join('/');

            _productEntries.add({
              'goods': goodsItem,
              'type': item['type']?.toString() ?? '',
              'qty': item['qty']?.toString() ?? '',
              'srNo': srNoString,
            });
          }
        }
        _showProductTable = _productEntries.isNotEmpty;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load challan");
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
      locationController.text = customer.address ?? '';
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

  bool get _isFormValid {
    if (customerNameController.text.trim().isEmpty) {
      _showError("Customer name required");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      _showError("Site location required");
      return false;
    }
    if (transporterController.text.trim().isEmpty) {
      _showError("Transporter name required");
      return false;
    }
    if (deliveryDetailsController.text.trim().isEmpty) {
      _showError("Delivery details required");
      return false;
    }
    if (vehicleNumberController.text.trim().isEmpty) {
      _showError("Vehicle number required");
      return false;
    }
    if (purchaseOrderNumberController.text.trim().isEmpty) {
      _showError("PO number required");
      return false;
    }
    if (depositeAmountController.text.trim().isEmpty) {
      _showError("Deposite amount required");
      return false;
    }
    // if (depositeNarrationController.text.trim().isEmpty) {
    //   _showError("Deposite Naration required");
    //   return false;
    // }

    final v = vehicleNumberController.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$').hasMatch(v) &&
        !RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$').hasMatch(v)) {
      _showError("Invalid vehicle number format");
      return false;
    }

    final driver = vehicleDriverDetailsController.text.trim();
    if (driver.isEmpty || !driver.contains('-')) {
      _showError("Driver: Name - 9876543210");
      return false;
    }
    final parts = driver.split('-').map((e) => e.trim()).toList();
    final driverName = parts[0];
    final driverNum = parts
        .sublist(1)
        .join('')
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(driverName)) {
      _showError("Driver name: letters only");
      return false;
    }
    if (driverNum.length != 10 || !RegExp(r'^[5-9]').hasMatch(driverNum)) {
      _showError("Driver mobile: 10 digits, start with 5-9");
      return false;
    }

    if (_productEntries.isEmpty || !_showProductTable) {
      _showError("Add at least one product");
      return false;
    }

    for (var entry in _productEntries) {
      final goods = entry['goods'] as GoodsDTO?;
      if (goods == null) {
        _showError("Select product in all rows");
        return false;
      }
      final type = (entry['type'] as String).trim();
      final qtyStr = (entry['qty'] as String).trim();
      final srNo = (entry['srNo'] as String).trim();

      if (type.isEmpty) {
        _showError("Type required for ${goods.name}");
        return false;
      }
      final qty = int.tryParse(qtyStr);
      if (qty == null || qty <= 0) {
        _showError("Qty must be ≥ 1 for ${goods.name}");
        return false;
      }
      if (srNo.isEmpty || srNo == '0') {
        _showError("Sr. No required and cannot be 0 for ${goods.name}");
        return false;
      }
    }
    return true;
  }

  Future<void> _saveChallanData() async {
    if (_saving || !_isFormValid) return;

    setState(() => _saving = true);

    try {
      final List<Map<String, dynamic>> items = _productEntries.map((e) {
        final goods = e['goods'] as GoodsDTO;

        final String rawsrNo = (e['srNo'] as String?)?.trim() ?? '';

        final List<String> srNoList = rawsrNo
            .split(RegExp(r'[/,;\\]'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();

        return {
          'name': goods.name,
          'type': (e['type'] as String).trim(),
          'qty': int.tryParse((e['qty'] as String).trim()) ?? 0,
          'srNo': srNoList,
        };
      }).toList();

      log(items.toString());

      final String driverText = vehicleDriverDetailsController.text.trim();
      final List<String> driverParts = driverText
          .split('-')
          .map((e) => e.trim())
          .toList();
      final String driverName = driverParts.isNotEmpty ? driverParts[0] : '';
      final String driverNumber = driverParts.length > 1
          ? driverParts.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')
          : '';

      final bool success = _challanId == null
          ? await _api.createChallan(
              customerId: selectedCustomerId,
              customerName: customerNameController.text.trim(),
              challanType: type,
              location: locationController.text.trim(),
              transporter: transporterController.text.trim(),
              vehicleNumber: vehicleNumberController.text.trim().toUpperCase(),
              driverName: driverName,
              driverNumber: driverNumber,
              items: items,
              date: dateController.text,
              purchaseOrderNumber: purchaseOrderNumberController.text.trim().isEmpty
                  ? null
                  : purchaseOrderNumberController.text.trim(),
              depositeAmount: depositeAmountController.text.trim().isEmpty
                  ? null
                  : double.tryParse(depositeAmountController.text.trim()),
              deliveryDetails: deliveryDetailsController.text.trim(),
              depositeNarration: depositeNarrationController.text.trim().isEmpty
                  ? null
                  : depositeNarrationController.text.trim(),
            )
          : await _api.updateChallan(
              challanId: _challanId!,
              customerId: selectedCustomerId,
              customerName: customerNameController.text.trim(),
              challanType: type,
              location: locationController.text.trim(),
              transporter: transporterController.text.trim(),
              vehicleNumber: vehicleNumberController.text.trim().toUpperCase(),
              driverName: driverName,
              driverNumber: driverNumber,
              items: items,
              date: dateController.text,
              deliveryDetails: deliveryDetailsController.text.trim(),
              purchaseOrderNumber: purchaseOrderNumberController.text.trim().isEmpty
                  ? null
                  : purchaseOrderNumberController.text.trim(),
              depositeAmount: depositeAmountController.text.trim().isEmpty
                  ? null
                  : double.tryParse(depositeAmountController.text.trim()),
              depositeNarration: depositeNarrationController.text.trim().isEmpty
                  ? null
                  : depositeNarrationController.text.trim(),
            );

      if (!mounted) return;

      if (success) {
        showSuccessToast(
          context,
          _challanId == null
              ? "Challan created successfully!"
              : "Challan updated!",
        );

        if (_challanId == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ViewChallanScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        showErrorToast(context, "Failed to save challan");
      }
    } catch (e) {
      log("Save error: $e");
      showErrorToast(context, "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _saving = false);
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
      customerEmailController.clear();
      purchaseOrderNumberController.clear();
      depositeAmountController.clear();
      deliveryDetailsController.clear();
      _showProductTable = false;
      _productEntries.clear();

      for (final ctrl in _qtyControllers.values) ctrl.clear();
      for (final ctrl in _srNoControllers.values) ctrl.clear();

      dateController.text = DateTime.now().toIso8601String().split('T').first;
      _vehicleNumberError = null;
      _driverDetailsError = null;
      type = "RECEIVED";
      challanTypeSelected = true;
    });
    _removeOverlay();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    locationController.dispose();
    transporterController.dispose();
    vehicleDriverDetailsController.dispose();
    vehicleNumberController.dispose();
    dateController.dispose();
    purchaseOrderNumberController.dispose();
    depositeAmountController.dispose();
    deliveryDetailsController.dispose();
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
                            label: "Site Location",
                            controller: locationController,
                            hint: "Enter Site Delivery Location",
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
                            label: "Delivery Details",
                            controller: deliveryDetailsController,
                            hint: "e.g., Gate 2, 3rd Floor, Contact Mr. Sharma",
                            enabled: true,
                            maxlines: 3,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "PO No.",
                            controller: purchaseOrderNumberController,
                            hint: "Purchase Order Number (if any)",
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Deposit Amount (₹)",
                            controller: depositeAmountController,
                            hint: "0.00",
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                if (newValue.text.isEmpty) return newValue;
                                final parts = newValue.text.split('.');
                                if (parts.length > 2) return oldValue;
                                if (parts.length == 2 && parts[1].length > 2)
                                  return oldValue;
                                return newValue;
                              }),
                            ],
                            enabled: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            label: "Deposite Naration",
                            controller: depositeNarrationController,
                            hint: "",
                            enabled: true,
                            maxlines: 3,
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
    int? maxlines,
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
          maxLines: maxlines,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Challan Type",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(156, 156, 156, 1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: type,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: "RECEIVED", child: Text("Received")),
                DropdownMenuItem(value: "DELIVERED", child: Text("Delivered")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    type = value;
                    challanTypeSelected = value == "RECEIVED";
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  bool get isProductTableValid {
    return _productEntries.every((entry) {
      final goods = entry['goods'] as GoodsDTO?;
      if (goods == null) return true;
      final type = (entry['type'] as String?)?.trim();
      final qty = (entry['qty'] as String?)?.trim();
      return type != null && type.isNotEmpty && qty != null && qty.isNotEmpty;
    });
  }

  Widget _buildProductTable() {
    if (_goodsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (goods.isEmpty) {
      return const Center(child: Text("No goods available"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Products",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (!_showProductTable)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showProductTable = true;
                if (_productEntries.isEmpty) _addEmptyRow();
              });
            },
            icon: const Icon(Icons.add_box_rounded),
            label: const Text("Insert Products"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accentBlue,
              side: const BorderSide(color: AppColors.accentBlue, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

        if (_showProductTable)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                      columnWidths: const {
                        0: FixedColumnWidth(180),
                        1: FixedColumnWidth(150),
                        2: FixedColumnWidth(100),
                        3: FixedColumnWidth(130),
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(238, 238, 238, 1),
                          ),
                          children: [
                            _headerCell('Product *'),
                            _headerCell('Type *'),
                            _headerCell('Qty *'),
                            _headerCell('Sr. No *'),
                          ],
                        ),

                        // Data Rows
                        ..._productEntries.asMap().entries.map((e) {
                          final index = e.key;
                          final entry = e.value;
                          final selectedGoods = entry['goods'] as GoodsDTO?;
                          final bool isEvenRow = index % 2 == 0;

                          final String type =
                              (entry['type'] as String?)?.trim() ?? '';
                          final String qtyStr =
                              (entry['qty'] as String?)?.trim() ?? '';
                          final String srNoStr =
                              (entry['srNo'] as String?)?.trim() ?? '';

                          final int? qty = qtyStr.isEmpty
                              ? null
                              : int.tryParse(qtyStr);

                          // Validation Errors
                          final String? typeError =
                              selectedGoods != null && type.isEmpty
                              ? 'Required'
                              : null;

                          String? qtyError;
                          if (selectedGoods != null) {
                            if (qtyStr.isEmpty) {
                              qtyError = 'Required';
                            } else if (qty == null) {
                              qtyError = 'Invalid';
                            } else if (qty == 0) {
                              qtyError = 'Must be ≥ 1';
                            }
                          }

                          String? srNoError;
                          if (selectedGoods != null) {
                            if (srNoStr.isEmpty) {
                              srNoError = 'Required';
                            } else if (srNoStr == '0') {
                              srNoError = 'Cannot be 0';
                            }
                          }

                          return TableRow(
                            decoration: BoxDecoration(
                              color: isEvenRow
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                            children: [
                              // Product
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<GoodsDTO>(
                                    isExpanded: true,
                                    hint: const Text(
                                      "Select Product *",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    value: selectedGoods,
                                    items: goods
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(
                                              g.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => entry['goods'] = value);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              // Type
                              _editableCell(
                                child: TextField(
                                  enabled: selectedGoods != null,
                                  decoration: InputDecoration(
                                    hintText: "Type *",
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    errorText: typeError,
                                    errorStyle: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => entry['type'] = v),
                                ),
                              ),

                              // Qty
                              _editableCell(
                                child: TextField(
                                  enabled: selectedGoods != null,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: "Qty *",
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    errorText: qtyError,
                                    errorStyle: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => entry['qty'] = v),
                                ),
                              ),

                              // Sr. No
                              _editableCell(
                                child: TextField(
                                  enabled: selectedGoods != null,
                                  decoration: InputDecoration(
                                    hintText: "Sr No *",
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    errorText: srNoError,
                                    errorStyle: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => entry['srNo'] = v),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addEmptyRow,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  label: const Text(
                    "Add Product",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
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

  Widget _editableCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );
  }

  void _addEmptyRow() {
    setState(() {
      _productEntries.add({'goods': null, 'type': '', 'qty': '', 'srNo': ''});
    });
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
