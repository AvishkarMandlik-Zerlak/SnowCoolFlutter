// view_challan.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';

class ViewChallanScreen extends StatefulWidget {
  const ViewChallanScreen({super.key});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {
  final TextEditingController searchController = TextEditingController();

  late ChallanDataSource _dataSource;

  int _rowsPerPage = 5;
  List<int> _availableRowsPerPage = [5, 10, 20];
  final double headingHeight = 56;
  final double dataRowHeight = 64;

  String selectedType = 'All';

  DateTime? fromDate;
  DateTime? toDate;
  final ChallanApi challanApi = ChallanApi();
  List<Map<String, dynamic>> _challanList = [];
  bool _isLoading = true;

  int _tableRebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _fetchChallans();
  }

  Future<void> _fetchChallans() async {
    setState(() => _isLoading = true);
    try {
      final data = await challanApi.fetchAllChallans();
      setState(() {
        _challanList = data;
        _dataSource = ChallanDataSource(
          _challanList,
          challanApi,
          context,
          _fetchChallans, // Pass refresh callback
        );
        _updatePagination();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load challans: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    final type = selectedType;

    setState(() {
      _dataSource.applyFilters(query, type);
      _updatePagination();
    });
  }

  void _resetFilters() {
    searchController.clear();
    selectedType = 'All';
    _dataSource.applyFilters('', 'All');
    _updatePagination();
    setState(() => _tableRebuildKey++);
  }

  void _updatePagination() {
    final totalRows = _dataSource.rowCount;

    if (totalRows == 0) {
      _rowsPerPage = 1;
      _availableRowsPerPage = [1];
    } else if (totalRows <= 8) {
      _rowsPerPage = totalRows;
      _availableRowsPerPage = [totalRows];
    } else if (totalRows <= 10) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10];
    } else if (totalRows <= 15) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 15];
    } else if (totalRows <= 20) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 20];
    } else {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 20, 50];
    }

    _tableRebuildKey++;
    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final pickedFrom = await showDatePicker(
      context: context,
      initialDate: fromDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      helpText: 'Select Start Date',
    );

    if (pickedFrom == null) return;

    final pickedTo = await showDatePicker(
      context: context,
      initialDate: toDate ?? pickedFrom,
      firstDate: pickedFrom,
      lastDate: DateTime(2026),
      helpText: 'Select End Date',
    );

    if (pickedTo == null) return;

    setState(() {
      fromDate = pickedFrom;
      toDate = pickedTo;
      _filterByDate();
    });
  }

  void _filterByDate() {
    if (fromDate == null || toDate == null) return;

    final filtered = _challanList.where((challan) {
      final date = DateTime.parse(challan['date']);
      return date.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate!.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _dataSource = ChallanDataSource(
        filtered,
        challanApi,
        context,
        _fetchChallans,
      );
      _updatePagination();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Details'),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChallanScreen()),
              );
            },
            child: Container(
              height: 30,
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromRGBO(0, 140, 192, 1),
              ),
              child: const Center(
                child: Text(
                  "Add Challan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Filters Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromRGBO(156, 156, 156, 1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(156, 156, 156, 1)),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(156, 156, 156, 1)),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      hintText: 'Search by Customer Name',
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color.fromRGBO(0, 140, 192, 1)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedType,
                    icon: const Icon(Icons.filter_list_outlined),
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Receive', child: Text('Receive')),
                      DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedType = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color.fromRGBO(0, 140, 192, 1)),
                    ),
                    child: const Row(
                      children: [
                        Text("Date", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dynamic Table
            LayoutBuilder(
              builder: (context, constraints) {
                final totalRows = _dataSource.rowCount;
                final visibleRows = totalRows < _rowsPerPage ? totalRows : _rowsPerPage;
                final tableHeight = headingHeight + (visibleRows * dataRowHeight) + 70;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: tableHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromRGBO(238, 238, 238, 1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PaginatedDataTable2(
                    key: ValueKey(_tableRebuildKey),
                    source: _dataSource,
                    rowsPerPage: _rowsPerPage,
                    availableRowsPerPage: _availableRowsPerPage,
                    onRowsPerPageChanged: (value) {
                      if (value == null) return;
                      setState(() => _rowsPerPage = value);
                    },
                    header: null,
                    wrapInCard: false,
                    headingRowColor: WidgetStateProperty.all(const Color.fromRGBO(238, 238, 238, 1)),
                    showFirstLastButtons: true,
                    headingRowHeight: headingHeight,
                    dataRowHeight: dataRowHeight,
                    fixedLeftColumns: 1,
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(
                        label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 140, 192, 1))),
                      ),
                      DataColumn2(
                        fixedWidth: 80,
                        label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 140, 192, 1))),
                      ),
                      DataColumn2(
                        label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 140, 192, 1))),
                      ),
                      DataColumn2(
                        fixedWidth: 60,
                        label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 140, 192, 1))),
                      ),
                      DataColumn2(
                        fixedWidth: 200,
                        label: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 140, 192, 1))),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Data Source ==========
class ChallanDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _originalData;
  List<Map<String, dynamic>> _filteredData = [];
  final ChallanApi _api;
  final BuildContext context;
  final VoidCallback onRefresh;

  ChallanDataSource(this._originalData, this._api, this.context, this.onRefresh) {
    _filteredData = List.from(_originalData);
  }

  void applyFilters(String query, String type) {
    _filteredData = _originalData.where((challan) {
      final matchesName = challan['name'].toString().toLowerCase().contains(query);
      final matchesType = type == 'All' || challan['type'] == type;
      return matchesName && matchesType;
    }).toList();
    notifyListeners();
  }

  Future<void> _deleteChallan(String challanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challan'),
        content: const Text('Are you sure you want to delete this challan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _api.deleteChallan(int.parse(challanId));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challan deleted successfully'), backgroundColor: Colors.green),
      );
      onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete challan'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editChallan(String challanId) async {
    final controller = TextEditingController();

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Customer Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      final challan = await _api.getChallan(int.parse(challanId));
      challan['customerName'] = newName;

      final success = await _api.updateChallan(int.parse(challanId), challan);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challan updated successfully'), backgroundColor: Colors.green),
        );
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update challan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _filteredData.length) return null;
    final challan = _filteredData[index];

    return DataRow(
      cells: [
        DataCell(Text(challan['name'] ?? '')),
        DataCell(Text(challan['type'] ?? '')),
        DataCell(Text(challan['location'] ?? '')),
        DataCell(Text(challan['qty'] ?? '')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: Colors.blue,
                onPressed: () => _editChallan(challan['id']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: () => _deleteChallan(challan['id']),
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                color: Colors.green,
                onPressed: () {
                  final text = '''
Challan ID: ${challan['id']}
Customer: ${challan['name']}
Type: ${challan['type']}
Location: ${challan['location']}
Total Qty: ${challan['qty']}
Date: ${challan['date']}
                  '''.trim();
                  Share.share(text, subject: 'Challan Details');
                },
              ),
              IconButton(
                icon: const Icon(Icons.print, size: 18),
                color: Colors.orange,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print feature coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => _filteredData.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}