import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../models/models.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final int? initialCustomerId;
  const CustomerLedgerScreen({super.key, this.initialCustomerId});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  CustomerModel? _selectedCustomer;
  List<dynamic> _ledgerEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cp = Provider.of<CustomerProvider>(context, listen: false);
      await cp.fetchCustomers();
      if (cp.customers.isNotEmpty) {
        _selectedCustomer = cp.customers.first;
        _fetchLedger();
      }
    });
  }

  Future<void> _fetchLedger() async {
    if (_selectedCustomer == null) return;
    setState(() => _isLoading = true);

    final res = await ApiClient().get("${ApiConstants.customers}/${_selectedCustomer!.id}");
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _ledgerEntries = res.data['ledger_entries'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CustomerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Khata / Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Account Statement',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account statement generated. Sharing via WhatsApp/PDF...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Picker Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _selectedCustomer?.id,
              decoration: const InputDecoration(labelText: 'Select Customer Khata', border: OutlineInputBorder()),
              items: cp.customers.map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text("${c.name} (${c.phone})"),
                );
              }).toList(),
              onChanged: (id) {
                setState(() {
                  _selectedCustomer = cp.customers.firstWhere((c) => c.id == id);
                });
                _fetchLedger();
              },
            ),
          ),

          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT BALANCE DUE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.actionBlue)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatCurrency(_selectedCustomer!.currentBalance),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _selectedCustomer!.currentBalance > 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Text("Credit Limit: ${AppFormatters.formatCurrency(_selectedCustomer!.creditLimit)}",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),

          // Ledger Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Date & Voucher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Debit (+)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Credit (-)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : _ledgerEntries.isEmpty
                    ? const Center(child: Text('No ledger entries recorded.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _ledgerEntries.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, idx) {
                          final e = _ledgerEntries[idx];
                          final debit = (e['debit_amount'] as num? ?? 0.0).toDouble();
                          final credit = (e['credit_amount'] as num? ?? 0.0).toDouble();
                          final bal = (e['running_balance'] as num? ?? 0.0).toDouble();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${e['voucher_type']}",
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        "${e['voucher_number']}\n${AppFormatters.formatDate(e['entry_date'])}",
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    debit > 0 ? AppFormatters.formatCurrency(debit) : '-',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: debit > 0 ? AppColors.danger : null),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    credit > 0 ? AppFormatters.formatCurrency(credit) : '-',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: credit > 0 ? AppColors.success : null),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    AppFormatters.formatCurrency(bal),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
