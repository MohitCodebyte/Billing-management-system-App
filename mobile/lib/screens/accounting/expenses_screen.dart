import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get(ApiConstants.expenses);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _expenses = res.data;
      }
    });
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final vendorController = TextEditingController();
    String method = "CASH";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Record Operating Expense', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Expense Description *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vendorController,
                    decoration: const InputDecoration(labelText: 'Paid To / Vendor', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('Petty Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI / PhonePe / GPay')),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer / Cheque')),
                    ],
                    onChanged: (val) => setDState(() => method = val ?? 'CASH'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    final t = titleController.text.trim();
                    final a = double.tryParse(amountController.text) ?? 0.0;
                    if (t.isEmpty || a <= 0) return;

                    final res = await ApiClient().post(ApiConstants.expenses, body: {
                      'title': t,
                      'amount': a,
                      'vendor': vendorController.text.trim(),
                      'payment_method': method,
                    });
                    Navigator.pop(ctx);
                    if (res.success) {
                      _fetchExpenses();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense logged successfully!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  child: const Text('Save Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExpense = _expenses.fold(0.0, (acc, e) => acc + (e['amount'] as num? ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Expenses'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchExpenses),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFFEF2F2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL EXPENSES (MTD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger)),
                Text(AppFormatters.formatCurrency(totalExpense), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : _expenses.isEmpty
                    ? const Center(child: Text('No operational expenses recorded.'))
                    : RefreshIndicator(
                        onRefresh: _fetchExpenses,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _expenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final e = _expenses[idx];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.receipt_outlined, color: AppColors.danger, size: 20),
                                ),
                                title: Text(e['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                subtitle: Text("${e['vendor'] ?? 'Cash'} • ${AppFormatters.formatDate(e['expense_date'])}"),
                                trailing: Text(
                                  AppFormatters.formatCurrency(e['amount']),
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
                                ),
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
        label: const Text('Add Expense'),
        onPressed: _showAddExpenseDialog,
      ),
    );
  }
}
