import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../core/utils/pdf_invoice_service.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  InvoiceModel? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get("${ApiConstants.invoices}/${widget.invoiceId}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _invoice = InvoiceModel.fromJson(res.data);
      } else {
        _error = res.error ?? "Failed to load invoice";
      }
    });
  }

  void _showRecordPaymentDialog() {
    if (_invoice == null) return;
    final amountController = TextEditingController(text: _invoice!.balanceAmount.toStringAsFixed(0));
    String method = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Record Due Payment', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Balance Outstanding: ${AppFormatters.formatCurrency(_invoice!.balanceAmount)}",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer / NEFT')),
                      DropdownMenuItem(value: 'CARD', child: Text('Card')),
                    ],
                    onChanged: (val) => setDialogState(() => method = val ?? 'CASH'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    if (amt <= 0) return;

                    final res = await ApiClient().post(
                      "${ApiConstants.invoices}/${widget.invoiceId}/payments",
                      body: {'amount': amt, 'payment_method': method},
                    );
                    Navigator.pop(ctx);
                    if (res.success) {
                      _fetchInvoice();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: AppColors.success),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.error ?? 'Failed to record payment'), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.actionBlue)),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: Center(child: Text(_error ?? 'Invoice not found')),
      );
    }

    final inv = _invoice!;

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download / Print Invoice PDF',
            onPressed: () async {
              try {
                await PdfInvoiceService.printOrShareInvoice(inv);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Invoice',
            onPressed: () async {
              try {
                await PdfInvoiceService.printOrShareInvoice(inv);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
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
                      Text(
                        'TAX INVOICE',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.actionBlue),
                      ),
                      StatusBadge(status: inv.status),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Billed To:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(inv.customerName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                          Text(inv.customerPhone, style: const TextStyle(fontSize: 12)),
                          if (inv.customerGstin.isNotEmpty)
                            Text("GSTIN: ${inv.customerGstin}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Invoice Date:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(AppFormatters.formatDate(inv.invoiceDate), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Due Date:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(AppFormatters.formatDate(inv.dueDate), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items Table
          Text('Items Breakdown', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ...inv.items.map((it) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text("HSN: ${it.hsnSac} • ${it.quantity} ${it.unit} @ ₹${it.unitPrice.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text("Taxable: ₹${it.taxableAmount.toStringAsFixed(2)} • GST ${it.gstRate.toInt()}%",
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(it.totalAmount),
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Tax Breakdown Card
          GstSummaryCard(
            subtotal: inv.subtotal,
            discount: inv.discountAmount,
            taxable: inv.taxableValue,
            gst: inv.totalGst,
            roundOff: inv.roundOff,
            grandTotal: inv.grandTotal,
          ),
          const SizedBox(height: 16),

          // Payment Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid:', style: TextStyle(fontSize: 14)),
                      Text(AppFormatters.formatCurrency(inv.paidAmount), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Due:', style: TextStyle(fontSize: 14)),
                      Text(AppFormatters.formatCurrency(inv.balanceAmount), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: inv.balanceAmount > 0 ? AppColors.danger : AppColors.success)),
                    ],
                  ),
                  if (inv.balanceAmount > 0) ...[
                    const Divider(height: 20),
                    AppButton(
                      text: 'Record Payment (₹${inv.balanceAmount.toStringAsFixed(0)})',
                      onPressed: _showRecordPaymentDialog,
                      height: 44,
                      icon: Icons.payment,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Row
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Print Bill',
                  isSecondary: true,
                  height: 44,
                  icon: Icons.print_outlined,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending to thermal printer...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Sales Return',
                  isDestructive: true,
                  height: 44,
                  icon: Icons.assignment_return_outlined,
                  onPressed: () => Navigator.pushNamed(context, '/sales-returns'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
