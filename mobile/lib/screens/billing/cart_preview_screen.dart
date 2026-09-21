import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/common_widgets.dart';

class CartPreviewScreen extends StatelessWidget {
  const CartPreviewScreen({super.key});

  void _showChargesDialog(BuildContext context) {
    final billing = Provider.of<BillingProvider>(context, listen: false);
    final chargesController = TextEditingController(text: billing.additionalCharges.toString());
    final discountController = TextEditingController(text: billing.globalDiscount.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Adjust Charges & Discount', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: chargesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Additional Freight / Loading Charges (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Special Overall Discount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
              onPressed: () {
                final c = double.tryParse(chargesController.text) ?? 0.0;
                final d = double.tryParse(discountController.text) ?? 0.0;
                billing.setAdditionalCharges(c);
                billing.setGlobalDiscount(d);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = Provider.of<BillingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (billing.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Preview')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.remove_shopping_cart_outlined, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Your cart is empty', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                child: const Text('Add Items from POS'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Invoice & Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add More Items',
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
            tooltip: 'Clear Cart',
            onPressed: () {
              billing.clearCart();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Customer Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.actionBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.actionBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        billing.selectedCustomer?.name ?? 'Walk-in Customer',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        billing.selectedCustomer != null
                            ? "Phone: ${billing.selectedCustomer!.phone} • GSTIN: ${billing.selectedCustomer!.gstin}"
                            : "Standard Retail Cash Billing",
                        style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Line Items (${billing.cart.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Charges & Discounts'),
                onPressed: () => _showChargesDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...List.generate(billing.cart.length, (idx) {
            final item = billing.cart[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text("SKU: ${item.product.sku} • Rate: ₹${item.unitPrice.toStringAsFixed(2)} • GST ${item.product.gstRate.toInt()}%",
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(item.total),
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                              onPressed: () => billing.updateQuantity(idx, item.quantity - 1),
                            ),
                            Text(
                              "${item.quantity.toStringAsFixed(0)} ${item.product.unit}",
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.actionBlue),
                              onPressed: () => billing.updateQuantity(idx, item.quantity + 1),
                            ),
                          ],
                        ),
                        Text(
                          "Tax: ₹${item.taxAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // GST Tax Summary
          GstSummaryCard(
            subtotal: billing.subtotal,
            discount: billing.totalDiscount,
            taxable: billing.taxableSubtotal,
            gst: billing.totalGst,
            roundOff: billing.roundOff,
            grandTotal: billing.grandTotal,
          ),
        ],
      ),
      bottomSheet: StickyBottomBar(
        title: 'Grand Total (Incl. Tax)',
        amount: AppFormatters.formatCurrency(billing.grandTotal),
        buttonText: 'Proceed to Payment',
        onButtonPressed: () => Navigator.pushNamed(context, '/payment'),
      ),
    );
  }
}
