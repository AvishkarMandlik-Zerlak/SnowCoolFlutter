import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
// import 'package:snow_trading_cool/screens/passbook.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import 'package:snow_trading_cool/widgets/loader.dart';

class ViewChallanScreen extends StatefulWidget {
  final String? type;
  const ViewChallanScreen({super.key, this.type});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {
  bool _selectionMode = false;
  bool _isLoading = false;

  final ChallanApi challanApi = ChallanApi();
  List<Map<String, dynamic>> _challans = [];
  List<Map<String, dynamic>> _filteredData = [];

  String _searchQuery = '';
  String _selectedType = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedIds = [];
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  // SAFE DATE PARSING FUNCTION — PREVENTS CRASH
  DateTime? _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'null') return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    return _challans.where((customer) {
      final nameMatch = (customer['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final typeMatch =
          _selectedType == 'All' || (customer['type'] ?? '') == _selectedType;

      final dateStr = customer['date'] as String?;
      final date = _safeParseDate(dateStr);

      final fromOk =
          _fromDate == null ||
          date == null ||
          date.isAfter(_fromDate!.subtract(const Duration(days: 1)));
      final toOk =
          _toDate == null ||
          date == null ||
          date.isBefore(_toDate!.add(const Duration(days: 1)));

      return nameMatch && typeMatch && fromOk && toOk;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedCustomers {
    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    final filtered = _filteredCustomers;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end.clamp(0, filtered.length));
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _showUserGoodsDetails(int challanId) async {
    if (challanId <= 0) {
      showErrorToast(context, "Invalid challan ID");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: SizedBox(width: 60, height: 60, child: customLoader())),
    );

    final challan = await challanApi.getChallan(challanId);

    if (mounted) Navigator.of(context).pop();

    if (challan == null) {
      showErrorToast(context, "Failed to load challan details");
      return;
    }

    if (!mounted) return;

    final items =
        (challan['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.receipt_long,
              color: Color.fromRGBO(0, 140, 192, 1),
            ),
            const SizedBox(width: 8),
            const Text(
              "Goods Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Items",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                if (items.isEmpty)
                  const Text(
                    "No items found",
                    style: TextStyle(color: Colors.grey),
                  ),

                ...items.map(
                  (item) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item['name'] ?? 'Unknown'),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "${item['qty'] ?? 0}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── DELETE CHALLAN (single or enable multiple) ───────────────────────
  Future<void> _deleteChallan(int challanId) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          title: const Text('Delete Challan'),
          content: const Text('Choose an action:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'multiple'),
              child: const Text(
                'Delete Multiple',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'single'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete This',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    // ── MULTIPLE
    if (action == 'multiple') {
      setState(() {
        _selectionMode = true;
        final idStr = challanId.toString();
        if (!_selectedIds.contains(idStr)) _selectedIds.add(idStr);
      });
      return;
    }

    // ── SINGLE
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Delete this challan permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final success = await challanApi.deleteChallan(challanId);
    setState(() => _isLoading = false);

    if (success) {
      showSuccessToast(context, "Challan deleted successfully");
      await _fetchChallans();
    } else {
      showErrorToast(context, "Failed to delete challan");
    }
  }

  // ── DELETE MULTIPLE CHALLANS IN ONE API CALL ───────────────────────
  Future<void> _deleteMultipleChallans() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Multiple Challans'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} selected challans?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    // Convert string IDs to int
    final List<int> idsToDelete = _selectedIds
        .map((id) => int.tryParse(id))
        .where((id) => id != null)
        .cast<int>()
        .toList();

    final success = await challanApi.deleteMultipleChallans(idsToDelete);

    setState(() {
      _isLoading = false;
      _selectedIds.clear();
      _selectionMode = false;
    });

    await _fetchChallans();

    if (success) {
      showSuccessToast(context, "All selected challans deleted successfully");
    } else {
      showErrorToast(context, "Failed to delete some or all challans");
    }
  }

  Future<void> _editChallan(Map<String, dynamic> challanRow) async {
    if (challanRow['id'] == null) {
      showErrorToast(context, "Invalid challan data");
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallanScreen(challanData: challanRow),
      ),
    );
  }

  Future<void> _generateAndPrintPdf(Map<String, dynamic> challan) async {
    final pdf = pw.Document();

    final dateStr = challan['date'] as String?;
    final displayDate =
        dateStr != null && dateStr.isNotEmpty && dateStr != 'null'
        ? dateStr
        : 'N/A';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "Challan Details",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Customer Name: ${challan['name'] ?? 'N/A'}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Type: ${challan['type'] ?? 'N/A'}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Location: ${challan['location'] ?? 'N/A'}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Quantity: ${challan['qty'] ?? '0'}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Date: $displayDate",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  "Generated by Snowcool Trading Co.",
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/challan_${challan['id']}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    showSuccessToast(context, "PDF generated successfully");
  }

  @override
  void initState() {
    super.initState();

    if (widget.type != null) {
      final normalized = widget.type!.toLowerCase();
      if (normalized == 'received') {
        _selectedType = 'Received';
      } else if (normalized == 'delivered') {
        _selectedType = 'Delivered';
      }
    }
    _fetchChallans();
  }

  Future<void> _fetchChallans() async {
    setState(() => _isLoading = true);
    try {
      final fetchedData = await challanApi.fetchAllChallans();
      setState(() {
        _challans = fetchedData;
        _filteredData = _challans;
        _isLoading = false;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load challans: $e");
      setState(() => _isLoading = false);
    }
  }

  void applyFilters(String query, dynamic type) {
    setState(() {
      _filteredData = _challans.where((customer) {
        final matchesName =
            (customer['name'] as String?)?.toLowerCase().contains(
              query.toLowerCase(),
            ) ??
            false;
        final matchesType = type == 'All' || (customer['type'] ?? '') == type;
        return matchesName && matchesType;
      }).toList();
    });
  }

  Color _getTypeColor(dynamic type) {
    final String? typeStr = type?.toString().toUpperCase();
    if (typeStr == 'RECEIVED') {
      return Colors.green;
    } else if (typeStr == 'DELIVERED') {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_selectedIds.isEmpty && _selectionMode) {
      _selectionMode = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredCustomers.length / _rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Details'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChallanScreen()),
              );
            },
            child: Container(
              height: 30,
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromRGBO(0, 140, 192, 1),
              ),
              child: const Center(
                child: Text(
                  "Add Challan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
        onRefresh: _fetchChallans,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Filter Section
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            // crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 225,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    labelText: 'Search by Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _selectedType,
                                items: ['All', 'Received', 'Delivered']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedType = val!),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(
                                    0,
                                    140,
                                    192,
                                    1,
                                  ),
                                ),
                                onPressed: _pickFromDate,
                                icon: const Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _fromDate == null
                                      ? "From Date"
                                      : DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_fromDate!),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(
                                    0,
                                    140,
                                    192,
                                    1,
                                  ),
                                ),
                                onPressed: _pickToDate,
                                icon: const Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _toDate == null
                                      ? "To Date"
                                      : DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_toDate!),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              if (_selectedIds.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(
                                      0,
                                      140,
                                      192,
                                      1,
                                    ),
                                  ),
                                  onPressed: () {
                                    showSuccessToast(
                                      context,
                                      "Printing ${_selectedIds.length} selected records...",
                                    );
                                    // TODO: Implement bulk print
                                  },
                                  icon: const Icon(
                                    Icons.print,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Print Multiple",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              if (_selectedIds.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: _deleteMultipleChallans,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Delete Multiple",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = constraints.maxWidth;
                            final double fixedColumnWidth = (screenWidth * 0.5)
                                .clamp(150, 350);
                            return Row(
                              children: [
                                // Name Column (Fixed Width)
                                Container(
                                  width: fixedColumnWidth,
                                  decoration: BoxDecoration(
                                    // border: Border.all(
                                    //   color: Colors.grey.shade300,
                                    // ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 50,
                                        color: Colors.grey.shade50,
                                        child: Row(
                                          children: [
                                            if (_selectionMode)
                                              SizedBox(
                                                width: 50,
                                                child: Center(
                                                  child: Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        width: 2,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const Expanded(
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 40),
                                                  Text(
                                                    'Name',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color.fromRGBO(
                                                        0,
                                                        140,
                                                        192,
                                                        1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ..._paginatedCustomers.map((row) {
                                        final isSelected = _selectedIds
                                            .contains(row['id'].toString());
                                        return Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue.shade50
                                                : null,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (_selectionMode)
                                                SizedBox(
                                                  width: 50,
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    onChanged: (_) =>
                                                        _toggleSelect(
                                                          row['id'].toString(),
                                                        ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 25,
                                                      ),
                                                  child: Text(
                                                    row['name'] ?? 'N/A',
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),

                                // Data Columns
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 750,
                                      ),
                                      child: SizedBox(
                                        width: 750,
                                        child: Column(
                                          children: [
                                            // Header
                                            Container(
                                              height: 50,
                                              color: Colors.grey.shade50,
                                              child: Row(
                                                children: const [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Center(
                                                      child: Text(
                                                        'Type',
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
                                                        'Location',
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
                                                    width: 50,
                                                    child: Center(
                                                      child: Text(
                                                        'Qty',
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
                                                        'Date',
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
                                                  Expanded(
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
                                            ..._paginatedCustomers.map((row) {
                                              final isSelected = _selectedIds
                                                  .contains(
                                                    row['id'].toString(),
                                                  );
                                              return Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.blue.shade50
                                                      : null,
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 100,
                                                      child: Center(
                                                        child: Text(
                                                          (row['type']
                                                                  ?.toString()
                                                                  .toUpperCase() ??
                                                              'N/A'),
                                                          style: TextStyle(
                                                            color:
                                                                _getTypeColor(
                                                                  row['type'],
                                                                ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 200,
                                                      child: Center(
                                                        child: Text(
                                                          row['location'] ??
                                                              'N/A',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 50,
                                                      child: Center(
                                                        child: Text(
                                                          row['qty']
                                                                  ?.toString() ??
                                                              '0',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150,
                                                      child: Center(
                                                        child: Text(
                                                          row['date'] != null &&
                                                                  row['date'] !=
                                                                      'null'
                                                              ? row['date']
                                                                    .toString()
                                                              : 'N/A',
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          IconButton(
                                                            onPressed: () {
                                                              final id =
                                                                  int.tryParse(
                                                                    row['id']
                                                                        .toString(),
                                                                  ) ??
                                                                  0;
                                                              _showUserGoodsDetails(
                                                                id,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              CupertinoIcons
                                                                  .doc_text_search,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    0,
                                                                    140,
                                                                    192,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              CupertinoIcons
                                                                  .square_pencil_fill,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    0,
                                                                    140,
                                                                    192,
                                                                    1,
                                                                  ),
                                                            ),
                                                            tooltip: 'Edit',
                                                            onPressed: () =>
                                                                _editChallan(
                                                                  row,
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              CupertinoIcons
                                                                  .bin_xmark_fill,
                                                              color: Colors.red,
                                                            ),
                                                            tooltip: 'Delete',
                                                            onPressed: () {
                                                              final id =
                                                                  int.tryParse(
                                                                    row['id']
                                                                        .toString(),
                                                                  ) ??
                                                                  0;
                                                              _deleteChallan(
                                                                id,
                                                              );
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              CupertinoIcons
                                                                  .square_arrow_up,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    0,
                                                                    140,
                                                                    192,
                                                                    1,
                                                                  ),
                                                            ),
                                                            onPressed: () {
                                                              Share.share(
                                                                'Challan: ${row['name']} - ${row['type']} on ${row['date']}',
                                                              );
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              CupertinoIcons
                                                                  .floppy_disk,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    0,
                                                                    140,
                                                                    192,
                                                                    1,
                                                                  ),
                                                            ),
                                                            onPressed: () =>
                                                                _generateAndPrintPdf(
                                                                  row,
                                                                ),
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
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Pagination
                Container(
                  color: const Color(0xFFB3E0F2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text('Page ${_currentPage + 1} of $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading) customLoader(),
          ],
        ),
      ),
    );
  }
}
