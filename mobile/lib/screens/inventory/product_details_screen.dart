import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get("${ApiConstants.products}/${widget.productId}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _product = ProductModel.fromJson(res.data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.actionBlue)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final p = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/add-product', arguments: p.id);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.actionBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.categoryName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.actionBlue),
                        ),
                      ),
                      StatusBadge(status: p.isLowStock ? 'LOW_STOCK' : 'IN_STOCK'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(p.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text("SKU: ${p.sku} • Barcode: ${p.barcode} • HSN: ${p.hsnSac}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _priceBlock('Selling Price', AppFormatters.formatCurrency(p.sellingPrice), AppColors.actionBlue),
                      _priceBlock('Purchase Cost', AppFormatters.formatCurrency(p.purchasePrice), isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      _priceBlock('MRP', AppFormatters.formatCurrency(p.mrp), AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stock Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock & Availability', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Available Stock:'),
                      Text(
                        "${p.currentStock} ${p.unit}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.isLowStock ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Threshold:'),
                      Text("${p.minStock} ${p.unit}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST Tax Bracket:'),
                      Text("${p.gstRate.toInt()}% GST", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          AppButton(
            text: 'Adjust Stock / Restock',
            onPressed: () => Navigator.pushNamed(context, '/stock'),
            icon: Icons.tune,
          ),
        ],
      ),
    );
  }

  Widget _priceBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
