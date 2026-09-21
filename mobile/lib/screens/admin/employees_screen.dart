import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedRole = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.employees);
    if (!mounted) return;

    if (res.success && res.data is List) {
      setState(() {
        _employees = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load employees';
        _isLoading = false;
      });
    }
  }

  static final Map<String, List<String>> _defaultRolePerms = {
    'admin': ['all'],
    'manager': ['billing.view', 'billing.create', 'invoices.view', 'customers.view', 'customers.create', 'products.view', 'products.create', 'inventory.adjust', 'stock.history', 'purchases.view', 'purchases.create', 'suppliers.view', 'payments.view', 'payments.create', 'expenses.view', 'reports.sales'],
    'cashier': ['billing.view', 'billing.create', 'invoices.view', 'customers.view', 'customers.create', 'products.view', 'payments.view', 'payments.create'],
    'salesperson': ['billing.view', 'billing.create', 'invoices.view', 'customers.view', 'customers.create', 'products.view', 'payments.create'],
    'accountant': ['payments.view', 'payments.create', 'expenses.view', 'expenses.create', 'reports.profit_loss', 'reports.gst', 'invoices.view'],
    'inventory manager': ['products.view', 'products.create', 'inventory.adjust', 'stock.history', 'purchases.view', 'purchases.create', 'suppliers.view', 'reports.inventory'],
    'staff': ['dashboard.view', 'notifications.view'],
  };

  void _showAddEmployeeDialog([Map<String, dynamic>? employee]) {
    final isEditing = employee != null;
    final nameCtrl = TextEditingController(text: employee?['name'] ?? '');
    final emailCtrl = TextEditingController(text: employee?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: employee?['phone'] ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = (employee?['role'] ?? 'staff').toString().toLowerCase();
    if (!_defaultRolePerms.containsKey(selectedRole)) {
      selectedRole = 'staff';
    }

    final existingPerms = (employee?['permissions'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    final Set<String> selectedPermissions = existingPerms.isNotEmpty
        ? Set.from(existingPerms)
        : Set.from(_defaultRolePerms[selectedRole] ?? []);

    final allAvailablePerms = [
      'billing.view',
      'billing.create',
      'invoices.view',
      'customers.view',
      'customers.create',
      'products.view',
      'products.create',
      'inventory.adjust',
      'stock.history',
      'purchases.view',
      'purchases.create',
      'suppliers.view',
      'payments.view',
      'payments.create',
      'expenses.view',
      'expenses.create',
      'reports.sales',
      'reports.profit_loss',
      'reports.gst',
      'reports.inventory',
      'employees.view',
      'branches.view',
      'settings.view',
    ];

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
                          isEditing ? 'Edit Employee & Permissions' : 'Add New Employee',
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      enabled: !isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'New Password (leave blank to keep)' : 'Temporary Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign System Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.security_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Full System Access)')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager (Store Operations)')),
                        DropdownMenuItem(value: 'cashier', child: Text('Cashier (Billing & Invoices)')),
                        DropdownMenuItem(value: 'salesperson', child: Text('Salesperson (Catalog & Sales)')),
                        DropdownMenuItem(value: 'accountant', child: Text('Accountant (Ledgers & Reports)')),
                        DropdownMenuItem(value: 'inventory manager', child: Text('Inventory Manager (Stock & Suppliers)')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff (Read-only)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedRole = val;
                            selectedPermissions.clear();
                            selectedPermissions.addAll(_defaultRolePerms[val] ?? []);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Granular Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedPermissions.clear();
                              selectedPermissions.addAll(_defaultRolePerms[selectedRole] ?? []);
                            });
                          },
                          child: const Text('Reset Defaults', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allAvailablePerms.map((perm) {
                          final isGranted = selectedPermissions.contains(perm) || selectedPermissions.contains('all');
                          return FilterChip(
                            label: Text(perm, style: TextStyle(fontSize: 11, color: isGranted ? Colors.white : AppColors.textPrimary)),
                            selected: isGranted,
                            selectedColor: AppColors.actionBlue,
                            checkmarkColor: Colors.white,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedPermissions.add(perm);
                                } else {
                                  selectedPermissions.remove(perm);
                                  selectedPermissions.remove('all');
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: isEditing ? 'Save Changes' : 'Create Account',
                      isLoading: isSaving,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (name.isEmpty || email.isEmpty || phone.isEmpty || (!isEditing && pass.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);

                        final payload = {
                          'name': name,
                          'email': email,
                          'phone': phone,
                          'role': selectedRole,
                          'permissions': selectedPermissions.toList(),
                          if (pass.isNotEmpty) 'password': pass,
                        };

                        final res = isEditing
                            ? await ApiClient().put('${ApiConstants.employees}/${employee['id']}', body: payload)
                            : await ApiClient().post(ApiConstants.employees, body: payload);

                        setModalState(() => isSaving = false);

                        if (!mounted) return;
                        if (res.success) {
                          Navigator.pop(ctx);
                          _fetchEmployees();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message ?? 'Employee saved successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message ?? 'Failed to save employee')),
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

  @override
  Widget build(BuildContext context) {
    final currentRole = context.watch<AuthProvider>().user?.role ?? '';
    final isAdmin = currentRole.toLowerCase() == 'admin';

    final filtered = _employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final phone = (e['phone'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      final role = (e['role'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          role.contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRole == 'ALL' || role == _selectedRole.toLowerCase();

      return matchesSearch && matchesRole;
    }).toList();

    int totalStaff = _employees.length;
    int totalAdmins = _employees.where((e) => (e['role'] ?? '').toString().toLowerCase() == 'admin').length;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Employees & Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmployees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchEmployees)
              : RefreshIndicator(
                  onRefresh: _fetchEmployees,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header CTA
                      if (isAdmin)
                        AppButton(
                          label: '+ Add Employee',
                          icon: Icons.person_add_alt_1,
                          onPressed: () => _showAddEmployeeDialog(),
                        ),
                      const SizedBox(height: 16),

                      // Stat Bento Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Total Staff',
                              count: '$totalStaff',
                              icon: Icons.group,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Active Roles',
                              count: '$totalStaff',
                              icon: Icons.verified_user,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Admins',
                              count: '$totalAdmins',
                              icon: Icons.admin_panel_settings,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Branches',
                              count: '1 Active',
                              icon: Icons.storefront,
                              color: AppColors.secondaryIndigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            hintText: 'Search by name, phone, role...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Role Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'ADMIN', 'MANAGER', 'CASHIER', 'SALESPERSON', 'ACCOUNTANT', 'INVENTORY MANAGER', 'STAFF'].map((r) {
                            final isSel = _selectedRole == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSel,
                                label: Text(r),
                                onSelected: (val) => setState(() => _selectedRole = r),
                                selectedColor: AppColors.primaryBlue,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppColors.secondaryText,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 11,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: isSel ? AppColors.primaryBlue : AppColors.border),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Employees list
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No employees found', style: TextStyle(color: AppColors.secondaryText)),
                          ),
                        )
                      else
                        ...filtered.map((emp) => _buildEmployeeCard(emp, isAdmin)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp, bool isAdmin) {
    final role = (emp['role'] ?? 'staff').toString().toUpperCase();
    final name = emp['name'] ?? 'Staff Member';
    final email = emp['email'] ?? '';
    final phone = emp['phone'] ?? '';

    Color roleColor = AppColors.primaryBlue;
    if (role == 'ADMIN') roleColor = AppColors.deepNavy;
    if (role == 'MANAGER') roleColor = AppColors.secondaryIndigo;
    if (role == 'CASHIER') roleColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$phone • $email',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) async {
                if (val == 'edit') {
                  _showAddEmployeeDialog(emp);
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Deactivate Employee?'),
                      content: Text('Are you sure you want to revoke access for $name?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Deactivate', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final res = await ApiClient().delete('${ApiConstants.employees}/${emp['id']}');
                    if (!mounted) return;
                    if (res.success) {
                      _fetchEmployees();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Employee deactivated.')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                const PopupMenuItem(value: 'delete', child: Text('Deactivate Staff', style: TextStyle(color: AppColors.danger))),
              ],
            ),
        ],
      ),
    );
  }
}
