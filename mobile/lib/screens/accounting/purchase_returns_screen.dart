import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class PurchaseReturnsScreen extends StatefulWidget {
  const PurchaseReturnsScreen({super.key});

  @override
  State<PurchaseReturnsScreen> createState() => _PurchaseReturnsScreenState();
}

class _PurchaseReturnsScreenState extends State<PurchaseReturnsScreen> {
  List<dynamic> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReturns();
  }

  Future<void> _fetchReturns() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get(ApiConstants.purchaseReturns);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _returns = res.data;
      }
    });
  }

  void _showNewPurchaseReturnDialog() async {
    final purRes = await ApiClient().get(ApiConstants.purchases);
    if (!purRes.success || (purRes.data as List).isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No purchase orders available.')));
      return;
    }

    final purchases = purRes.data as List;
    var selectedPur = purchases.first;
    final reasonController = TextEditingController(text: "Defective batch received");

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDState) {
            final items = (selectedPur['items'] as List?) ?? [];
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Return Goods to Supplier', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedPur['id'],
                      decoration: const InputDecoration(labelText: 'Select Purchase Bill', border: OutlineInputBorder()),
                      items: purchases.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text("${p['purchase_number']} - ${p['supplier_name']}"),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setDState(() {
                          selectedPur = purchases.firstWhere((p) => p['id'] == id);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for Vendor Return', border: OutlineInputBorder()),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase has no items')));
                      return;
                    }
                    final firstItem = items.first;
                    final res = await ApiClient().post(ApiConstants.purchaseReturns, body: {
                      'purchase_id': selectedPur['id'],
                      'reason': reasonController.text.trim(),
                      'refund_type': 'DEBIT_NOTE',
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
                        const SnackBar(content: Text('Purchase return logged & Debit Note generated!'), backgroundColor: AppColors.success),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.error ?? 'Failed to process return'), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  child: const Text('Confirm Return'),
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
        title: const Text('Purchase Returns (Vendor)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchReturns),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _returns.isEmpty
              ? const Center(child: Text('No purchase returns recorded.'))
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
                            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.keyboard_return, color: AppColors.danger, size: 20),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r['return_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              Text(AppFormatters.formatCurrency(r['total_amount']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.danger)),
                            ],
                          ),
                          subtitle: Text("Against: ${r['purchase_number']} • ${r['supplier_name']}\nReason: ${r['reason']}"),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_return),
        label: const Text('Return to Vendor'),
        onPressed: _showNewPurchaseReturnDialog,
      ),
    );
  }
}
