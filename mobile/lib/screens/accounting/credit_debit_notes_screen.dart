import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class CreditDebitNotesScreen extends StatefulWidget {
  const CreditDebitNotesScreen({super.key});

  @override
  State<CreditDebitNotesScreen> createState() => _CreditDebitNotesScreenState();
}

class _CreditDebitNotesScreenState extends State<CreditDebitNotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _creditNotes = [];
  List<dynamic> _debitNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    final cnRes = await ApiClient().get(ApiConstants.creditNotes);
    final dnRes = await ApiClient().get(ApiConstants.debitNotes);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (cnRes.success && cnRes.data != null) _creditNotes = cnRes.data;
      if (dnRes.success && dnRes.data != null) _debitNotes = dnRes.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit & Debit Notes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.actionBlue,
          indicatorColor: AppColors.actionBlue,
          tabs: [
            Tab(text: 'Credit Notes (${_creditNotes.length})'),
            Tab(text: 'Debit Notes (${_debitNotes.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                // Credit Notes
                _creditNotes.isEmpty
                    ? const Center(child: Text('No credit notes issued.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _creditNotes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final n = _creditNotes[idx];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt, color: AppColors.success, size: 20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n['note_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                  Text(AppFormatters.formatCurrency(n['amount']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.success)),
                                ],
                              ),
                              subtitle: Text("Customer: ${n['customer_name']}\nReason: ${n['reason']}"),
                              trailing: StatusBadge(status: n['status'] ?? 'ACTIVE'),
                            ),
                          );
                        },
                      ),

                // Debit Notes
                _debitNotes.isEmpty
                    ? const Center(child: Text('No debit notes issued.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _debitNotes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final n = _debitNotes[idx];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.note_alt, color: AppColors.danger, size: 20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n['note_number'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                  Text(AppFormatters.formatCurrency(n['amount']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.danger)),
                                ],
                              ),
                              subtitle: Text("Supplier: ${n['supplier_name']}\nReason: ${n['reason']}"),
                              trailing: StatusBadge(status: n['status'] ?? 'ACTIVE'),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
