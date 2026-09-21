import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<dynamic> _branches = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.branches);
    if (!mounted) return;

    if (res.success && res.data is List) {
      setState(() {
        _branches = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load branches';
        _isLoading = false;
      });
    }
  }

  void _showAddBranchDialog([Map<String, dynamic>? branch]) {
    final isEditing = branch != null;
    final nameCtrl = TextEditingController(text: branch?['name'] ?? '');
    final codeCtrl = TextEditingController(text: branch?['code'] ?? '');
    final phoneCtrl = TextEditingController(text: branch?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: branch?['email'] ?? '');
    final addrCtrl = TextEditingController(text: branch?['address'] ?? '');
    final cityCtrl = TextEditingController(text: branch?['city'] ?? '');
    final stateCtrl = TextEditingController(text: branch?['state'] ?? 'Maharashtra');
    final gstinCtrl = TextEditingController(text: branch?['gstin'] ?? '');
    bool isHeadOffice = branch?['is_head_office'] ?? false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Branch' : 'Add New Branch',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Branch Name *', prefixIcon: Icon(Icons.store_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      enabled: !isEditing,
                      decoration: const InputDecoration(labelText: 'Branch Code (e.g. BR02) *', prefixIcon: Icon(Icons.qr_code)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact Phone', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Branch Email', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrCtrl,
                      decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: gstinCtrl,
                      decoration: const InputDecoration(labelText: 'Branch GSTIN (if separate)', prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Head Office / Central Depot', style: TextStyle(fontSize: 14)),
                      value: isHeadOffice,
                      onChanged: (val) => setModalState(() => isHeadOffice = val),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: isEditing ? 'Save Changes' : 'Create Branch',
                      isLoading: isSaving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim();

                        if (name.isEmpty || code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name and Code are required.')),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);

                        final payload = {
                          'name': name,
                          'code': code,
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'state': stateCtrl.text.trim(),
                          'gstin': gstinCtrl.text.trim(),
                          'is_head_office': isHeadOffice,
                        };

                        final res = isEditing
                            ? await ApiClient().put('${ApiConstants.branches}/${branch['id']}', body: payload)
                            : await ApiClient().post(ApiConstants.branches, body: payload);

                        setModalState(() => isSaving = false);

                        if (!mounted) return;
                        if (res.success) {
                          Navigator.pop(ctx);
                          _fetchBranches();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message ?? 'Branch saved successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message ?? 'Failed to save branch')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _switchBranch(int branchId, String branchName) async {
    final res = await ApiClient().post(ApiConstants.switchBranch, body: {'branch_id': branchId});
    if (!mounted) return;
    if (res.success) {
      // update local user branch
      final auth = context.read<AuthProvider>();
      await auth.loadUserFromStorage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched active branch to $branchName')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to switch branch')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final currentBranchId = authUser?.branchId;

    final filtered = _branches.where((b) {
      final name = (b['name'] ?? '').toString().toLowerCase();
      final code = (b['code'] ?? '').toString().toLowerCase();
      final city = (b['city'] ?? '').toString().toLowerCase();
      return _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase()) ||
          city.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Branch Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBranches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchBranches)
              : RefreshIndicator(
                  onRefresh: _fetchBranches,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Top Action & Search
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: const InputDecoration(
                                  hintText: 'Search branch name, code, city...',
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add Branch'),
                            onPressed: () => _showAddBranchDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metrics
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              title: 'Total Branches',
                              value: '${_branches.length}',
                              subtitle: 'Registered units',
                              icon: Icons.storefront,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricCard(
                              title: 'Operating Units',
                              value: '${_branches.length} Active',
                              subtitle: 'Live synchronization',
                              icon: Icons.check_circle_outline,
                              isPositive: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'ALL LOCATIONS & DEPOTS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),

                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No branches found', style: TextStyle(color: AppColors.secondaryText)),
                          ),
                        )
                      else
                        ...filtered.map((b) {
                          final isCurrent = b['id'] == currentBranchId;
                          final isHead = b['is_head_office'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent ? AppColors.primaryBlue : AppColors.border,
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          b['name'] ?? 'Branch',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            b['code'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                        if (isHead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.deepNavy.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'HEAD OFFICE',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check, size: 12, color: AppColors.success),
                                            SizedBox(width: 4),
                                            Text(
                                              'Active Outlet',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${b['address'] ?? ''}, ${b['city'] ?? ''}, ${b['state'] ?? ''}',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${b['phone'] ?? '-'} • GSTIN: ${b['gstin'] ?? 'Shared'}',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      onPressed: () => _showAddBranchDialog(b),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isCurrent)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.swap_horiz, size: 16),
                                        label: const Text('Switch Branch'),
                                        onPressed: () => _switchBranch(b['id'], b['name']),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
