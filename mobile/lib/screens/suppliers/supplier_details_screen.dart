import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final int supplierId;
  const SupplierDetailsScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> with SingleTickerProviderStateMixin {
  SupplierModel? _supplier;
  List<dynamic> _recentPurchases = [];
  List<dynamic> _ledgerEntries = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get("${ApiConstants.suppliers}/${widget.supplierId}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _supplier = SupplierModel.fromJson(res.data);
        _recentPurchases = res.data['recent_purchases'] ?? [];
        _ledgerEntries = res.data['ledger_entries'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.actionBlue)),
      );
    }

    if (_supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Details')),
        body: const Center(child: Text('Supplier not found')),
      );
    }

    final s = _supplier!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDetails),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (s.companyName.isNotEmpty)
                        Text(s.companyName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text("Phone: ${s.phone} • GSTIN: ${s.gstin.isNotEmpty ? s.gstin : 'Unregistered'}", style: const TextStyle(fontSize: 12)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Outstanding Payable:', style: TextStyle(fontSize: 14)),
                          Text(
                            AppFormatters.formatCurrency(s.currentPayable),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: s.currentPayable > 0 ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.actionBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.actionBlue,
                tabs: const [
                  Tab(text: 'Purchase Bills'),
                  Tab(text: 'Payable Ledger'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Purchases
            _recentPurchases.isEmpty
                ? const Center(child: Text('No purchase records for this vendor.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recentPurchases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final p = _recentPurchases[idx];
                      return Card(
                        child: ListTile(
                          title: Text(p['purchase_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          subtitle: Text(AppFormatters.formatDate(p['purchase_date'])),
                          trailing: Text(AppFormatters.formatCurrency(p['grand_total']), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          onTap: () => Navigator.pushNamed(context, '/purchase-details', arguments: p['id']),
                        ),
                      );
                    },
                  ),

            // Ledger
            _ledgerEntries.isEmpty
                ? const Center(child: Text('No ledger entries recorded.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ledgerEntries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final e = _ledgerEntries[idx];
                      final isCredit = (e['credit_amount'] as num? ?? 0) > 0;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCredit ? AppColors.dangerBg : AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isCredit ? AppColors.danger : AppColors.success,
                            size: 16,
                          ),
                        ),
                        title: Text("${e['voucher_type']} • ${e['voucher_number']}", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text("${AppFormatters.formatDate(e['entry_date'])}\n${e['narration'] ?? ''}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isCredit ? "+ ${AppFormatters.formatCurrency(e['credit_amount'])}" : "- ${AppFormatters.formatCurrency(e['debit_amount'])}",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isCredit ? AppColors.danger : AppColors.success,
                              ),
                            ),
                            Text("Payable: ${AppFormatters.formatCurrency(e['running_balance'])}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}
