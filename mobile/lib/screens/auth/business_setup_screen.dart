import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../widgets/common_widgets.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _addressController = TextEditingController(text: "Plot 44, MIDC Phase II");
  final _cityController = TextEditingController(text: "Pune");
  final _stateController = TextEditingController(text: "Maharashtra");
  final _prefixController = TextEditingController(text: "INV-");
  double _taxRate = 18.0;
  bool _enableEInvoice = false;
  bool _isLoading = false;

  void _saveSetup() async {
    setState(() => _isLoading = true);

    await ApiClient().put(ApiConstants.businessSettings, body: {
      'business': {
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      },
      'settings': {
        'invoice_prefix': _prefixController.text.trim(),
        'default_tax_rate': _taxRate,
        'enable_e_invoicing': _enableEInvoice,
      }
    });

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business Profile Configured!'), backgroundColor: AppColors.success),
    );
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure Invoicing Profile',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure billing preferences, default state of supply, and invoice sequencing.',
                style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              Text('Business Street Address', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Shop / Unit number, Industrial area',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('City', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(hintText: 'City'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('State', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(hintText: 'State'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Invoice Series Prefix', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _prefixController,
                decoration: const InputDecoration(
                  hintText: 'e.g. INV- or BL/',
                  prefixIcon: Icon(Icons.tag, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              Text('Default GST Tax Bracket', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                  final isSelected = _taxRate == rate;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text('${rate.toInt()}%'),
                        selected: isSelected,
                        selectedColor: AppColors.actionBlue,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _taxRate = rate);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Enable E-Invoicing & E-Way Bill Integration', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Direct portal JSON generation compliant with NIC standards', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                value: _enableEInvoice,
                activeColor: AppColors.actionBlue,
                onChanged: (val) => setState(() => _enableEInvoice = val),
              ),
              const SizedBox(height: 32),

              AppButton(
                text: 'Complete Setup & Open POS',
                onPressed: _saveSetup,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  ApiConstants.copyright,
                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
