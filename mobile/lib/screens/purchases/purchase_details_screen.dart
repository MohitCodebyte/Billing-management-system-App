import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final int purchaseId;
  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  Map<String, dynamic>? _purchase;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPurchase();
  }

  Future<void> _fetchPurchase() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get("${ApiConstants.purchases}/${widget.purchaseId}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _purchase = res.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Order Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.actionBlue)),
      );
    }

    if (_purchase == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Order Details')),
        body: const Center(child: Text('Purchase not found')),
      );
    }

    final p = _purchase!;
    final items = (p['items'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(p['purchase_number'] ?? 'Purchase Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPurchase,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['purchase_number'] ?? '', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      StatusBadge(status: p['status'] ?? 'RECEIVED'),
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Supplier: ${p['supplier_name']}", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text("Supplier Invoice No: ${p['supplier_invoice_number'] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                  Text("Bill Date: ${AppFormatters.formatDate(p['purchase_date'])}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Received Stock Items (${items.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ...items.map((it) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(it['product_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text("Qty: ${it['quantity']} ${it['unit']} @ ₹${it['unit_price']} (GST ${it['gst_rate']}%)"),
                trailing: Text(
                  AppFormatters.formatCurrency(it['total_amount']),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Subtotal', AppFormatters.formatCurrency(p['subtotal'])),
                  const SizedBox(height: 6),
                  _row('Total GST (ITC Input Credit)', AppFormatters.formatCurrency(p['total_gst'])),
                  const Divider(height: 16),
                  _row('Grand Total', AppFormatters.formatCurrency(p['grand_total']), isBold: true),
                  const SizedBox(height: 6),
                  _row('Paid to Vendor', AppFormatters.formatCurrency(p['paid_amount'])),
                  const SizedBox(height: 6),
                  _row('Balance Payable', AppFormatters.formatCurrency(p['balance_amount']), isRed: (p['balance_amount'] as num? ?? 0) > 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          AppButton(
            text: 'Purchase Return to Vendor',
            isDestructive: true,
            icon: Icons.keyboard_return_outlined,
            onPressed: () => Navigator.pushNamed(context, '/purchase-returns'),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w700 : null)),
        Text(
          v,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isRed ? AppColors.danger : null,
          ),
        ),
      ],
    );
  }
}
