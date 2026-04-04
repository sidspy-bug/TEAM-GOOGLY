import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../repositories/api_sales_repository.dart';

/// Editable product row parsed from OCR.
class ParsedProduct {
  TextEditingController nameCtrl;
  TextEditingController costPriceCtrl;
  TextEditingController sellingPriceCtrl;
  TextEditingController quantityCtrl;
  String category;
  bool selected;

  ParsedProduct({
    required String name,
    required double costPrice,
    required double sellingPrice,
    required int quantity,
    this.category = 'General',
    this.selected = true,
  })  : nameCtrl = TextEditingController(text: name),
        costPriceCtrl =
            TextEditingController(text: costPrice > 0 ? costPrice.toStringAsFixed(2) : ''),
        sellingPriceCtrl = TextEditingController(
            text: sellingPrice > 0 ? sellingPrice.toStringAsFixed(2) : ''),
        quantityCtrl = TextEditingController(text: quantity.toString());

  void dispose() {
    nameCtrl.dispose();
    costPriceCtrl.dispose();
    sellingPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}

/// OCR Screen — scan an image, extract & parse products, save to inventory.
class OcrScreen extends StatefulWidget {
  final String mode; // 'purchase' or 'sale'
  final VoidCallback? onSaveSuccess;
  const OcrScreen({super.key, this.mode = 'purchase', this.onSaveSuccess});
  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _rawText;
  String? _vendorName;
  String? _extractedDate;
  List<ParsedProduct> _products = [];
  bool _isProcessing = false;
  bool _isSaving = false;
  String? _successMsg;
  // Consolidated error tracking
  List<String> _errorMessages = [];
  int _notFoundCount = 0;

  static const _categories = [
    'General', 'Grocery', 'Dairy', 'Beverages', 'Snacks',
    'Personal Care', 'Stationery', 'Electronics', 'Clothing', 'Other',
  ];

