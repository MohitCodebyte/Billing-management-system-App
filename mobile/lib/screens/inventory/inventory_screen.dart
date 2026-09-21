import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/inventory_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _onlyLowStock = false;
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchProducts();
      Provider.of<InventoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalValuation = inventory.products.fold(0.0, (acc, p) => acc + (p.currentStock * p.purchasePrice));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Stock Movement Audit History',
            onPressed: () => Navigator.pushNamed(context, '/stock-history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inventory.fetchProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Valuation Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkElevated : const Color(0xFFEFF6FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL STOCK VALUATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.actionBlue)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.formatCurrency(totalValuation), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Stock In/Out'),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products by name, SKU, barcode...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                inventory.fetchProducts(search: val, categoryId: _selectedCategory, lowStock: _onlyLowStock);
              },
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Low Stock Alerts'),
                  selected: _onlyLowStock,
                  selectedColor: AppColors.dangerBg,
                  labelStyle: TextStyle(
                    color: _onlyLowStock ? AppColors.danger : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setState(() => _onlyLowStock = val);
                    inventory.fetchProducts(
                      search: _searchController.text,
                      categoryId: _selectedCategory,
                      lowStock: _onlyLowStock,
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : inventory.products.isEmpty
                    ? Center(
                        child: Text('No products found in inventory.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: () => inventory.fetchProducts(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: inventory.products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final p = inventory.products[idx];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (p.isLowStock ? AppColors.dangerBg : (isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9))),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.inventory,
                                    color: p.isLowStock ? AppColors.danger : AppColors.actionBlue,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusBadge(status: p.isLowStock ? 'LOW_STOCK' : 'IN_STOCK'),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text("SKU: ${p.sku} • ${p.categoryName} • HSN: ${p.hsnSac}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Price: ${AppFormatters.formatCurrency(p.sellingPrice)} / ${p.unit}",
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                                        ),
                                        Text(
                                          "Available: ${p.currentStock.toInt()} ${p.unit}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: p.isLowStock ? AppColors.danger : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/product-details', arguments: p.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
      ),
    );
  }
}
