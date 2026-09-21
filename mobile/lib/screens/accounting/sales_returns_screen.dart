import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class SalesReturnsScreen extends StatefulWidget {
  const SalesReturnsScreen({super.key});

  @override
  State<SalesReturnsScreen> createState() => _SalesReturnsScreenState();
}

class _SalesReturnsScreenState extends State<SalesReturnsScreen> {
  List<dynamic> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReturns();
  }

  Future<void> _fetchReturns() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get(ApiConstants.salesReturns);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _returns = res.data;
      }
    });
  }

  void _showNewSalesReturnDialog() async {
    // Fetch recent invoices to select from
    final invRes = await ApiClient().get(ApiConstants.invoices);
    if (!invRes.success || (invRes.data as List).isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invoices available for return.')),
      );
      return;
    }

    final invoices = invRes.data as List;
    var selectedInv = invoices.first;
    final reasonController = TextEditingController(text: "Defective / Specification mismatch");
    String refundType = "CREDIT_NOTE";

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDState) {
            final items = (selectedInv['items'] as List?) ?? [];
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Process Sales Return', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedInv['id'],
                      decoration: const InputDecoration(labelText: 'Select Invoice', border: OutlineInputBorder()),
                      items: invoices.map<DropdownMenuItem<int>>((i) {
                        return DropdownMenuItem<int>(
                          value: i['id'],
                          child: Text("${i['invoice_number']} - ${i['customer_name']}"),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setDState(() {
                          selectedInv = invoices.firstWhere((i) => i['id'] == id);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for Return', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: refundType,
                      decoration: const InputDecoration(labelText: 'Refund Mode', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'CREDIT_NOTE', child: Text('Issue Credit Note (Recommended)')),
                        DropdownMenuItem(value: 'CASH', child: Text('Instant Cash Refund')),
                      ],
                      onChanged: (v) => setDState(() => refundType = v ?? 'CREDIT_NOTE'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (items.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice has no returnable items')));
                      return;
                    }
                    final firstItem = items.first;
                    final res = await ApiClient().post(ApiConstants.salesReturns, body: {
                      'invoice_id': selectedInv['id'],
                      'refund_type': refundType,
                      'reason': reasonController.text.trim(),
                      'items': [
                        {
                          'product_id': firstItem['product_id'],
                          'product_name': firstItem['product_name'],
                          'quantity': 1.0,
                          'unit_price': firstItem['unit_price'],
                          'restock_inventory': true,
                        }
                      ]
                    });
                    Navigator.pop(ctx);
                    if (res.success) {
                      _fetchReturns();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sales return processed & stock replenished!'), backgroundColor: AppColors.success),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.error ?? 'Failed to process return'), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  child: const Text('Process Return'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Returns & Credit Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchReturns),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _returns.isEmpty
              ? const Center(child: Text('No sales returns recorded.'))
              : RefreshIndicator(
                  onRefresh: _fetchReturns,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _returns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final r = _returns[idx];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.assignment_return, color: AppColors.warning, size: 20),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r['return_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              Text(AppFormatters.formatCurrency(r['total_amount']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.danger)),
                            ],
                          ),
                          subtitle: Text("Against: ${r['invoice_number']} • ${r['customer_name']}\nReason: ${r['reason']}"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                            child: Text(r['refund_type'] ?? 'CREDIT_NOTE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.keyboard_return),
        label: const Text('New Sales Return'),
        onPressed: _showNewSalesReturnDialog,
      ),
    );
  }
}
