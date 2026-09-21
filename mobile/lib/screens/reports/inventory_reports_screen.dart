import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();
    final invData = reportProv.inventoryReport;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Inventory Valuation & Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reportProv.fetchAllReports(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting Inventory Audit Report...')),
              );
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: reportProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportProv.errorMessage != null
              ? ErrorView(
                  message: reportProv.errorMessage!,
                  onRetry: () => reportProv.fetchAllReports(),
                )
              : invData == null
                  ? const EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Inventory Data',
                      message: 'Add products and record stock to view valuation audits.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => reportProv.fetchAllReports(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Warehouse banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warehouse, color: AppColors.primaryBlue, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Main Warehouse Depot • Central Stock',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Audited: Realtime',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Valuation Hero Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue, size: 18),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'TOTAL STOCK VALUATION',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Landed Cost Basis',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppFormatters.formatCurrency(invData['total_valuation'] ?? 0.0),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Derived from ${invData['total_items'] ?? 0} catalog product lines',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // KPI Strip
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Catalog SKUs',
                                  value: '${invData['total_items'] ?? 0}',
                                  subtitle: 'Active lines',
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MetricCard(
                                  title: 'Low Stock',
                                  value: '${invData['low_stock_count'] ?? 0}',
                                  subtitle: 'Buffer alert',
                                  icon: Icons.warning_amber_rounded,
                                  isPositive: (invData['low_stock_count'] ?? 0) == 0,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MetricCard(
                                  title: 'Out of Stock',
                                  value: '${invData['out_of_stock_count'] ?? 0}',
                                  subtitle: 'Zero count',
                                  icon: Icons.error_outline,
                                  isPositive: (invData['out_of_stock_count'] ?? 0) == 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Filter chips
                          Row(
                            children: [
                              _buildFilterChip('ALL', 'All Items'),
                              const SizedBox(width: 8),
                              _buildFilterChip('LOW_STOCK', 'Low Stock'),
                              const SizedBox(width: 8),
                              _buildFilterChip('OUT_OF_STOCK', 'Out of Stock'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Items List
                          ..._buildFilteredItems(invData['items'] as List<dynamic>? ?? []),
                          const SizedBox(height: 20),

                          // Action CTAs
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Export Audit PDF',
                                  icon: Icons.picture_as_pdf,
                                  isOutlined: true,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Generating stock audit PDF...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  label: 'Download CSV',
                                  icon: Icons.table_chart,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Downloading inventory CSV table...')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.secondaryText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
      ),
    );
  }

  List<Widget> _buildFilteredItems(List<dynamic> items) {
    var filtered = items;
    if (_selectedFilter != 'ALL') {
      filtered = items.where((it) => it['status'] == _selectedFilter).toList();
    }

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('No items matching "$_selectedFilter"', style: TextStyle(color: AppColors.secondaryText)),
        )
      ];
    }

    return filtered.map((it) {
      final status = (it['status'] ?? 'IN_STOCK').toString();
      Color statusColor = AppColors.success;
      if (status == 'LOW_STOCK') statusColor = AppColors.warning;
      if (status == 'OUT_OF_STOCK') statusColor = AppColors.danger;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it['name'] ?? 'Product',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${it['sku'] ?? '-'} • Unit Cost: ${AppFormatters.formatCurrency(it['purchase_price'] ?? 0.0)}',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${it['stock'] ?? 0} ${it['unit'] ?? "PCS"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: status == 'OUT_OF_STOCK' ? AppColors.danger : AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.formatCurrency(it['valuation'] ?? 0.0),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
