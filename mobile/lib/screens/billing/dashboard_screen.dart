import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.dashboard);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _dashboardData = res.data;
      } else {
        _error = res.error ?? "Failed to load dashboard metrics";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = _dashboardData?['stats'] ?? {};
    final recentInvoices = (_dashboardData?['recent_invoices'] as List?) ?? [];
    final lowStockItems = (_dashboardData?['low_stock_items'] as List?) ?? [];

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.business?.name ?? 'BharatLedger Pro',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  auth.branch?.name ?? 'Main Warehouse',
                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        AppButton(text: 'Retry', onPressed: _loadDashboard, height: 40),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: AppColors.actionBlue,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Hero Banner with Quick New Bill CTA
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TODAY'S REVENUE",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppFormatters.formatCurrency(stats['today_sales']),
                                      style: GoogleFonts.inter(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.receipt_outlined, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${stats['today_invoices'] ?? 0} Bills",
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/billing'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.actionBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.point_of_sale, size: 20),
                                label: Text(
                                  'Generate New Bill (POS)',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics 2x2 Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          MetricCard(
                            title: 'Receivables (Due)',
                            value: AppFormatters.formatCurrency(stats['total_receivables']),
                            icon: Icons.call_received,
                            iconColor: AppColors.warning,
                            onTap: () => Navigator.pushNamed(context, '/payments'),
                          ),
                          MetricCard(
                            title: 'Payables (Vendors)',
                            value: AppFormatters.formatCurrency(stats['total_payables']),
                            icon: Icons.call_made,
                            iconColor: AppColors.danger,
                            onTap: () => Navigator.pushNamed(context, '/suppliers'),
                          ),
                          MetricCard(
                            title: 'Stock Valuation',
                            value: AppFormatters.formatCurrency(stats['total_inventory_valuation']),
                            icon: Icons.inventory_2,
                            iconColor: AppColors.actionBlue,
                            onTap: () => Navigator.pushNamed(context, '/inventory'),
                          ),
                          MetricCard(
                            title: 'Low Stock Items',
                            value: "${stats['low_stock_count'] ?? 0} items",
                            icon: Icons.warning_amber_rounded,
                            iconColor: stats['low_stock_count'] != null && stats['low_stock_count'] > 0 ? AppColors.danger : AppColors.success,
                            onTap: () => Navigator.pushNamed(context, '/stock'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Low stock alert carousel
                      if (lowStockItems.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notification_important, size: 18, color: AppColors.danger),
                                const SizedBox(width: 6),
                                Text(
                                  'Restock Priority Alerts',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/stock'),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...lowStockItems.map((item) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.warning, color: AppColors.danger, size: 20),
                              ),
                              title: Text(item['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: Text("SKU: ${item['sku']} • Min: ${item['min_stock']} ${item['unit']}", style: GoogleFonts.inter(fontSize: 12)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${item['current_stock']} ${item['unit']}",
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
                                  ),
                                  const Text("Remaining", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(context, '/stock'),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Recent Invoices section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Invoices',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/invoices'),
                            child: const Text('All Invoices'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (recentInvoices.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              'No invoices generated yet. Tap "Generate New Bill" to begin.',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...recentInvoices.map((inv) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.actionBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt, color: AppColors.actionBlue, size: 20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(inv['invoice_number'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text(
                                    AppFormatters.formatCurrency(inv['grand_total']),
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      inv['customer_name'] ?? '',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  StatusBadge(status: inv['status'] ?? 'ISSUED'),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/invoice-details',
                                  arguments: inv['id'],
                                );
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          ApiConstants.copyright,
                          style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
