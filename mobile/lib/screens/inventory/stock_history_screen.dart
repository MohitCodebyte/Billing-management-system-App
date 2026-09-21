import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common_widgets.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final res = await ApiClient().get(ApiConstants.inventoryHistory);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _history = res.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Audit Log'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
          : _history.isEmpty
              ? const Center(child: Text('No stock movements logged yet.'))
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _history[idx];
                      final type = item['movement_type'] ?? 'IN';
                      final isPlus = type == 'IN' || type == 'RETURN';

                      return Card(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPlus ? AppColors.successBg : AppColors.dangerBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlus ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isPlus ? AppColors.success : AppColors.danger,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            item['product_name'] ?? 'Item',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            "${item['notes'] ?? ''}\n${AppFormatters.formatDateTime(item['created_at'])}",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isPlus ? '+' : '-'}${item['quantity']} ${item['unit'] ?? ''}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isPlus ? AppColors.success : AppColors.danger,
                                ),
                              ),
                              Text(
                                "Prev: ${item['previous_quantity']} → New: ${item['new_quantity']}",
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
