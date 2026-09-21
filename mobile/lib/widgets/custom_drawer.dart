import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.actionBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.precision_manufacturing, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.business?.name ?? 'BharatLedger Industrial',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.actionBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                auth.user?.role ?? 'Admin',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                auth.branch?.name ?? 'Head Office',
                                style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildDynamicMenuItems(context, auth, isDark),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: AppColors.danger, size: 20),
                    title: Text(
                      'Log Out',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger),
                    ),
                    dense: true,
                    onTap: () {
                      auth.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ApiConstants.copyright,
                    style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${ApiConstants.appTitle} ${ApiConstants.version}',
                    style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppColors.actionBlue : null,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.actionBlue : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.actionBlue.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (currentRoute != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }

  List<Widget> _buildDynamicMenuItems(BuildContext context, AuthProvider auth, bool isDark) {
    final sections = [
      const _DrawerSectionDef('CORE BILLING', [
        _DrawerItemDef(Icons.dashboard_outlined, '6. Business Dashboard', '/dashboard', 'dashboard.view'),
        _DrawerItemDef(Icons.point_of_sale_outlined, '7. Billing / POS', '/billing', 'billing.view'),
        _DrawerItemDef(Icons.receipt_long_outlined, '11. Invoice Management', '/invoices', 'invoices.view'),
        _DrawerItemDef(Icons.people_outline, '13. Customers Management', '/customers', 'customers.view'),
      ]),
      const _DrawerSectionDef('PRODUCTS & INVENTORY', [
        _DrawerItemDef(Icons.inventory_2_outlined, '15. Inventory & Products', '/inventory', 'products.view'),
        _DrawerItemDef(Icons.warehouse_outlined, '18. Stock Management', '/stock', 'inventory.adjust'),
        _DrawerItemDef(Icons.history_outlined, '19. Stock History', '/stock-history', 'stock.history'),
      ]),
      const _DrawerSectionDef('PURCHASES & SUPPLIERS', [
        _DrawerItemDef(Icons.shopping_bag_outlined, '20. Purchase List', '/purchases', 'purchases.view'),
        _DrawerItemDef(Icons.add_shopping_cart_outlined, '22. New Purchase', '/new-purchase', 'purchases.create'),
        _DrawerItemDef(Icons.local_shipping_outlined, '23. Suppliers List', '/suppliers', 'suppliers.view'),
      ]),
      const _DrawerSectionDef('ACCOUNTING & RETURNS', [
        _DrawerItemDef(Icons.payments_outlined, '25. Payments & Receivables', '/payments', 'payments.view'),
        _DrawerItemDef(Icons.account_balance_wallet_outlined, '26. Expenses Management', '/expenses', 'expenses.view'),
        _DrawerItemDef(Icons.assignment_return_outlined, '27. Sales Returns', '/sales-returns', 'returns.sales'),
        _DrawerItemDef(Icons.keyboard_return_outlined, '28. Purchase Returns', '/purchase-returns', 'returns.purchases'),
        _DrawerItemDef(Icons.note_alt_outlined, '29. Credit / Debit Notes', '/credit-debit-notes', 'credit_debit.view'),
        _DrawerItemDef(Icons.menu_book_outlined, '30. Customer Ledger', '/customer-ledger', 'ledger.customer'),
      ]),
      const _DrawerSectionDef('REPORTS & ANALYTICS', [
        _DrawerItemDef(Icons.analytics_outlined, '31. Reports Dashboard', '/reports', 'reports.view'),
        _DrawerItemDef(Icons.bar_chart_outlined, '32. Sales Analytics', '/sales-analytics', 'reports.sales'),
        _DrawerItemDef(Icons.trending_up_outlined, '33. Profit & Loss', '/profit-loss', 'reports.profit_loss'),
        _DrawerItemDef(Icons.account_balance_outlined, '34. GST / Tax Reports', '/gst-reports', 'reports.gst'),
        _DrawerItemDef(Icons.pie_chart_outline, '35. Inventory Reports', '/inventory-reports', 'reports.inventory'),
      ]),
      const _DrawerSectionDef('ADMINISTRATION', [
        _DrawerItemDef(Icons.badge_outlined, '36. Employees & Roles', '/employees', 'employees.view'),
        _DrawerItemDef(Icons.store_outlined, '37. Branch Management', '/branches', 'branches.view'),
        _DrawerItemDef(Icons.notifications_none_outlined, '38. Notifications Center', '/notifications', 'notifications.view'),
        _DrawerItemDef(Icons.settings_outlined, '39. Business Settings', '/business-settings', 'settings.view'),
        _DrawerItemDef(Icons.print_outlined, '40. Printer Settings', '/printer-settings', 'billing.view'),
      ]),
    ];

    List<Widget> widgets = [];
    for (final sec in sections) {
      final visible = sec.items.where((it) => auth.hasPermission(it.permission)).toList();
      if (visible.isNotEmpty) {
        widgets.add(_sectionHeader(sec.title, isDark));
        for (final it in visible) {
          widgets.add(_drawerItem(context, it.icon, it.title, it.route));
        }
      }
    }
    return widgets;
  }
}

class _DrawerItemDef {
  final IconData icon;
  final String title;
  final String route;
  final String permission;

  const _DrawerItemDef(this.icon, this.title, this.route, this.permission);
}

class _DrawerSectionDef {
  final String title;
  final List<_DrawerItemDef> items;

  const _DrawerSectionDef(this.title, this.items);
}

