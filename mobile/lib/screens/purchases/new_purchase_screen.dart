import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  SupplierModel? _selectedSupplier;
  final List<Map<String, dynamic>> _purchaseItems = [];
  final _vendorInvoiceController = TextEditingController();
  final _paidAmountController = TextEditingController(text: "0");
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplierProvider>(context, listen: false).fetchSuppliers();
      Provider.of<InventoryProvider>(context, listen: false).fetchProducts();
    });
  }

  void _addItemDialog() {
    final inv = Provider.of<InventoryProvider>(context, listen: false);
    ProductModel? chosenProd = inv.products.isNotEmpty ? inv.products.first : null;
    final qtyController = TextEditingController(text: "10");
    final rateController = TextEditingController(text: chosenProd?.purchasePrice.toString() ?? "100");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Raw Materials / Stock', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: chosenProd?.id,
                    decoration: const InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()),
                    items: inv.products.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setDState(() {
                        chosenProd = inv.products.firstWhere((p) => p.id == id);
                        rateController.text = chosenProd?.purchasePrice.toString() ?? "100";
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantity (${chosenProd?.unit ?? 'Units'})', border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Purchase Rate (₹)', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    if (chosenProd == null) return;
                    final q = double.tryParse(qtyController.text) ?? 1.0;
                    final r = double.tryParse(rateController.text) ?? chosenProd!.purchasePrice;

                    setState(() {
                      _purchaseItems.add({
                        'product_id': chosenProd!.id,
                        'product_name': chosenProd!.name,
                        'unit': chosenProd!.unit,
                        'quantity': q,
                        'unit_price': r,
                        'gst_rate': chosenProd!.gstRate,
                        'total': q * r * (1 + chosenProd!.gstRate / 100),
                      });
                      _paidAmountController.text = _calculateTotal().toStringAsFixed(0);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateTotal() {
    return _purchaseItems.fold(0.0, (acc, it) => acc + (it['total'] as double));
  }

  void _submitPurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item to purchase')));
      return;
    }

    setState(() => _isSubmitting = true);
    final paidAmt = double.tryParse(_paidAmountController.text) ?? 0.0;

    final payload = {
      'supplier_id': _selectedSupplier!.id,
      'supplier_invoice_number': _vendorInvoiceController.text.trim(),
      'items': _purchaseItems,
      'payment': {
        'amount': paidAmt,
        'payment_method': 'BANK_TRANSFER',
      }
    };

    final res = await ApiClient().post(ApiConstants.purchases, body: payload);
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase recorded! Stock updated automatically.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to record purchase'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supProvider = Provider.of<SupplierProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Record New Purchase Bill')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Supplier selector
          Text('Supplier / Vendor *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedSupplier?.id,
            decoration: const InputDecoration(labelText: 'Choose Supplier', border: OutlineInputBorder()),
            items: supProvider.suppliers.map((s) {
              return DropdownMenuItem<int>(
                value: s.id,
                child: Text("${s.name} (Payable: ${AppFormatters.formatCompactCurrency(s.currentPayable)})"),
              );
            }).toList(),
            onChanged: (id) {
              setState(() {
                _selectedSupplier = supProvider.suppliers.firstWhere((s) => s.id == id);
              });
            },
          ),
          const SizedBox(height: 16),

          Text('Vendor Invoice / Challan No.', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _vendorInvoiceController,
            decoration: const InputDecoration(hintText: 'e.g. JINDAL/2026/8941', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          // Items Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items Received (${_purchaseItems.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Item'),
                onPressed: _addItemDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_purchaseItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Tap "+ Add Item" to specify raw materials or merchandise.')),
            )
          else
            ...List.generate(_purchaseItems.length, (idx) {
              final it = _purchaseItems[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(it['product_name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text("${it['quantity']} ${it['unit']} @ ₹${it['unit_price']} + GST ${it['gst_rate']}%"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppFormatters.formatCurrency(it['total']), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            _purchaseItems.removeAt(idx);
                            _paidAmountController.text = _calculateTotal().toStringAsFixed(0);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Payment allocation
          Text('Supplier Payment Details', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _paidAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount Paid to Vendor (₹)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomSheet: StickyBottomBar(
        title: 'Grand Total (with GST)',
        amount: AppFormatters.formatCurrency(_calculateTotal()),
        buttonText: 'Save Purchase',
        isLoading: _isSubmitting,
        onButtonPressed: _submitPurchase,
      ),
    );
  }
}
