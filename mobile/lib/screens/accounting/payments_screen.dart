import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    // Fetch recent receipts from invoices / customer ledger
    final res = await ApiClient().get(ApiConstants.dashboard);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _payments = res.data['recent_invoices'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Receivables'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPayments),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _payments.isEmpty
              ? const Center(child: Text('No payment logs recorded yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final p = _payments[idx];
                    final paid = (p['paid_amount'] as num? ?? 0.0).toDouble();

                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: AppColors.success, size: 20),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['customer_name'] ?? 'Party Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            Text(AppFormatters.formatCurrency(paid), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.success)),
                          ],
                        ),
                        subtitle: Text("Invoice: ${p['invoice_number']} • ${AppFormatters.formatDate(p['invoice_date'])}"),
                        trailing: StatusBadge(status: p['status'] ?? 'PAID'),
                      ),
                    );
                  },
                ),
    );
  }
}
