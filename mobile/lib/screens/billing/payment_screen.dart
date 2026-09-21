import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _cardController = TextEditingController();
  final _creditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final billing = Provider.of<BillingProvider>(context, listen: false);
    _cashController.text = billing.grandTotal.toStringAsFixed(0);
    _upiController.text = "0";
    _cardController.text = "0";
    _creditController.text = "0";
  }

  void _onSplitChanged() {
    final billing = Provider.of<BillingProvider>(context, listen: false);
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    final upi = double.tryParse(_upiController.text) ?? 0.0;
    final card = double.tryParse(_cardController.text) ?? 0.0;
    final credit = double.tryParse(_creditController.text) ?? 0.0;

    final splits = <Map<String, dynamic>>[];
    if (cash > 0) splits.add({'method': 'CASH', 'amount': cash});
    if (upi > 0) splits.add({'method': 'UPI', 'amount': upi});
    if (card > 0) splits.add({'method': 'CARD', 'amount': card});
    if (credit > 0) splits.add({'method': 'CREDIT', 'amount': credit});

    billing.setSplitPayments(splits);
  }

  void _handlePaymentSubmit() async {
    final billing = Provider.of<BillingProvider>(context, listen: false);

    if (billing.paymentMethod == 'SPLIT') {
      final totalSplit = (double.tryParse(_cashController.text) ?? 0.0) +
          (double.tryParse(_upiController.text) ?? 0.0) +
          (double.tryParse(_cardController.text) ?? 0.0) +
          (double.tryParse(_creditController.text) ?? 0.0);

      if ((totalSplit - billing.grandTotal).abs() > 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Split payment total (₹$totalSplit) must equal grand total (₹${billing.grandTotal})'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final success = await billing.submitInvoice();

    if (!mounted) return;
    if (success && billing.lastCreatedInvoice != null) {
      final inv = billing.lastCreatedInvoice!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Invoice Generated!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  inv.invoiceNumber,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _dialogRow('Total Amount', AppFormatters.formatCurrency(inv.grandTotal)),
                      const SizedBox(height: 4),
                      _dialogRow('Paid Amount', AppFormatters.formatCurrency(inv.paidAmount)),
                      const SizedBox(height: 4),
                      _dialogRow('Balance Due', AppFormatters.formatCurrency(inv.balanceAmount), isRed: inv.balanceAmount > 0),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                },
                child: const Text('Back to Dashboard'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Invoice'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, '/invoice-details', arguments: inv.id);
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billing.errorMessage ?? 'Payment failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _dialogRow(String label, String value, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isRed ? AppColors.danger : null)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = Provider.of<BillingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final methods = [
      {'id': 'CASH', 'name': 'Cash', 'icon': Icons.money},
      {'id': 'UPI', 'name': 'UPI / QR', 'icon': Icons.qr_code},
      {'id': 'CARD', 'name': 'Debit/Credit Card', 'icon': Icons.credit_card},
      {'id': 'CREDIT', 'name': 'Credit (Udhaar)', 'icon': Icons.account_balance_wallet},
      {'id': 'SPLIT', 'name': 'Split Payment', 'icon': Icons.call_split},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Total Amount Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'AMOUNT PAYABLE',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                Text(
                  AppFormatters.formatCurrency(billing.grandTotal),
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Customer: ${billing.selectedCustomer?.name ?? 'Walk-in'}",
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Payment Mode',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          // Payment Options
          ...methods.map((m) {
            final isSelected = billing.paymentMethod == m['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.actionBlue : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.actionBlue.withOpacity(0.12) : (isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m['icon'] as IconData, color: isSelected ? AppColors.actionBlue : null, size: 22),
                  ),
                  title: Text(
                    m['name'] as String,
                    style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.actionBlue)
                      : const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted),
                  onTap: () => billing.setPaymentMethod(m['id'] as String),
                ),
              ),
            );
          }),

          // Split payment breakdown fields
          if (billing.paymentMethod == 'SPLIT') ...[
            const SizedBox(height: 16),
            Text('Split Allocation (₹)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _splitField('Cash Amount (₹)', _cashController),
                    const SizedBox(height: 10),
                    _splitField('UPI Amount (₹)', _upiController),
                    const SizedBox(height: 10),
                    _splitField('Card Amount (₹)', _cardController),
                    const SizedBox(height: 10),
                    _splitField('Credit / Udhaar (₹)', _creditController),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomSheet: StickyBottomBar(
        title: 'Complete Transaction',
        amount: AppFormatters.formatCurrency(billing.paidAmount),
        buttonText: 'Confirm & Generate Bill',
        isLoading: billing.isSubmitting,
        onButtonPressed: _handlePaymentSubmit,
      ),
    );
  }

  Widget _splitField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _onSplitChanged(),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
