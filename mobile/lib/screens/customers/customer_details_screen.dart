import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
  CustomerModel? _customer;
  List<dynamic> _recentInvoices = [];
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
    final res = await ApiClient().get("${ApiConstants.customers}/${widget.customerId}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _customer = CustomerModel.fromJson(res.data);
        _recentInvoices = res.data['recent_invoices'] ?? [];
        _ledgerEntries = res.data['ledger_entries'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.actionBlue)),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final c = _customer!;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.actionBlue,
                                child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                    if (c.companyName.isNotEmpty)
                                      Text(c.companyName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text("Phone: ${c.phone}", style: const TextStyle(fontSize: 13)),
                                    if (c.gstin.isNotEmpty)
                                      Text("GSTIN: ${c.gstin}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Outstanding Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.formatCurrency(c.currentBalance),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: c.currentBalance > 0 ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 30, width: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                              Column(
                                children: [
                                  const Text('Credit Limit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.formatCurrency(c.creditLimit),
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons Row (Call, WhatsApp, Create Bill)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${c.phone}...')));
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sending payment reminder to ${c.phone} via WhatsApp...')),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.actionBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.actionBlue,
                tabs: const [
                  Tab(text: 'Invoices History'),
                  Tab(text: 'Account Ledger'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Invoices
            _recentInvoices.isEmpty
                ? const Center(child: Text('No invoice history for this customer.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recentInvoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final inv = _recentInvoices[idx];
                      return Card(
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(inv['invoice_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              Text(AppFormatters.formatCurrency(inv['grand_total']), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          subtitle: Text(AppFormatters.formatDate(inv['invoice_date'])),
                          trailing: StatusBadge(status: inv['status'] ?? 'ISSUED'),
                          onTap: () => Navigator.pushNamed(context, '/invoice-details', arguments: inv['id']),
                        ),
                      );
                    },
                  ),

            // Tab 2: Ledger
            _ledgerEntries.isEmpty
                ? const Center(child: Text('No ledger transactions recorded yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ledgerEntries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final e = _ledgerEntries[idx];
                      final isDebit = (e['debit_amount'] as num? ?? 0) > 0;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDebit ? AppColors.dangerBg : AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDebit ? AppColors.danger : AppColors.success,
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
                              isDebit ? "+ ${AppFormatters.formatCurrency(e['debit_amount'])}" : "- ${AppFormatters.formatCurrency(e['credit_amount'])}",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDebit ? AppColors.danger : AppColors.success,
                              ),
                            ),
                            Text("Bal: ${AppFormatters.formatCurrency(e['running_balance'])}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
