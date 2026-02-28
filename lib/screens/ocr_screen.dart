import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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
  const OcrScreen({super.key});
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
  String? _error;
  String? _successMsg;

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
        _error = null;
        _successMsg = null;
        for (final p in _products) { p.dispose(); }
        _products = [];
      });
      await _processImage(bytes);
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  // ── OCR processing ─────────────────────────────────────────────────────
  Future<void> _processImage(Uint8List bytes) async {
    setState(() { _isProcessing = true; _error = null; });
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
          costPrice: (item['costPrice'] ?? 0).toDouble(),
          sellingPrice: (item['sellingPrice'] ?? 0).toDouble(),
          quantity: (item['quantity'] ?? 1).toInt(),
        )).toList();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() { _error = 'OCR processing failed: $e'; _isProcessing = false; });
    }
  }

  // ── Save to inventory ──────────────────────────────────────────────────
  Future<void> _saveToInventory() async {
    final selected = _products.where((p) => p.selected).toList();
    if (selected.isEmpty) {
      _snack('No products selected to save'); return;
    }
    for (final p in selected) {
      if (p.nameCtrl.text.trim().isEmpty) { _snack('Product name cannot be empty'); return; }
      final cp = double.tryParse(p.costPriceCtrl.text);
      if (cp == null || cp <= 0) { _snack('Invalid cost price for "${p.nameCtrl.text}"'); return; }
      final sp = double.tryParse(p.sellingPriceCtrl.text);
      if (sp == null || sp <= 0) { _snack('Enter selling price for "${p.nameCtrl.text}"'); return; }
    }

    setState(() { _isSaving = true; _error = null; _successMsg = null; });
    int saved = 0;
    final List<String> errs = [];

    for (final p in selected) {
      try {
        final res = await ApiService().post('/products/add', body: {
          'product_name': p.nameCtrl.text.trim(),
          'category': p.category,
          'cost_price': double.parse(p.costPriceCtrl.text),
          'selling_price': double.parse(p.sellingPriceCtrl.text),
        });
        final pid = res['product']?['id'];
        if (pid == null) { errs.add('${p.nameCtrl.text}: no product ID'); continue; }
        await ApiService().post('/inventory/add', body: {
          'product_id': pid, 'stock': int.tryParse(p.quantityCtrl.text) ?? 1,
        });
        saved++;
      } catch (e) { errs.add('${p.nameCtrl.text}: $e'); }
    }
    setState(() {
      _isSaving = false;
      _successMsg = errs.isEmpty
          ? 'Saved $saved product(s) to inventory!'
          : 'Saved $saved. ${errs.length} failed.';
      if (errs.isNotEmpty) _error = errs.join('\n');
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _addRow() => setState(() =>
      _products.add(ParsedProduct(name: '', costPrice: 0, sellingPrice: 0, quantity: 1)));

  void _removeRow(int i) => setState(() { _products[i].dispose(); _products.removeAt(i); });

  void _clearAll() => setState(() {
    _imageBytes = null; _rawText = null; _vendorName = null;
    _extractedDate = null; _error = null; _successMsg = null;
    for (final p in _products) { p.dispose(); }
    _products = [];
  });

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          if (_imageBytes != null)
            IconButton(icon: const Icon(Icons.clear), tooltip: 'Clear', onPressed: _clearAll),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 12 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_imageBytes == null)
            _uploadArea(mobile)
          else ...[
            _imagePreview(mobile),
            const SizedBox(height: 16),
            if (_isProcessing) _processingCard(),
            if (_error != null) _errorBanner(),
            if (_successMsg != null) _successBanner(),
            if (!_isProcessing && _products.isNotEmpty) ...[
              _scanSummary(),
              const SizedBox(height: 12),
              if (mobile) _productCards() else _productTable(),
              const SizedBox(height: 16),
              _actionButtons(),
            ],
            if (!_isProcessing && _products.isEmpty && _rawText != null) _noProducts(),
            if (_rawText != null && _rawText!.isNotEmpty) ...[
              const SizedBox(height: 16), _rawTextExpander(),
            ],
          ],
        ]),
      ),
    );
  }

  // ── Upload area ────────────────────────────────────────────────────────
  Widget _uploadArea(bool mobile) => Center(
    child: Container(
      width: mobile ? double.infinity : 500,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 2),
      ),
      child: Column(children: [
        Icon(Icons.document_scanner_outlined, size: 64, color: Colors.indigo.shade300),
        const SizedBox(height: 16),
        const Text('Scan Invoice / Receipt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Upload a supplier invoice, receipt, or stock list.\nProducts are auto-detected with prices & quantities.',
            style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
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
  Widget _imagePreview(bool mobile) => ExpansionTile(
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
  Widget _processingCard() => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
      child: const Column(children: [
        CircularProgressIndicator(), SizedBox(height: 16),
        Text('Scanning & extracting product data…', style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 4),
        Text('This may take a few seconds', style: TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    ),
  );

  Widget _errorBanner() => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200)),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
      if (_imageBytes != null)
        TextButton(onPressed: () => _processImage(_imageBytes!), child: const Text('Retry')),
    ]),
  );

  Widget _successBanner() => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200)),
    child: Row(children: [
      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(_successMsg!, style: TextStyle(color: Colors.green.shade700))),
    ]),
  );

  // ── Scan summary ───────────────────────────────────────────────────────
  Widget _scanSummary() => Card(
    color: Colors.indigo.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Icon(Icons.receipt_long, color: Colors.indigo.shade700),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_vendorName ?? 'Invoice / Receipt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo.shade800)),
        const SizedBox(height: 2),
        Text('${_products.length} product(s) detected  •  Date: ${_extractedDate ?? 'N/A'}',
            style: TextStyle(color: Colors.indigo.shade600, fontSize: 13)),
      ])),
      TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Row')),
    ])),
  );

  // ── Desktop table ──────────────────────────────────────────────────────
  Widget _productTable() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(children: [
          SizedBox(width: 36),
          Expanded(flex: 3, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 8),
          Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 8),
          SizedBox(width: 90, child: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 8),
          SizedBox(width: 100, child: Text('Selling Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 8),
          SizedBox(width: 70, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 36),
        ])),
        const Divider(height: 1),
        ...List.generate(_products.length, (i) {
          final p = _products[i];
          return Container(
            color: i.isEven ? Colors.grey.shade50 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              SizedBox(width: 36, child: Checkbox(value: p.selected,
                  onChanged: (v) => setState(() => p.selected = v ?? true), activeColor: Colors.indigo)),
              Expanded(flex: 3, child: _field(p.nameCtrl, 'Product name')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: DropdownButtonFormField<String>(
                initialValue: p.category,
                items: _categories.map((c) => DropdownMenuItem(value: c,
                    child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => p.category = v ?? 'General'),
                decoration: InputDecoration(isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 90, child: _field(p.costPriceCtrl, '0.00', num: true, pre: '\$ ')),
              const SizedBox(width: 8),
              SizedBox(width: 100, child: _field(p.sellingPriceCtrl, '0.00', num: true, pre: '\$ ')),
              const SizedBox(width: 8),
              SizedBox(width: 70, child: _field(p.quantityCtrl, '1', num: true)),
              SizedBox(width: 36, child: IconButton(icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade400, size: 18), onPressed: () => _removeRow(i), splashRadius: 16)),
            ]),
          );
        }),
      ],
    )),
  );

  // ── Mobile cards ───────────────────────────────────────────────────────
  Widget _productCards() => Column(
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                  onPressed: () => _removeRow(i)),
            ]),
            const SizedBox(height: 6),
            _field(p.nameCtrl, 'Product name', lbl: 'Product Name'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: p.category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => p.category = v ?? 'General'),
              decoration: InputDecoration(labelText: 'Category', isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(p.costPriceCtrl, '0.00', lbl: 'Cost Price (CP)', num: true, pre: '\$ ')),
              const SizedBox(width: 8),
              Expanded(child: _field(p.sellingPriceCtrl, '0.00', lbl: 'Selling Price (SP)', num: true, pre: '\$ ')),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: 120, child: _field(p.quantityCtrl, '1', lbl: 'Stock Qty', num: true)),
          ],
        )),
      );
    }),
  );

  // ── Text field helper ──────────────────────────────────────────────────
  Widget _field(TextEditingController c, String hint,
      {bool num = false, String? pre, String? lbl}) => TextField(
    controller: c,
    keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(hintText: hint, labelText: lbl, prefixText: pre, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
  );

  // ── Action buttons ─────────────────────────────────────────────────────
  Widget _actionButtons() {
    final n = _products.where((p) => p.selected).length;
    return Row(children: [
      Expanded(child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveToInventory,
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving…' : 'Save $n Product(s) to Inventory'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      )),
      const SizedBox(width: 12),
      OutlinedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add Row'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    ]);
  }

  // ── No products placeholder ────────────────────────────────────────────
  Widget _noProducts() => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      const Text('No products detected automatically',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('The text was extracted but no product lines were parsed.\nYou can add products manually.',
          style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add),
          label: const Text('Add Product Manually'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white)),
    ])),
  );

  // ── Raw text expander ──────────────────────────────────────────────────
  Widget _rawTextExpander() => ExpansionTile(
    leading: const Icon(Icons.text_snippet_outlined, color: Colors.grey),
    title: const Text('Raw Extracted Text', style: TextStyle(fontSize: 14, color: Colors.grey)),
    children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200)),
        child: SelectableText(_rawText!, style: const TextStyle(fontSize: 13, height: 1.5, fontFamily: 'monospace')),
      ),
    ],
  );
}
