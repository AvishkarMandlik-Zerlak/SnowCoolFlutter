import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PassBookScreen extends StatefulWidget {
  const PassBookScreen({super.key});

  @override
  State<PassBookScreen> createState() => _PassBookScreenState();
}

class _PassBookScreenState extends State<PassBookScreen> {
  List<Map<String, dynamic>> _allStock = [];
  List<Map<String, dynamic>> _filteredStock = [];
  List<Map<String, dynamic>> _paginatedStock = [];

  final int _rowsPerPage = 10;
  int _currentPage = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _allStock = [
      {
        'id': 1,
        'product_name': 'Small Floron Cylinder',
        'sr_no': 101,
        'date': '2025-11-10',
        'receive': 60,
        'deliver': 25,
      },
      {
        'id': 2,
        'product_name': 'Large Oxygen Cylinder 40L',
        'sr_no': 102,
        'date': '2025-11-10',
        'receive': 35,
        'deliver': 18,
      },
      {
        'id': 3,
        'product_name': 'Medical Oxygen 10L',
        'sr_no': 103,
        'date': '2025-11-09',
        'receive': 90,
        'deliver': 50,
      },
      {
        'id': 4,
        'product_name': 'Portable Oxygen Concentrator 5L',
        'sr_no': 104,
        'date': '2025-11-08',
        'receive': 28,
        'deliver': 12,
      },
      {
        'id': 5,
        'product_name': 'Nasal Cannula Adult',
        'sr_no': 105,
        'date': '2025-11-07',
        'receive': 250,
        'deliver': 200,
      },
      {
        'id': 6,
        'product_name': 'Humidifier Bottle 350ml',
        'sr_no': 106,
        'date': '2025-11-06',
        'receive': 120,
        'deliver': 80,
      },
      {
        'id': 7,
        'product_name': 'Oxygen Mask Non-Rebreather',
        'sr_no': 107,
        'date': '2025-11-05',
        'receive': 180,
        'deliver': 110,
      },
      {
        'id': 8,
        'product_name': 'Flowmeter Regulator 0-15LPM',
        'sr_no': 108,
        'date': '2025-11-04',
        'receive': 45,
        'deliver': 30,
      },
      {
        'id': 9,
        'product_name': 'Oxygen Tubing 7ft',
        'sr_no': 109,
        'date': '2025-11-03',
        'receive': 350,
        'deliver': 290,
      },
      {
        'id': 10,
        'product_name': 'BIPAP Full Face Mask',
        'sr_no': 110,
        'date': '2025-11-02',
        'receive': 22,
        'deliver': 10,
      },
      {
        'id': 11,
        'product_name': 'CPAP Nasal Mask Medium',
        'sr_no': 111,
        'date': '2025-11-01',
        'receive': 40,
        'deliver': 20,
      },
      {
        'id': 12,
        'product_name': 'Pulse Oximeter Fingertip',
        'sr_no': 112,
        'date': '2025-10-31',
        'receive': 150,
        'deliver': 95,
      },
      {
        'id': 13,
        'product_name': 'Suction Catheter 14Fr',
        'sr_no': 113,
        'date': '2025-10-30',
        'receive': 400,
        'deliver': 330,
      },
      {
        'id': 14,
        'product_name': 'Ambu Bag Adult Silicone',
        'sr_no': 114,
        'date': '2025-10-29',
        'receive': 38,
        'deliver': 18,
      },
      {
        'id': 15,
        'product_name': 'Oxygen Cylinder Trolley',
        'sr_no': 115,
        'date': '2025-10-28',
        'receive': 20,
        'deliver': 10,
      },
      {
        'id': 16,
        'product_name': 'Nebulizer Kit Adult',
        'sr_no': 116,
        'date': '2025-10-27',
        'receive': 85,
        'deliver': 60,
      },
      {
        'id': 17,
        'product_name': 'High Flow Nasal Cannula',
        'sr_no': 117,
        'date': '2025-10-26',
        'receive': 55,
        'deliver': 25,
      },
      {
        'id': 18,
        'product_name': 'Digital BP Monitor',
        'sr_no': 118,
        'date': '2025-10-25',
        'receive': 70,
        'deliver': 40,
      },
    ];
    _allStock.sort((a, b) => b['date'].compareTo(a['date']));

