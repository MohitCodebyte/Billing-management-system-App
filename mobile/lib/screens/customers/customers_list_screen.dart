import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final gstinController = TextEditingController();
    final limitController = TextEditingController(text: "100000");

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add New Customer', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer / Firm Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gstinController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credit Limit (₹)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                final cp = Provider.of<CustomerProvider>(context, listen: false);
                final success = await cp.createCustomer({
                  'name': name,
                  'phone': phone,
                  'gstin': gstinController.text.trim(),
                  'credit_limit': double.tryParse(limitController.text) ?? 100000.0,
                });
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer added successfully!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Save Customer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CustomerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cp.fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customer by name, phone or GSTIN...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => cp.fetchCustomers(search: val),
            ),
          ),
          Expanded(
            child: cp.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : cp.customers.isEmpty
                    ? Center(
                        child: Text('No customers found. Tap + to add one.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: () => cp.fetchCustomers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cp.customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final c = cp.customers[idx];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.actionBlue.withOpacity(0.12),
                                  child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppColors.actionBlue, fontWeight: FontWeight.w700)),
                                ),
                                title: Text(c.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  "${c.phone} • Limit: ${AppFormatters.formatCompactCurrency(c.creditLimit)}",
                                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(c.currentBalance),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: c.currentBalance > 0 ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      c.currentBalance > 0 ? 'Receivable (Due)' : 'Cleared',
                                      style: TextStyle(fontSize: 10, color: c.currentBalance > 0 ? AppColors.danger : AppColors.success),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/customer-details', arguments: c.id);
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
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        onPressed: _showAddCustomerDialog,
      ),
    );
  }
}
