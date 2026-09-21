import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Month', 'Last Month', 'Q2 FY27', 'FY 2026-27'];

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
    final pl = reportProv.profitLoss;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Profit & Loss Statement'),
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
                const SnackBar(content: Text('Exporting P&L Statement to PDF...')),
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
              : pl == null
                  ? const EmptyStateView(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No Financial Data',
                      message: 'Record invoices, purchases and expenses to calculate Profit & Loss.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => reportProv.fetchAllReports(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Period tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _periods.map((p) {
                                final isSelected = p == _selectedPeriod;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(p),
                                    onSelected: (val) {
                                      setState(() => _selectedPeriod = p);
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
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Accounting Basis: Accrual • FY 2026-27',
                                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              ),
                              Text(
                                'INR (₹)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Industrial Hero Card (Net Operating Profit)
                          _buildNetProfitHero(pl),
                          const SizedBox(height: 20),

                          // Detailed Financial Computation Sheet
                          _buildLedgerSheet(pl),
                          const SizedBox(height: 24),

                          // Bottom Export Action
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Download P&L Sheet',
                                  icon: Icons.download,
                                  isOutlined: true,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Downloading audited P&L PDF report...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  label: 'Share to CA / Partner',
                                  icon: Icons.send,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sharing P&L Statement via WhatsApp...')),
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

  Widget _buildNetProfitHero(Map<String, dynamic> pl) {
    final netProfit = (pl['net_profit'] as num?)?.toDouble() ?? 0.0;
    final totalRev = (pl['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cogs = (pl['cost_of_goods'] as num?)?.toDouble() ?? 0.0;
    final expenses = (pl['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final margin = (pl['profit_margin_percent'] as num?)?.toDouble() ?? 0.0;
    final isProfit = netProfit >= 0;

    double cogsPct = totalRev > 0 ? (cogs / totalRev).clamp(0.0, 1.0) : 0.0;
    double expPct = totalRev > 0 ? (expenses / totalRev).clamp(0.0, 1.0) : 0.0;
    double netPct = totalRev > 0 ? (netProfit / totalRev).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NET OPERATING PROFIT',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isProfit ? AppColors.success : AppColors.danger).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isProfit ? AppColors.success : AppColors.danger,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${margin.toStringAsFixed(1)}% Margin',
                      style: TextStyle(
                        color: isProfit ? AppColors.success : AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppFormatters.formatCurrency(netProfit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gross Revenue ${AppFormatters.formatCurrency(totalRev)} minus COGS & OpEx',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Pulse bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (cogsPct > 0)
                    Expanded(
                      flex: (cogsPct * 100).toInt(),
                      child: Container(color: Colors.white70),
                    ),
                  if (expPct > 0)
                    Expanded(
                      flex: (expPct * 100).toInt(),
                      child: Container(color: AppColors.warning),
                    ),
                  if (netPct > 0)
                    Expanded(
                      flex: (netPct * 100).toInt(),
                      child: Container(color: AppColors.success),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPulseLegend(Colors.white70, 'COGS: ${(cogsPct * 100).toStringAsFixed(0)}%'),
              _buildPulseLegend(AppColors.warning, 'OpEx: ${(expPct * 100).toStringAsFixed(0)}%'),
              _buildPulseLegend(AppColors.success, 'Net: ${(netPct * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
      ],
    );
  }

  Widget _buildLedgerSheet(Map<String, dynamic> pl) {
    final rev = (pl['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cogs = (pl['cost_of_goods'] as num?)?.toDouble() ?? 0.0;
    final gross = (pl['gross_profit'] as num?)?.toDouble() ?? 0.0;
    final opex = (pl['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final net = (pl['net_profit'] as num?)?.toDouble() ?? 0.0;

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
          const Text(
            'FINANCIAL BREAKDOWN',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          _buildRow('Operating Revenue (Sales)', AppFormatters.formatCurrency(rev), isBold: true),
          const Divider(height: 20),
          _buildRow('Less: Cost of Goods Sold (Purchases)', '- ${AppFormatters.formatCurrency(cogs)}', color: AppColors.danger),
          const Divider(height: 20),
          _buildRow('Gross Profit', AppFormatters.formatCurrency(gross), isBold: true, color: gross >= 0 ? AppColors.success : AppColors.danger),
          const Divider(height: 20),
          _buildRow('Less: Operating Expenses', '- ${AppFormatters.formatCurrency(opex)}', color: AppColors.danger),
          const Divider(height: 24, thickness: 1.5),
          _buildRow('Net Profit (Before Tax)', AppFormatters.formatCurrency(net), isBold: true, fontSize: 16, color: net >= 0 ? AppColors.success : AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.primaryText : AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
