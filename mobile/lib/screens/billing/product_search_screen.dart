import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _searchController = TextEditingController();

  void _showItemAddDialog(ProductModel product) {
    final billing = Provider.of<BillingProvider>(context, listen: false);
    final qtyController = TextEditingController(text: "1");
    final priceController = TextEditingController(text: product.sellingPrice.toString());
    final discountController = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(product.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("SKU: ${product.sku} • Stock: ${product.currentStock} ${product.unit}",
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity (${product.unit})",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Unit Price (₹)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Discount (%)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 1.0;
                final price = double.tryParse(priceController.text) ?? product.sellingPrice;
                final disc = double.tryParse(discountController.text) ?? 0.0;

                billing.addToCart(product, quantity: qty);
                final idx = billing.cart.indexWhere((i) => i.product.id == product.id);
                if (idx >= 0) {
                  billing.updateItemPrice(idx, price);
                  billing.updateItemDiscount(idx, disc);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $qty ${product.unit} to cart'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Add to Invoice'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Select Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by SKU, product name, HSN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {},
                ),
              ),
              onChanged: (val) => inventory.fetchProducts(search: val),
            ),
          ),
          Expanded(
            child: inventory.products.isEmpty
                ? const Center(child: Text('Type to search products in catalog...'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventory.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final p = inventory.products[idx];
                      return Card(
                        child: ListTile(
                          title: Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text("SKU: ${p.sku} • Stock: ${p.currentStock} ${p.unit}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.formatCurrency(p.sellingPrice),
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.actionBlue),
                              ),
                              const Text('Tap to configure', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                          onTap: () => _showItemAddDialog(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
