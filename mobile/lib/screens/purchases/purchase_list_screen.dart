import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  List<dynamic> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get(ApiConstants.purchases);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _purchases = res.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders & Bills'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPurchases),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _purchases.isEmpty
              ? const Center(child: Text('No purchase orders recorded yet.'))
              : RefreshIndicator(
                  onRefresh: _fetchPurchases,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final p = _purchases[idx];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryIndigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.secondaryIndigo, size: 20),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p['purchase_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              Text(AppFormatters.formatCurrency(p['grand_total']), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text("${p['supplier_name']} • ${AppFormatters.formatDate(p['purchase_date'])}"),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(status: p['status'] ?? 'RECEIVED'),
                                  if ((p['balance_amount'] as num? ?? 0) > 0)
                                    Text(
                                      "Payable: ${AppFormatters.formatCurrency(p['balance_amount'])}",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/purchase-details', arguments: p['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Purchase Bill'),
        onPressed: () => Navigator.pushNamed(context, '/new-purchase'),
      ),
    );
  }
}
