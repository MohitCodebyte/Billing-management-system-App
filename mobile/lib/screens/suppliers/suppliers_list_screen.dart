import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/supplier_provider.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplierProvider>(context, listen: false).fetchSuppliers();
    });
  }

  void _showAddSupplierDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final gstinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Supplier', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Supplier / Vendor Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Phone *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstinController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionBlue, foregroundColor: Colors.white),
              onPressed: () async {
                final n = nameController.text.trim();
                final p = phoneController.text.trim();
                if (n.isEmpty || p.isEmpty) return;

                final sp = Provider.of<SupplierProvider>(context, listen: false);
                await sp.createSupplier({'name': n, 'phone': p, 'gstin': gstinController.text.trim()});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Supplier added successfully!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Save Supplier'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SupplierProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Vendors'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => sp.fetchSuppliers()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search suppliers by name or phone...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => sp.fetchSuppliers(search: val),
            ),
          ),
          Expanded(
            child: sp.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionBlue))
                : sp.suppliers.isEmpty
                    ? Center(child: Text('No suppliers recorded.', style: GoogleFonts.inter(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: () => sp.fetchSuppliers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sp.suppliers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final s = sp.suppliers[idx];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.secondaryIndigo.withOpacity(0.12),
                                  child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: AppColors.secondaryIndigo, fontWeight: FontWeight.w700)),
                                ),
                                title: Text(s.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                                subtitle: Text("${s.phone} • GSTIN: ${s.gstin.isNotEmpty ? s.gstin : 'None'}"),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(s.currentPayable),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: s.currentPayable > 0 ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                    const Text('Payable Due', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/supplier-details', arguments: s.id);
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
        icon: const Icon(Icons.add_business),
        label: const Text('Add Supplier'),
        onPressed: _showAddSupplierDialog,
      ),
    );
  }
}
