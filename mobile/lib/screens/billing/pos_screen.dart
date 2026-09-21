import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchProducts();
      Provider.of<InventoryProvider>(context, listen: false).fetchCategories();
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  void _showCustomerPicker() {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final billing = Provider.of<BillingProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Customer', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('New'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/customers');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by customer name or phone...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) => customerProvider.fetchCustomers(search: val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<CustomerProvider>(
                      builder: (_, cp, __) {
                        if (cp.isLoading) return const Center(child: CircularProgressIndicator());
                        if (cp.customers.isEmpty) {
                          return const Center(child: Text('No customers found.'));
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: cp.customers.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (_, idx) {
                            final c = cp.customers[idx];
                            final isSelected = billing.selectedCustomer?.id == c.id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.actionBlue.withOpacity(0.1),
                                child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppColors.actionBlue, fontWeight: FontWeight.w700)),
                              ),
                              title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              subtitle: Text("${c.phone} • GSTIN: ${c.gstin.isNotEmpty ? c.gstin : 'None'}"),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(c.currentBalance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: c.currentBalance > 0 ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                  const Text('Balance', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                              selected: isSelected,
                              onTap: () {
                                billing.selectCustomer(c);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = Provider.of<BillingProvider>(context);
    final inventory = Provider.of<InventoryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing / POS Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Barcode Scanner',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barcode scanner active. Point at product SKU.')),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (billing.cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Text(
                        '${billing.cart.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart-preview'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Selection Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkElevated : const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.actionBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        billing.selectedCustomer?.name ?? 'No Customer Selected (Walk-in)',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (billing.selectedCustomer != null)
                        Text(
                          "Credit Limit: ${AppFormatters.formatCurrency(billing.selectedCustomer!.creditLimit)} • Due: ${AppFormatters.formatCurrency(billing.selectedCustomer!.currentBalance)}",
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _showCustomerPicker,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: AppColors.actionBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    billing.selectedCustomer == null ? 'Select Customer' : 'Change',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items by name, SKU or barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          inventory.fetchProducts();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                inventory.fetchProducts(search: val, categoryId: _selectedCategoryId);
              },
            ),
          ),

          // Category filter chips
          if (inventory.categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All Items'),
                      selected: _selectedCategoryId == null,
                      selectedColor: AppColors.actionBlue,
                      labelStyle: TextStyle(color: _selectedCategoryId == null ? Colors.white : null, fontSize: 12),
                      onSelected: (val) {
                        setState(() => _selectedCategoryId = null);
                        inventory.fetchProducts(search: _searchController.text);
                      },
                    ),
                  ),
                  ...inventory.categories.map((cat) {
                    final isSel = _selectedCategoryId == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat['name'] ?? ''),
                        selected: isSel,
                        selectedColor: AppColors.actionBlue,
                        labelStyle: TextStyle(color: isSel ? Colors.white : null, fontSize: 12),
                        onSelected: (val) {
                          setState(() => _selectedCategoryId = val ? cat['id'] : null);
                          inventory.fetchProducts(
                            search: _searchController.text,
                            categoryId: _selectedCategoryId,
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Products List
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : inventory.products.isEmpty
                    ? Center(
                        child: Text('No matching products found in stock.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: inventory.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final prod = inventory.products[idx];
                          final inCartQty = billing.cart
                              .firstWhere((i) => i.product.id == prod.id, orElse: () => CartItem(product: prod, quantity: 0, unitPrice: 0))
                              .quantity;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.settings_suggest, color: AppColors.actionBlue, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "SKU: ${prod.sku} • HSN: ${prod.hsnSac} • GST ${prod.gstRate.toInt()}%",
                                          style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              AppFormatters.formatCurrency(prod.sellingPrice),
                                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.actionBlue),
                                            ),
                                            Text(
                                              " / ${prod.unit}",
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Stock: ${prod.currentStock.toInt()}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: prod.isLowStock ? AppColors.danger : AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add button or Counter
                                  if (inCartQty > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                                          onPressed: () {
                                            final cartIdx = billing.cart.indexWhere((i) => i.product.id == prod.id);
                                            billing.updateQuantity(cartIdx, inCartQty - 1);
                                          },
                                        ),
                                        Text(
                                          '${inCartQty.toInt()}',
                                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: AppColors.actionBlue),
                                          onPressed: () => billing.addToCart(prod, quantity: 1),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () => billing.addToCart(prod, quantity: 1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.actionBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Add +', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomSheet: billing.cart.isNotEmpty
          ? StickyBottomBar(
              title: '${billing.cart.length} Products in Cart',
              amount: AppFormatters.formatCurrency(billing.grandTotal),
              buttonText: 'Review Invoice',
              onButtonPressed: () => Navigator.pushNamed(context, '/cart-preview'),
            )
          : null,
    );
  }
}
