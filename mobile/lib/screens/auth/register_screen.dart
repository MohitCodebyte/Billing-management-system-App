import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

typedef RegisterScreen = BusinessRegistrationScreen;

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gstinController = TextEditingController();

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.registerBusiness(
      name: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      gstin: _gstinController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/business-setup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Business'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start with BharatLedger',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set up your enterprise billing, inventory tracking, and GST reporting profile.',
                  style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                _label('Company / Business Legal Name *'),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Apex Industrial Supplies Pvt Ltd',
                    prefixIcon: Icon(Icons.business, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
                ),
                const SizedBox(height: 16),

                _label('Proprietor / Managing Director Name *'),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
                ),
                const SizedBox(height: 16),

                _label('Mobile Number *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),

                _label('Work Email *'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'admin@company.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 16),

                _label('Master Account Password *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 chars' : null,
                ),
                const SizedBox(height: 16),

                _label('GSTIN (Optional)'),
                TextFormField(
                  controller: _gstinController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: '27AAACB2234L1Z2',
                    prefixIcon: Icon(Icons.receipt_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: 'Continue to Setup',
                  onPressed: _handleRegister,
                  isLoading: auth.isLoading,
                  icon: Icons.arrow_forward,
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
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
