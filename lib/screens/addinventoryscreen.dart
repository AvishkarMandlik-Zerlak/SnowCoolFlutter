import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/services/goods_api.dart';

class Addinventoryscreen extends StatefulWidget {
  const Addinventoryscreen({super.key});

  @override
  State<Addinventoryscreen> createState() => _AddinventoryscreenState();
}

class _AddinventoryscreenState extends State<Addinventoryscreen> {
  final TextEditingController _productNameCtrl = TextEditingController();
  final GoodsApi _api = GoodsApi();

  // Selection state
  GoodsDTO? _selectedProduct;
  bool _isManuallyEdited = false;
  bool _inEditMode = false;
  int? _editingId;

  // Goods list state
  List<GoodsDTO> _allGoods = [];
  List<GoodsDTO> _filteredGoods = [];
  bool _goodsLoading = true;
  String _goodsError = '';

  @override
  void initState() {
    super.initState();
    _loadGoods();
  }

  Future<void> _loadGoods() async {
    setState(() {
      _goodsLoading = true;
      _goodsError = '';
    });
    try {
      final goods = await _api.getAllGoods();
      setState(() {
        _allGoods = goods;
        _filteredGoods = goods;
        _goodsLoading = false;
      });
    } catch (e) {
      setState(() {
        _goodsLoading = false;
        _goodsError = 'Failed to load items';
      });
    }
  }

  void _filterGoods(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredGoods = _allGoods
          .where((g) => g.name.toLowerCase().contains(q))
          .toList();
      if (_selectedProduct != null) {
        _isManuallyEdited =
            _productNameCtrl.text.trim() != _selectedProduct!.name;
      }
    });
  }

  // Note: selection via list was removed with the plus button.

  void _resetForm() {
    _productNameCtrl.clear();
    setState(() {
      _selectedProduct = null;
      _isManuallyEdited = false;
      _filteredGoods = _allGoods;
    });
  }

  Future<void> _saveProductName() async {
    final productName = _productNameCtrl.text.trim();

    if (productName.isEmpty) {
      showWarningToast(context, "Please enter or select a product");
      return;
    }
    if (productName.length < 2) {
      showWarningToast(context, "Product name must be at least 2 characters");
      return;
    }

    if (_selectedProduct != null && _isManuallyEdited && !_inEditMode) {
      showWarningToast(
        context,
        "Cannot save: You edited the selected product name",
      );
      return;
    }

    try {
      bool success;
      if (_inEditMode && _editingId != null) {
        success = await _api.updateGood(_editingId!, productName);
      } else {
        success = await _api.goods(productName);
      }
      if (success) {
        showSuccessToast(
          context,
          _inEditMode ? "Product updated" : "Product saved successfully",
        );
        _resetForm();
        await _loadGoods();
      } else {
        showWarningToast(
          context,
          _inEditMode ? "Unable to update product" : "Unable to save product",
        );
      }
    } catch (e) {
      showErrorToast(context, "Connection failed. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Inventory"),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color.fromRGBO(0, 140, 192, 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name Field
            const Text(
              "Items Name",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(0, 140, 192, 1),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productNameCtrl,
              onChanged: _filterGoods,
              decoration: InputDecoration(
                hintText: "Enter or select product name",
                hintStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(147, 148, 150, 1),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black87,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Checkmark when selected & not edited
                    if (_selectedProduct != null && !_isManuallyEdited)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    // Clear button
                    if (_productNameCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _productNameCtrl.clear();
                          _filterGoods('');
                          setState(() => _isManuallyEdited = false);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Suggested Products Label
            const Text(
              "Or select from below:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Loading / Error State
            if (_goodsLoading)
              const Center(child: CircularProgressIndicator())
            else if (_goodsError.isNotEmpty)
              Center(
                child: Text(
                  _goodsError,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 140, 192, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Product Name",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        "Action",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Products List (Scrollable)
            if (!_goodsLoading && _goodsError.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredGoods.length,
                  itemBuilder: (context, index) {
                    final product = _filteredGoods[index];
                    final isSelected = _selectedProduct?.id == product.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromRGBO(0, 140, 192, 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color.fromRGBO(0, 140, 192, 1)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    CupertinoIcons.square_pencil_fill,
                                    color: Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    setState(() {
                                      _inEditMode = true;
                                      _editingId = product.id;
                                      _selectedProduct = product;
                                      _productNameCtrl.text = product.name;
                                      _isManuallyEdited = false;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.bin_xmark_fill,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Product'),
                                        content: Text(
                                          'Delete "${product.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && product.id != null) {
                                      final removed = await _api.deleteGood(
                                        product.id!,
                                      );
                                      if (removed) {
                                        showSuccessToast(
                                          context,
                                          'Product deleted',
                                        );
                                        await _loadGoods();
                                      } else {
                                        showWarningToast(
                                          context,
                                          'Delete failed',
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Save Button
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _resetForm,
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
                    onTap: _saveProductName,
                    child: Container(
                      height: 56,
                      width: MediaQuery.of(context).size.width / 2.3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: (_isManuallyEdited && _selectedProduct != null)
                            ? Colors.grey
                            : const Color.fromRGBO(0, 140, 192, 1),
                      ),
                      child: const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}
