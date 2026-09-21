import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  String _selectedFilter = 'This Month';
  final List<String> _filters = ['Today', 'This Week', 'This Month', 'Last Month', 'This Year'];

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
    final salesData = reportProv.salesAnalytics;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reportProv.fetchAllReports(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting sales analytics summary...')),
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
              : salesData == null
                  ? const EmptyStateView(
                      icon: Icons.analytics_outlined,
                      title: 'No Analytics Data',
                      message: 'Complete some billing invoices to view sales analytics.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => reportProv.fetchAllReports(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Filter scroller
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filters.map((f) {
                                final isSelected = f == _selectedFilter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(f),
                                    onSelected: (val) {
                                      setState(() => _selectedFilter = f);
                                      reportProv.fetchAllReports();
                                    },
                                    selectedColor: AppColors.primaryBlue,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.secondaryText,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primaryBlue : AppColors.border,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Active Window Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available, color: AppColors.primaryBlue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Filter Window: $_selectedFilter',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text(
                                        'Real-time transaction aggregate',
                                        style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Live Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // KPI Cards Grid
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Sales',
                                  value: AppFormatters.formatCurrency(salesData['total_sales'] ?? 0.0),
                                  subtitle: 'GST inclusive',
                                  icon: Icons.payments_outlined,
                                  isPositive: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Invoices Built',
                                  value: '${salesData['invoice_count'] ?? 0} Bills',
                                  subtitle: 'Total volume',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Taxable Revenue',
                                  value: AppFormatters.formatCurrency(salesData['total_taxable'] ?? 0.0),
                                  subtitle: 'Pre-tax base',
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Total GST Collected',
                                  value: AppFormatters.formatCurrency(salesData['total_gst'] ?? 0.0),
                                  subtitle: 'Outward tax',
                                  icon: Icons.percent,
                                  isPositive: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Received',
                                  value: AppFormatters.formatCurrency(salesData['total_paid'] ?? 0.0),
                                  subtitle: 'Settled funds',
                                  icon: Icons.check_circle_outline,
                                  isPositive: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Outstanding Dues',
                                  value: AppFormatters.formatCurrency(salesData['total_outstanding'] ?? 0.0),
                                  subtitle: 'Receivables',
                                  icon: Icons.pending_actions,
                                  isPositive: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Trend Chart
                          _buildTrendChart(salesData['trend'] as List<dynamic>? ?? []),
                          const SizedBox(height: 24),

                          // Action CTAs
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Download Report',
                                  icon: Icons.download,
                                  isOutlined: true,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Generating Sales Analytics PDF report...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  label: 'Share Summary',
                                  icon: Icons.share,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sharing Sales Summary to WhatsApp/Email...')),
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

  Widget _buildTrendChart(List<dynamic> trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Revenue Trend',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Daily Growth',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (trend.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text('No daily data available for this range', style: TextStyle(color: AppColors.secondaryText)),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < trend.length) {
                            final dateStr = (trend[idx]['date'] ?? '').toString();
                            final parts = dateStr.split('-');
                            final day = parts.length > 2 ? parts[2] : dateStr;
                            return Text(day, style: TextStyle(fontSize: 10, color: AppColors.secondaryText));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000) {
                            return Text('${(value / 1000).toStringAsFixed(0)}k', style: TextStyle(fontSize: 10, color: AppColors.secondaryText));
                          }
                          return Text(value.toStringAsFixed(0), style: TextStyle(fontSize: 10, color: AppColors.secondaryText));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < trend.length; i++)
                          FlSpot(i.toDouble(), (trend[i]['amount'] as num?)?.toDouble() ?? 0.0),
                      ],
                      isCurved: true,
                      color: AppColors.primaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryBlue.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
