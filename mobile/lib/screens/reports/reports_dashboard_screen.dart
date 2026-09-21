import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        'title': '32. Sales Analytics & Trends',
        'desc': 'Daily & monthly revenue curves, invoice counts, top customers.',
        'icon': Icons.bar_chart,
        'route': '/sales-analytics',
        'color': AppColors.actionBlue,
      },
      {
        'title': '33. Profit & Loss Statement',
        'desc': 'Sales revenue minus cost of goods sold and operating expenses.',
        'icon': Icons.trending_up,
        'route': '/profit-loss',
        'color': AppColors.success,
      },
      {
        'title': '34. GST & Tax Audit Reports',
        'desc': 'GSTR-1 outward tax liability, GSTR-3B summary, and ITC input credit.',
        'icon': Icons.account_balance,
        'route': '/gst-reports',
        'color': AppColors.secondaryIndigo,
      },
      {
        'title': '35. Stock Valuation & Inventory',
        'desc': 'Total inventory asset value, low stock warnings, out-of-stock items.',
        'icon': Icons.inventory_2,
        'route': '/inventory-reports',
        'color': AppColors.warning,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial & Tax Reports'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final r = reports[idx];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(context, r['route'] as String),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (r['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(r['icon'] as IconData, color: r['color'] as Color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'] as String,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
