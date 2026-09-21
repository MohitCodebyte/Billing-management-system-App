import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class GstReportsScreen extends StatefulWidget {
  const GstReportsScreen({super.key});

  @override
  State<GstReportsScreen> createState() => _GstReportsScreenState();
}

class _GstReportsScreenState extends State<GstReportsScreen> {
  String _selectedMonth = "Sep '26";
  final List<String> _months = ["Jul", "Aug", "Sep '26", "Oct"];

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
    final authProv = context.watch<AuthProvider>();
    final business = authProv.business;
    final gstData = reportProv.gstReport;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('GST & Tax Reports'),
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
                const SnackBar(content: Text('Exporting GST Returns Report...')),
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
              : gstData == null
                  ? const EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No GST Data Available',
                      message: 'Generate sales invoices and record purchases to populate GST return data.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => reportProv.fetchAllReports(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Compliance Master Meta Strip
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
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
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          business?.name ?? 'Industrial Supply Corp',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'FY 2026-27',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'GSTIN: ${business?.gstin ?? "27AABCU9603R1ZM"} • Return Period: September 2026',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Month selectors
                          Row(
                            children: _months.map((m) {
                              final isSelected = m == _selectedMonth;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(m),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setState(() => _selectedMonth = m);
                                    reportProv.fetchAllReports();
                                  },
                                  selectedColor: AppColors.primaryBlue,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.secondaryText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Net Cash GST Payable Spotlight Card
                          _buildNetPayableCard(gstData['net_gst_payable'] ?? 0.0),
                          const SizedBox(height: 16),

                          // Outward Supply (GSTR-1)
                          _buildGstSection(
                            title: '1. Outward Supplies (GSTR-1 Sales)',
                            badgeText: 'Liability',
                            badgeColor: AppColors.danger,
                            data: gstData['outward'] as Map<String, dynamic>? ?? {},
                          ),
                          const SizedBox(height: 16),

                          // Inward Supplies / ITC (GSTR-2B)
                          _buildGstSection(
                            title: '2. Input Tax Credit (ITC - Purchases)',
                            badgeText: 'Tax Asset',
                            badgeColor: AppColors.success,
                            data: gstData['inward_itc'] as Map<String, dynamic>? ?? {},
                          ),
                          const SizedBox(height: 24),

                          // Action CTAs
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Export GSTR-1 JSON',
                                  icon: Icons.code,
                                  isOutlined: true,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('GST Portal compatible JSON exported successfully.')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  label: 'Download GSTR-3B PDF',
                                  icon: Icons.picture_as_pdf,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Downloading summary GSTR-3B tax report...')),
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

  Widget _buildNetPayableCard(num netPayable) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NET CASH GST PAYABLE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                      Text(
                        'Outward Tax minus Eligible ITC',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Due 20th Oct',
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppFormatters.formatCurrency(netPayable.toDouble()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Electronic Cash Ledger challan required before filing deadline.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGstSection({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Map<String, dynamic> data,
  }) {
    final taxable = (data['taxable_value'] as num?)?.toDouble() ?? 0.0;
    final cgst = (data['cgst'] as num?)?.toDouble() ?? 0.0;
    final sgst = (data['sgst'] as num?)?.toDouble() ?? 0.0;
    final igst = (data['igst'] as num?)?.toDouble() ?? 0.0;
    final total = (data['total_tax'] as num?)?.toDouble() ?? 0.0;

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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildItemRow('Taxable Value', AppFormatters.formatCurrency(taxable), isBold: true),
          const Divider(height: 16),
          _buildItemRow('Central GST (CGST)', AppFormatters.formatCurrency(cgst)),
          const SizedBox(height: 6),
          _buildItemRow('State GST (SGST)', AppFormatters.formatCurrency(sgst)),
          const SizedBox(height: 6),
          _buildItemRow('Integrated GST (IGST)', AppFormatters.formatCurrency(igst)),
          const Divider(height: 18, thickness: 1.2),
          _buildItemRow('Total Tax', AppFormatters.formatCurrency(total), isBold: true, color: badgeColor),
        ],
      ),
    );
  }

  Widget _buildItemRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primaryText : AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
