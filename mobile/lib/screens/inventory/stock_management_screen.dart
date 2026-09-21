import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  ProductModel? _selectedProduct;
  String _movementType = "IN"; // IN, OUT, ADJUSTMENT, DAMAGE
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  void _submitAdjustment() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product first')));
      return;
    }

    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

    setState(() => _isLoading = true);
    final inv = Provider.of<InventoryProvider>(context, listen: false);

    final success = await inv.adjustStock(
      productId: _selectedProduct!.id,
      quantity: qty,
      movementType: _movementType,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock record updated & auditable movement logged!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to adjust stock'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management & Audit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Item for Stock Update', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              value: _selectedProduct?.id,
              decoration: const InputDecoration(labelText: 'Choose Product', border: OutlineInputBorder()),
              items: inv.products.map((p) {
                return DropdownMenuItem<int>(
                  value: p.id,
                  child: Text("${p.name} (Cur: ${p.currentStock} ${p.unit})", maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (id) {
                setState(() {
                  _selectedProduct = inv.products.firstWhere((p) => p.id == id);
                });
              },
            ),
            const SizedBox(height: 20),

            Text('Action / Movement Type', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            Row(
              children: [
                _typeChip('Stock In (+)', 'IN', AppColors.success),
                const SizedBox(width: 8),
                _typeChip('Stock Out (-)', 'OUT', AppColors.warning),
                const SizedBox(width: 8),
                _typeChip('Damaged', 'DAMAGE', AppColors.danger),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _movementType == 'ADJUSTMENT' ? 'New Exact Stock Level' : 'Quantity to Update',
                suffixText: _selectedProduct?.unit ?? 'Units',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason / Audit Note',
                hintText: 'e.g. Warehouse restock, Physical count audit, Damaged during unloading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Save Stock Movement',
              onPressed: _submitAdjustment,
              isLoading: _isLoading,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String type, Color activeColor) {
    final isSel = _movementType == type;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: activeColor,
        labelStyle: TextStyle(
          color: isSel ? Colors.white : null,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) setState(() => _movementType = type);
        },
      ),
    );
  }
}
