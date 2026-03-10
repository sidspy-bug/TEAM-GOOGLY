import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../repositories/api_sales_repository.dart';
import '../l10n/app_localizations.dart';

/// Screen for manually adding products or recording sales without OCR.
class ManualEntryScreen extends StatefulWidget {
  /// 'product' to add/restock a product, 'sale' to record a sale.
  final String mode;
  const ManualEntryScreen({super.key, required this.mode});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // ── Product mode fields ──
  final _nameCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  String _category = 'General';

  // ── Sale mode fields ──
  final _qtyCtrl = TextEditingController(text: '1');
  String _transactionMode = 'Cash';
  int? _selectedProductId;
  List<Map<String, dynamic>> _existingProducts = [];
  bool _loadingProducts = false;

  // Shared state
  bool _isSaving = false;
  String? _error;
  String? _successMsg;

  static const _categories = [
    'General', 'Grocery', 'Dairy', 'Beverages', 'Snacks',
    'Personal Care', 'Stationery', 'Electronics', 'Clothing', 'Other',
  ];

  static const _txModes = ['Cash', 'UPI', 'Card'];

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'sale') _fetchProducts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costPriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _stockCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final data = await _api.get('/products/list');
      final list = data is List ? data : [];
      setState(() {
        _existingProducts = list
            .whereType<Map<String, dynamic>>()
            .where((p) => p['id'] != null)
            .toList();
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _loadingProducts = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; _error = null; _successMsg = null; });

    try {
      if (widget.mode == 'product') {
        await _addProduct();
      } else {
        await _recordSale();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addProduct() async {
    final name = _nameCtrl.text.trim();
    final cp = double.parse(_costPriceCtrl.text.trim());
    final sp = double.parse(_sellingPriceCtrl.text.trim());
    final stock = int.parse(_stockCtrl.text.trim());

    // Check if product already exists
    List<dynamic> existingProducts = [];
    try {
      final data = await _api.get('/products/list');
      existingProducts = data is List ? data : [];
    } catch (_) {}

    String normalized(String v) => v.trim().toLowerCase();
    Map<String, dynamic>? existing;
    for (final row in existingProducts) {
      if (row is Map<String, dynamic> &&
          normalized((row['productName'] ?? '').toString()) == normalized(name)) {
        existing = row;
        break;
      }
    }

    dynamic productId;
    if (existing != null && existing['id'] != null) {
      productId = existing['id'];
      await _api.put('/products/update/$productId', body: {
        'productName': name,
        'category': _category,
        'costPrice': cp,
        'sellingPrice': sp,
      });
    } else {
      final created = await _api.post('/products/add', body: {
        'productName': name,
        'category': _category,
        'costPrice': cp,
        'sellingPrice': sp,
      });
      productId = created['id'];
    }

    if (productId == null) {
      setState(() => _error = 'Failed to get product ID');
      return;
    }

    await _api.post('/inventory/add', body: {
      'productId': productId,
      'stockAdded': stock,
    });

    ApiSalesRepository().clearCache();
    final l = AppLocalizations.of(context);
    setState(() {
      _successMsg = l.productAddedSuccess;
      _nameCtrl.clear();
      _costPriceCtrl.clear();
      _sellingPriceCtrl.clear();
      _stockCtrl.text = '1';
      _category = 'General';
    });
  }

  Future<void> _recordSale() async {
    if (_selectedProductId == null) {
      setState(() => _error = AppLocalizations.of(context).selectProduct);
      return;
    }

    final qty = int.parse(_qtyCtrl.text.trim());

    await _api.post('/transactions/sell', body: {
      'productId': _selectedProductId,
      'unitsSold': qty,
      'transactionMode': _transactionMode,
    });

    ApiSalesRepository().clearCache();
    final l = AppLocalizations.of(context);
    setState(() {
      _successMsg = l.saleRecordedSuccess;
      _qtyCtrl.text = '1';
      _selectedProductId = null;
      _transactionMode = 'Cash';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isProduct = widget.mode == 'product';
    final mobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProduct ? l.addProduct : l.recordSale),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isProduct ? Icons.add_shopping_cart : Icons.point_of_sale,
                            color: Colors.indigo.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isProduct ? l.addProduct : l.recordSale,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isProduct
                                      ? l.addProductDesc
                                      : l.recordSaleDesc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status messages
                  if (_error != null)
                    _statusBanner(
                      _error!,
                      Colors.red.shade50,
                      Colors.red.shade200,
                      Icons.error_outline,
                      Colors.red.shade700,
                    ),
                  if (_successMsg != null)
                    _statusBanner(
                      _successMsg!,
                      Colors.green.shade50,
                      Colors.green.shade200,
                      Icons.check_circle,
                      Colors.green.shade700,
                    ),

                  // Form fields
                  if (isProduct) ..._productFields(l) else ..._saleFields(l),

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isProduct ? Icons.save : Icons.receipt),
                    label: Text(
                      _isSaving
                          ? l.loading
                          : (isProduct ? l.addProduct : l.recordSale),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _productFields(AppLocalizations l) => [
        TextFormField(
          controller: _nameCtrl,
          decoration: _inputDecoration(l.productNameLabel, Icons.label_outline),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _category,
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? 'General'),
          decoration: _inputDecoration(l.category, Icons.category_outlined),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _costPriceCtrl,
          decoration: _inputDecoration(l.costPrice, Icons.money_outlined,
              prefix: '₹ '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.fieldRequired;
            if (double.tryParse(v.trim()) == null) return l.enterValidNumber;
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _sellingPriceCtrl,
          decoration: _inputDecoration(l.sellingPriceLabel, Icons.sell_outlined,
              prefix: '₹ '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.fieldRequired;
            if (double.tryParse(v.trim()) == null) return l.enterValidNumber;
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _stockCtrl,
          decoration: _inputDecoration(l.initialStock, Icons.inventory_2_outlined),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.fieldRequired;
            final n = int.tryParse(v.trim());
            if (n == null || n < 0) return l.enterValidNumber;
            return null;
          },
        ),
      ];

  List<Widget> _saleFields(AppLocalizations l) => [
        if (_loadingProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_existingProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l.noProductsAvailable,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedProductId,
            items: _existingProducts.map((p) {
              final id = p['id'] as int;
              final name = (p['productName'] ?? 'Unknown').toString();
              return DropdownMenuItem(value: id, child: Text(name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedProductId = v),
            decoration: _inputDecoration(l.selectProduct, Icons.shopping_bag_outlined),
            validator: (v) => v == null ? l.fieldRequired : null,
          ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _qtyCtrl,
          decoration: _inputDecoration(l.quantityLabel, Icons.numbers),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.fieldRequired;
            final n = int.tryParse(v.trim());
            if (n == null || n <= 0) return l.enterValidNumber;
            return null;
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _transactionMode,
          items: _txModes
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) =>
              setState(() => _transactionMode = v ?? 'Cash'),
          decoration:
              _inputDecoration(l.transactionMode, Icons.payment_outlined),
        ),
      ];

  InputDecoration _inputDecoration(String label, IconData icon,
          {String? prefix}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _statusBanner(String msg, Color bg, Color border, IconData icon,
          Color iconColor) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: TextStyle(color: iconColor, fontSize: 13)),
            ),
          ],
        ),
      );
}
