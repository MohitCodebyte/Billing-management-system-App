import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);

    final params = <String, dynamic>{};
    if (_selectedStatus != null) params['status'] = _selectedStatus;
    if (_searchController.text.isNotEmpty) params['search'] = _searchController.text.trim();

    final res = await ApiClient().get(ApiConstants.invoices, queryParams: params);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        final List raw = res.data;
        _invoices = raw.map((j) => InvoiceModel.fromJson(j)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses = [
      {'label': 'All', 'value': null},
      {'label': 'Paid', 'value': 'PAID'},
      {'label': 'Partial', 'value': 'PARTIAL'},
      {'label': 'Issued', 'value': 'ISSUED'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by Invoice Number...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _fetchInvoices(),
            ),
          ),

          // Status Filter Tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: statuses.map((s) {
                final isSelected = _selectedStatus == s['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s['label'] as String),
                    selected: isSelected,
                    selectedColor: AppColors.actionBlue,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12),
                    onSelected: (val) {
                      setState(() => _selectedStatus = s['value']);
                      _fetchInvoices();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : _invoices.isEmpty
                    ? Center(
                        child: Text('No invoices found.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchInvoices,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _invoices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final inv = _invoices[idx];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.actionBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: AppColors.actionBlue, size: 20),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(inv.invoiceNumber, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                                    Text(
                                      AppFormatters.formatCurrency(inv.grandTotal),
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(
                                      "${inv.customerName} • ${AppFormatters.formatDate(inv.invoiceDate)}",
                                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        StatusBadge(status: inv.status),
                                        if (inv.balanceAmount > 0)
                                          Text(
                                            "Due: ${AppFormatters.formatCurrency(inv.balanceAmount)}",
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/invoice-details', arguments: inv.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.actionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
        onPressed: () => Navigator.pushNamed(context, '/billing'),
      ),
    );
  }
}
