import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/local_store.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  // Business controllers
  final _nameCtrl = TextEditingController();
  final _tradeNameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  // Settings controllers
  final _invoicePrefixCtrl = TextEditingController(text: 'INV-');
  final _purchasePrefixCtrl = TextEditingController(text: 'PUR-');
  final _termsCtrl = TextEditingController();
  double _defaultTaxRate = 18.0;
  bool _enableEInvoicing = true;
  bool _enableEWayBill = false;
  String _attribution = ApiConstants.copyrightAttribution;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.businessSettings);
    if (!mounted) return;

    if (res.success && res.data is Map) {
      final biz = res.data['business'] as Map<String, dynamic>? ?? {};
      final settings = res.data['settings'] as Map<String, dynamic>? ?? {};
      _attribution = res.data['attribution'] ?? ApiConstants.copyrightAttribution;

      _nameCtrl.text = biz['name'] ?? '';
      _tradeNameCtrl.text = biz['trade_name'] ?? '';
      _gstinCtrl.text = biz['gstin'] ?? '';
      _phoneCtrl.text = biz['phone'] ?? '';
      _emailCtrl.text = biz['email'] ?? '';
      _addressCtrl.text = biz['address'] ?? '';
      _cityCtrl.text = biz['city'] ?? '';
      _stateCtrl.text = biz['state'] ?? 'Maharashtra';
      _pincodeCtrl.text = biz['pincode'] ?? '';

      _invoicePrefixCtrl.text = settings['invoice_prefix'] ?? 'INV-';
      _purchasePrefixCtrl.text = settings['purchase_prefix'] ?? 'PUR-';
      _termsCtrl.text = settings['terms_and_conditions'] ?? '';
      _defaultTaxRate = (settings['default_tax_rate'] as num?)?.toDouble() ?? 18.0;
      _enableEInvoicing = settings['enable_e_invoicing'] ?? true;
      _enableEWayBill = settings['enable_e_way_bill'] ?? false;

      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load business settings';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'business': {
        'name': _nameCtrl.text.trim(),
        'trade_name': _tradeNameCtrl.text.trim(),
        'gstin': _gstinCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      },
      'settings': {
        'invoice_prefix': _invoicePrefixCtrl.text.trim(),
        'purchase_prefix': _purchasePrefixCtrl.text.trim(),
        'default_tax_rate': _defaultTaxRate,
        'terms_and_conditions': _termsCtrl.text.trim(),
        'enable_e_invoicing': _enableEInvoicing,
        'enable_e_way_bill': _enableEWayBill,
      }
    };

    final res = await ApiClient().put(ApiConstants.businessSettings, body: payload);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business settings saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to update settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Business Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSettings,
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchSettings)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section 1: Business Identity
                      _buildCard(
                        title: 'IDENTITY & PROFILE',
                        icon: Icons.badge_outlined,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Business Legal Name (As per GST) *'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tradeNameCtrl,
                            decoration: const InputDecoration(labelText: 'Trade / Display Name'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(labelText: 'WhatsApp / Phone *'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(labelText: 'Billing Email *'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Address
                      _buildCard(
                        title: 'REGISTERED BUSINESS ADDRESS',
                        icon: Icons.location_on_outlined,
                        children: [
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(labelText: 'Premises / Industrial Unit Address'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(labelText: 'City'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateCtrl,
                                  decoration: const InputDecoration(labelText: 'State'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _pincodeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'PIN Code'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 3: GST & Taxation
                      _buildCard(
                        title: 'GST & TAX CONFIGURATION',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          TextFormField(
                            controller: _gstinCtrl,
                            decoration: const InputDecoration(
                              labelText: '15-Digit GSTIN *',
                              hintText: '27AABCU9603R1ZM',
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<double>(
                                  value: _defaultTaxRate,
                                  decoration: const InputDecoration(labelText: 'Default Tax Rate'),
                                  items: const [
                                    DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                                    DropdownMenuItem(value: 5.0, child: Text('5% (Raw Supply)')),
                                    DropdownMenuItem(value: 12.0, child: Text('12% (Industrial Goods)')),
                                    DropdownMenuItem(value: 18.0, child: Text('18% (Standard)')),
                                    DropdownMenuItem(value: 28.0, child: Text('28% (Automotive/Machinery)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _defaultTaxRate = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable E-Invoicing (IRN generation)', style: TextStyle(fontSize: 13)),
                            value: _enableEInvoicing,
                            onChanged: (val) => setState(() => _enableEInvoicing = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable E-Way Bill generation', style: TextStyle(fontSize: 13)),
                            value: _enableEWayBill,
                            onChanged: (val) => setState(() => _enableEWayBill = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Operational Prefixes & Terms
                      _buildCard(
                        title: 'INVOICING PREFERENCES & TERMS',
                        icon: Icons.tune,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _invoicePrefixCtrl,
                                  decoration: const InputDecoration(labelText: 'Invoice Prefix (e.g. INV-)'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _purchasePrefixCtrl,
                                  decoration: const InputDecoration(labelText: 'Purchase Prefix (e.g. PUR-)'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _termsCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Default Terms & Conditions',
                              hintText: '1. Goods once sold will not be taken back.\n2. Interest @ 18% p.a. on delayed payments.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      AppButton(
                        label: 'Save Changes',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveSettings,
                      ),
                      const SizedBox(height: 24),

                      // Local Storage & Backup Management Card
                      _buildCard(
                        title: 'LOCAL PERSISTENCE & DATA BACKUP',
                        icon: Icons.storage_outlined,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '100% Database-Free & Local-First (Atomic JSON Storage)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All business records, products, invoices, and accounting data are stored securely on this device without requiring a database server or internet connection.',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.file_download_outlined, size: 18),
                                  label: const Text('Export Backup (JSON)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                  ),
                                  onPressed: () {
                                    final jsonStr = LocalStore().exportJsonString();
                                    Clipboard.setData(ClipboardData(text: jsonStr));
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Backup Exported Successfully'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Full portable business dataset has been generated and copied to your clipboard!'),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Size: ${(jsonStr.length / 1024).toStringAsFixed(1)} KB\nRecords: Invoices, Products, Customers, Ledgers, Settings',
                                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                                  label: const Text('Restore Backup'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                  ),
                                  onPressed: () {
                                    final restoreCtrl = TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Restore Backup JSON'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Paste your exported BharatLedger JSON backup text below:'),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: restoreCtrl,
                                              maxLines: 6,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                hintText: '{"version": "4.2.0-offline", ...}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                            onPressed: () async {
                                              final input = restoreCtrl.text.trim();
                                              if (input.isEmpty) return;
                                              final ok = await LocalStore().restoreFromJsonString(input);
                                              if (ctx.mounted) Navigator.pop(ctx);
                                              if (mounted) {
                                                if (ok) {
                                                  _fetchSettings();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Backup restored successfully!'), backgroundColor: AppColors.success),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Invalid backup JSON format'), backgroundColor: AppColors.danger),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('Restore'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Mandatory Attribution & Release Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primaryBlue),
                                SizedBox(width: 6),
                                Text(
                                  'BharatLedger Pro v4.8.2',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _attribution,
                              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'End-to-end 256-bit AES encrypted industrial ledger storage',
                              style: TextStyle(fontSize: 10, color: AppColors.secondaryText.withOpacity(0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
