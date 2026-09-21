import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common_widgets.dart';

class AddEditProductScreen extends StatefulWidget {
  final int? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hsnController = TextEditingController(text: "8481");
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _minStockController = TextEditingController(text: "10");
  final _initialStockController = TextEditingController(text: "20");

  String _unit = "PCS";
  double _gstRate = 18.0;
  int? _categoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final inv = Provider.of<InventoryProvider>(context, listen: false);
    if (inv.categories.isNotEmpty) {
      _categoryId = inv.categories.first['id'];
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final inv = Provider.of<InventoryProvider>(context, listen: false);

    final payload = {
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'hsn_sac': _hsnController.text.trim(),
      'unit': _unit,
      'category_id': _categoryId,
      'purchase_price': double.tryParse(_purchasePriceController.text) ?? 0.0,
      'selling_price': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'mrp': double.tryParse(_mrpController.text) ?? (double.tryParse(_sellingPriceController.text) ?? 0.0),
      'gst_rate': _gstRate,
      'min_stock': double.tryParse(_minStockController.text) ?? 10.0,
      'initial_stock': double.tryParse(_initialStockController.text) ?? 0.0,
    };

    final success = await inv.createProduct(payload);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to inventory!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save product. SKU may already exist.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add New Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General Product Information', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU Code *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'SKU required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hsnController,
                      decoration: const InputDecoration(labelText: 'HSN/SAC Code', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Measurement Unit', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'PCS', child: Text('Pieces (PCS)')),
                        DropdownMenuItem(value: 'BOX', child: Text('Box (BOX)')),
                        DropdownMenuItem(value: 'KG', child: Text('Kilograms (KG)')),
                        DropdownMenuItem(value: 'MTR', child: Text('Meters (MTR)')),
                        DropdownMenuItem(value: 'LTR', child: Text('Liters (LTR)')),
                        DropdownMenuItem(value: 'SET', child: Text('Set (SET)')),
                      ],
                      onChanged: (val) => setState(() => _unit = val ?? 'PCS'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Pricing & Tax (₹)', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Purchase Rate (₹)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Selling Price (₹) *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Price required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mrpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maximum Retail Price (MRP)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: _gstRate,
                      decoration: const InputDecoration(labelText: 'GST Tax %', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                        DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                        DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                        DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                        DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                      ],
                      onChanged: (val) => setState(() => _gstRate = val ?? 18.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Stock Controls', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Stock Alert Threshold', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _initialStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Initial Opening Stock', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              AppButton(
                text: 'Save & Publish Product',
                onPressed: _saveProduct,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