    _filteredStock = List.from(_allStock);
    _updatePaginated();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────
  void _onSearch(String query) {
    _searchQuery = query;
    _filteredStock = _allStock
        .where(
          (item) => item['product_name'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();

    _currentPage = 0; // reset to first page
    _updatePaginated();
  }

  void _updatePaginated() {
    final sortedFiltered = List.from(_filteredStock)
      ..sort((a, b) => a['date'].compareTo(b['date'])); // Oldest → Newest

    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, sortedFiltered.length);
    final sliced = sortedFiltered.sublist(start, end);

    _paginatedStock = sliced.map((e) => Map<String, dynamic>.from(e)).toList();

    int running = 0;
    final balanceMap = <int, int>{}; // id → balance

    for (var item in sortedFiltered) {
      running += (item['receive'] as int) - (item['deliver'] as int);
      balanceMap[item['id'] as int] = running;
    }

    for (var item in _paginatedStock) {
      item['running_balance'] = balanceMap[item['id'] as int] ?? 0;
    }

    setState(() {});
  }

  void _onEdit(Map<String, dynamic> item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit: ${item['product_name']}')));
  }

  void _onDelete(Map<String, dynamic> item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Delete: ${item['product_name']}')));
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _filteredStock.isEmpty
        ? 1
        : (_filteredStock.length / _rowsPerPage).ceil();
    const blueColor = Color.fromRGBO(0, 140, 192, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Passbook',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: blueColor,
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                hintText: "Search product...",
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color.fromRGBO(156, 156, 156, 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(156, 156, 156, 1),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(0, 140, 192, 1),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    // border: Border(
                    //   right: BorderSide(color: Colors.grey.shade300),
                    // ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        color: blueColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Product Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _paginatedStock.length,
                          itemBuilder: (_, i) {
                            final item = _paginatedStock[i];
                            return Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Text(
                                item['product_name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width:
                          140 + 90 + 120 + 120 + 150 + 200,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            height: 56,
                            color: blueColor,
                            child: Row(
                              children: [
                                _headerCell('Date', 140),
                                _headerCell('Sr No', 90),
                                _headerCell('Deliver', 120),
                                _headerCell('Receive', 120),
                                _headerCell('Balance', 150),
                                _headerCell('Action', 200),
                              ],
                            ),
                          ),
                          // Body
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _paginatedStock.length,
                              itemBuilder: (_, i) {
                                final item = _paginatedStock[i];
                                final deliver = item['deliver'] ?? 0;
                                final receive = item['receive'] ?? 0;
                                final balance = item['running_balance'] ?? 0;

                                return Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _dataCell(
                                        DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(DateTime.parse(item['date'])),
                                        140,
                                      ),
                                      _dataCell(item['sr_no'].toString(), 90),
                                      _dataCell(
                                        deliver.toString(),
                                        120,
                                        color: Colors.red.shade700,
                                      ),
                                      _dataCell(
                                        receive.toString(),
                                        120,
                                        color: Colors.green.shade700,
                                      ),
                                      _dataCell(
                                        balance.toString(),
                                        150,
                                        color: balance >= 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        bold: true,
                                      ),
                                      SizedBox(
                                        width: 200,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () {},
                                              icon: Image.asset(
                                                "assets/images/passbook.png",
                                              ),
                                              tooltip: 'View Passbook',
                                            ),
                                            // IconButton(
                                            //   icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                            //   onPressed: () => _onEdit(item),
                                            //   tooltip: 'Edit',
                                            // ),
                                            // IconButton(
                                            //   icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            //   onPressed: () => _onDelete(item),
                                            //   tooltip: 'Delete',
                                            // ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: const Color(0xFFB3E0F2),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() => _currentPage--);
                          _updatePaginated();
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: _currentPage < totalPages - 1
                      ? () {
                          setState(() => _currentPage++);
                          _updatePaginated();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width, {
    Color? color,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            color: color ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}