  @override
  void dispose() {
    for (final p in _products) { p.dispose(); }
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _rawText = null;
        _errorMessages = [];
        _notFoundCount = 0;
        _successMsg = null;
        for (final p in _products) { p.dispose(); }
        _products = [];
      });
      await _processImage(bytes);
    } catch (e) {
      setState(() => _errorMessages = ['Failed to pick image: $e']);
    }
  }

  // ── OCR processing ─────────────────────────────────────────────────────
  Future<void> _processImage(Uint8List bytes) async {
    setState(() { _isProcessing = true; _errorMessages = []; });
    try {
      final result = await ApiService().post('/ocr/scan', body: {
        'image': base64Encode(bytes),
      });

      final List<dynamic> parsed = result['parsedProducts'] ?? [];
      for (final p in _products) { p.dispose(); }

      setState(() {
        _rawText = result['text'] ?? '';
        _vendorName = result['vendorName'] ?? '';
        _extractedDate = result['extractedDate'] ?? '';
        _products = parsed.map((item) => ParsedProduct(
          name: item['productName'] ?? '',
          costPrice: _toDouble(item['costPrice']),
          sellingPrice: _derivedSellingPrice(item),
          quantity: (item['quantity'] ?? 1).toInt(),
        )).toList();
        _isProcessing = false;
      });
    } catch (e) {
      final message = e is ApiException ? e.message : e.toString();
      setState(() {
        _errorMessages = ['OCR processing failed: $message'];
        _isProcessing = false;
      });
    }
  }

  // ── Save to inventory ──────────────────────────────────────────────────
  Future<void> _saveToInventory() async {
    final selected = _products.where((p) => p.selected).toList();
    if (selected.isEmpty) {
      _snack('No products selected to save'); return;
    }

    final isPurchaseMode = widget.mode == 'purchase';
    final isSaleMode = widget.mode == 'sale';

    for (final p in selected) {
      if (p.nameCtrl.text.trim().isEmpty) { _snack('Product name cannot be empty'); return; }

      final qty = int.tryParse(p.quantityCtrl.text) ?? 0;
      if (qty <= 0) { _snack('Invalid quantity for "${p.nameCtrl.text}"'); return; }

      if (isPurchaseMode) {
        final cp = double.tryParse(p.costPriceCtrl.text);
        if (cp == null || cp <= 0) { _snack('Invalid cost price for "${p.nameCtrl.text}"'); return; }
      }

      if (isSaleMode) {
        final sp = double.tryParse(p.sellingPriceCtrl.text);
        if (sp == null || sp <= 0) { _snack('Enter selling price for "${p.nameCtrl.text}"'); return; }
      }
    }

    setState(() { _isSaving = true; _errorMessages = []; _notFoundCount = 0; _successMsg = null; });
    int saved = 0;
    final List<String> errs = [];
    final List<String> notFoundNames = [];

    List<dynamic> existingProducts = [];
    try {
      final data = await ApiService().get('/products/list');
      existingProducts = data is List ? data : [];
    } catch (e) {
      setState(() { _isSaving = false; _errorMessages = ['Failed to load products: $e']; });
      return;
    }

    String normalized(String v) => v.trim().toLowerCase();
    final Map<String, Map<String, dynamic>> productByName = {};
    for (final row in existingProducts) {
      if (row is! Map<String, dynamic>) continue;
      final key = normalized((row['productName'] ?? '').toString());
      if (key.isEmpty) continue;
      productByName[key] = row;
    }

    for (final p in selected) {
      try {
        final name = p.nameCtrl.text.trim();
        final qty = int.tryParse(p.quantityCtrl.text) ?? 1;
        final existing = productByName[normalized(name)];

        if (isPurchaseMode) {
          final cp = double.parse(p.costPriceCtrl.text);
          dynamic productId;

          if (existing != null && existing['id'] != null) {
            productId = existing['id'];
            final existingSp = _toDouble(existing['sellingPrice']);
            final safeSp = existingSp > 0 ? existingSp : cp;
            await ApiService().put('/products/update/$productId', body: {
              'productName': name,
              'category': p.category,
              'costPrice': cp,
              'sellingPrice': safeSp,
            });
          } else {
            final created = await ApiService().post('/products/add', body: {
              'productName': name,
              'category': p.category,
              'costPrice': cp,
              'sellingPrice': cp,
            });
            productId = created['id'];
          }

          if (productId == null) { errs.add('$name: no product ID'); continue; }
          await ApiService().post('/inventory/add', body: {
            'productId': productId,
            'stockAdded': qty,
          });
          saved++;
        } else if (isSaleMode) {
          if (existing == null || existing['id'] == null) {
            notFoundNames.add(name);
            continue;
          }
          final productId = existing['id'];
          final sp = double.parse(p.sellingPriceCtrl.text);

          await ApiService().put('/products/update/$productId', body: {
            'sellingPrice': sp,
          });

          await ApiService().post('/transactions/sell', body: {
            'productId': productId,
            'unitsSold': qty,
            'transactionMode': 'OCR',
          });
          saved++;
        }
      } catch (e) { errs.add('${p.nameCtrl.text}: $e'); }
    }

    setState(() {
      _isSaving = false;
      ApiSalesRepository().clearCache();

      // Consolidate not-found errors
      _notFoundCount = notFoundNames.length;
      _errorMessages = [];
      if (notFoundNames.isNotEmpty) {
        _errorMessages.add('${notFoundNames.length} product(s) not found in inventory.');
        _errorMessages.addAll(notFoundNames);
      }
      _errorMessages.addAll(errs);
    });

    if (saved > 0) {
      if (mounted) {
        final msg = isPurchaseMode
            ? 'Saved $saved product(s) to inventory!'
            : 'Saved $saved sale transaction(s)!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
        if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  double _derivedSellingPrice(dynamic item) {
    if (item is! Map<String, dynamic>) return 0;
    final parsedSp = _toDouble(item['sellingPrice']);
    final qty = (item['quantity'] ?? 1).toInt();
    final total = _toDouble(item['totalPrice']);
    final unitPrice = _toDouble(item['costPrice']);

    if (widget.mode != 'sale') return parsedSp;
    if (parsedSp > 0) return parsedSp;
    if (total > 0 && qty > 0) return total / qty;
    return unitPrice;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _addRow() => setState(() =>
      _products.add(ParsedProduct(name: '', costPrice: 0, sellingPrice: 0, quantity: 1)));

  void _removeRow(int i) => setState(() { _products[i].dispose(); _products.removeAt(i); });

  void _clearAll() => setState(() {
    _imageBytes = null; _rawText = null; _vendorName = null;
    _extractedDate = null; _errorMessages = []; _notFoundCount = 0; _successMsg = null;
    for (final p in _products) { p.dispose(); }
    _products = [];
  });

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasProducts = !_isProcessing && _products.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'purchase' ? 'Scan Purchase Invoice' : 'Scan Sales Invoice'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          if (_imageBytes != null)
            IconButton(icon: const Icon(Icons.clear), tooltip: 'Clear', onPressed: _clearAll),
        ],
      ),
      // Sticky save button at bottom
      bottomNavigationBar: hasProducts ? _stickyBottomBar(isDark) : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 12 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_imageBytes == null)
            _uploadArea(mobile, isDark)
          else ...[
            _imagePreview(mobile, isDark),
            const SizedBox(height: 16),
            if (_isProcessing) _processingCard(isDark),
            if (_successMsg != null) _successBanner(isDark),
            if (_errorMessages.isNotEmpty) _consolidatedErrorBanner(isDark),
            if (hasProducts) ...[
              _scanSummary(isDark),
              const SizedBox(height: 12),
              if (mobile) _productCards(isDark) else _productTable(isDark),
              const SizedBox(height: 16),
            ],
            if (!_isProcessing && _products.isEmpty && _rawText != null) _noProducts(isDark),
            if (_rawText != null && _rawText!.isNotEmpty) ...[
              const SizedBox(height: 16), _rawTextExpander(isDark),
            ],
            // Bottom padding for sticky bar
            if (hasProducts) const SizedBox(height: 80),
          ],
        ]),
      ),
    );
  }

  // ── Sticky bottom save bar ─────────────────────────────────────────────
  Widget _stickyBottomBar(bool isDark) {
    final n = _products.where((p) => p.selected).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToInventory,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving
                    ? 'Saving…'
                    : (widget.mode == 'purchase'
                        ? 'Save $n Product(s) to Inventory'
                        : 'Save $n Sale Transaction(s)'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload area ────────────────────────────────────────────────────────
  Widget _uploadArea(bool mobile, bool isDark) => Center(
    child: Container(
      width: mobile ? double.infinity : 500,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.indigo.shade100, width: 2),
      ),
      child: Column(children: [
        Icon(Icons.document_scanner_outlined, size: 64, color: Colors.indigo.shade300),
        const SizedBox(height: 16),
        const Text('Scan Invoice / Receipt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Upload a supplier invoice, receipt, or stock list.\nProducts are auto-detected with prices & quantities.',
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library), label: const Text('Choose from Gallery'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt), label: const Text('Take Photo'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Colors.indigo)),
          ),
        ]),
      ]),
    ),
  );

  // ── Image preview (collapsed) ─────────────────────────────────────────
  Widget _imagePreview(bool mobile, bool isDark) => ExpansionTile(
    leading: const Icon(Icons.image, color: Colors.indigo),
    title: const Text('Scanned Image', style: TextStyle(fontWeight: FontWeight.w600)),
    initiallyExpanded: false,
    children: [
      Padding(padding: const EdgeInsets.all(12), child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!, fit: BoxFit.contain,
            width: double.infinity, height: mobile ? 200 : 300),
      )),
      Padding(padding: const EdgeInsets.only(bottom: 8), child: TextButton.icon(
        onPressed: () => _pickImage(ImageSource.gallery),
        icon: const Icon(Icons.refresh, size: 16), label: const Text('Replace Image'),
      )),
    ],
  );

  // ── Status cards ───────────────────────────────────────────────────────
  Widget _processingCard(bool isDark) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
      child: Column(children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Scanning & extracting product data…', style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF94A3B8) : Colors.grey)),
        const SizedBox(height: 4),
        Text('This may take a few seconds', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.grey)),
      ]),
    ),
  );

  // ── Consolidated error banner ──────────────────────────────────────────
  Widget _consolidatedErrorBanner(bool isDark) {
    final hasManyErrors = _errorMessages.length > 2;
    final summaryText = _notFoundCount > 0
        ? '$_notFoundCount product(s) not found — Add them via Purchase first'
        : '${_errorMessages.length} error(s) occurred';

    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.red.shade800.withValues(alpha: 0.5) : Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(summaryText, style: TextStyle(
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ))),
              if (_imageBytes != null && _notFoundCount == 0)
                TextButton(onPressed: () => _processImage(_imageBytes!), child: const Text('Retry')),
            ]),
          ),
          if (hasManyErrors)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text('Show details (${_errorMessages.length})',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.red.shade300 : Colors.red.shade600)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errorMessages.skip(1).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red.shade600)),
                          Expanded(child: Text(e, style: TextStyle(fontSize: 12, color: isDark ? Colors.red.shade300 : Colors.red.shade700))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _successBanner(bool isDark) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: isDark ? Colors.green.shade800.withValues(alpha: 0.5) : Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(_successMsg!, style: TextStyle(color: isDark ? Colors.green.shade300 : Colors.green.shade700))),
    ]),
  );

  // ── Scan summary ───────────────────────────────────────────────────────
  Widget _scanSummary(bool isDark) => Card(
    color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Icon(Icons.receipt_long, color: Colors.indigo.shade400),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_vendorName ?? 'Invoice / Receipt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade800)),
        const SizedBox(height: 2),
        Text('${_products.length} product(s) detected  •  Date: ${_extractedDate ?? 'N/A'}',
            style: TextStyle(color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600, fontSize: 13)),
      ])),
      TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Row')),
    ])),
  );

  // ── Desktop table ──────────────────────────────────────────────────────
  Widget _productTable(bool isDark) {
    final evenRow = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
    final oddRow = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(children: [
          const SizedBox(width: 36),
          const Expanded(flex: 3, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 8),
          const Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 8),
          if (widget.mode == 'purchase')
            const SizedBox(width: 100, child: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))
          else
            const SizedBox(width: 100, child: Text('Selling Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(widget.mode == 'purchase' ? 'Stock In' : 'Units Sold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 36),
        ])),
        Divider(height: 1, color: isDark ? const Color(0xFF475569) : null),
        ...List.generate(_products.length, (i) {
          final p = _products[i];
          return Container(
            color: i.isEven ? evenRow : oddRow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(children: [
              SizedBox(width: 36, child: Checkbox(value: p.selected,
                  onChanged: (v) => setState(() => p.selected = v ?? true), activeColor: Colors.indigo)),
              Expanded(flex: 3, child: _field(p.nameCtrl, 'Product name', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: DropdownButtonFormField<String>(
                initialValue: p.category,
                items: _categories.map((c) => DropdownMenuItem(value: c,
                    child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => p.category = v ?? 'General'),
                decoration: InputDecoration(isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade400)),
                    filled: isDark, fillColor: isDark ? const Color(0xFF334155) : null),
              )),
              const SizedBox(width: 8),
              if (widget.mode == 'purchase')
                SizedBox(width: 100, child: _field(p.costPriceCtrl, '0.00', num: true, pre: '₹ ', isDark: isDark))
              else
                SizedBox(width: 100, child: _field(p.sellingPriceCtrl, '0.00', num: true, pre: '₹ ', isDark: isDark)),
              const SizedBox(width: 8),
              SizedBox(width: 90, child: _field(p.quantityCtrl, '1', num: true, isDark: isDark)),
              SizedBox(width: 36, child: IconButton(icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade400, size: 18), onPressed: () => _removeRow(i), splashRadius: 16)),
            ]),
          );
        }),
      ],
    )),
  );
  }

  // ── Mobile cards ───────────────────────────────────────────────────────
  Widget _productCards(bool isDark) => Column(
    children: List.generate(_products.length, (i) {
      final p = _products[i];
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Checkbox(value: p.selected,
                  onChanged: (v) => setState(() => p.selected = v ?? true), activeColor: Colors.indigo),
              Expanded(child: Text(p.nameCtrl.text.isNotEmpty ? p.nameCtrl.text : 'Product ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis)),
              IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                  onPressed: () => _removeRow(i)),
            ]),
            const SizedBox(height: 6),
            _field(p.nameCtrl, 'Product name', lbl: 'Product Name', isDark: isDark),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: p.category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => p.category = v ?? 'General'),
              decoration: InputDecoration(labelText: 'Category', isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade400)),
                  filled: isDark, fillColor: isDark ? const Color(0xFF334155) : null),
            ),
            const SizedBox(height: 8),
            if (widget.mode == 'purchase')
              Row(children: [
                Expanded(child: _field(p.costPriceCtrl, '0.00', lbl: 'Cost Price (CP)', num: true, pre: '₹ ', isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _field(p.quantityCtrl, '1', lbl: 'Stock Qty', num: true, isDark: isDark)),
              ])
            else if (widget.mode == 'sale')
              Row(children: [
                Expanded(child: _field(p.sellingPriceCtrl, '0.00', lbl: 'Selling Price (SP)', num: true, pre: '₹ ', isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _field(p.quantityCtrl, '1', lbl: 'Units Sold', num: true, isDark: isDark)),
              ]),
          ],
        )),
      );
    }),
  );

  // ── Text field helper ──────────────────────────────────────────────────
  Widget _field(TextEditingController c, String hint,
      {bool num = false, String? pre, String? lbl, bool isDark = false}) => TextField(
    controller: c,
    keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      labelText: lbl,
      prefixText: pre,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade400),
      ),
      filled: isDark,
      fillColor: isDark ? const Color(0xFF334155) : null,
      hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
      prefixStyle: TextStyle(color: isDark ? Colors.white70 : null),
    ),
  );

  // ── No products placeholder ────────────────────────────────────────────
  Widget _noProducts(bool isDark) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      Icon(Icons.search_off, size: 48, color: isDark ? Colors.white38 : Colors.grey.shade400),
      const SizedBox(height: 12),
      const Text('No products detected automatically',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('The text was extracted but no product lines were parsed.\nYou can add products manually.',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add),
          label: const Text('Add Product Manually'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white)),
    ])),
  );

  // ── Raw text expander ──────────────────────────────────────────────────
  Widget _rawTextExpander(bool isDark) => ExpansionTile(
    leading: Icon(Icons.text_snippet_outlined, color: isDark ? Colors.white38 : Colors.grey),
    title: Text('Raw Extracted Text', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey)),
    children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.grey.shade200),
        ),
        child: SelectableText(_rawText!, style: TextStyle(
          fontSize: 13, height: 1.5, fontFamily: 'monospace',
          color: isDark ? Colors.white70 : Colors.black87,
        )),
      ),
    ],
  );
}
