import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phone;
  const OtpVerificationScreen({super.key, this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

typedef OtpScreen = OtpVerificationScreen;

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final TextEditingController _phoneController;
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone?.isNotEmpty == true ? widget.phone : "+91 98230 12345");
    _otpControllers[0].text = "1";
    _otpControllers[1].text = "2";
    _otpControllers[2].text = "3";
    _otpControllers[3].text = "4";
  }

  void _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    final phone = _phoneController.text.trim();

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter complete 4-digit OTP')));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    final success = await auth.verifyOtp(phone, otp);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Verified Successfully!'), backgroundColor: AppColors.success));
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Invalid OTP'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.actionBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined, color: AppColors.actionBlue, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter Security Code',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a 4-digit verification code to your registered mobile number.',
                style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _phoneController.text,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                ),
              ),
              const SizedBox(height: 32),

              // 4 digit inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 3) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              AppButton(
                text: 'Verify & Access Terminal',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification code resent to your phone: 1234')),
                      );
                    },
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.actionBlue),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                ApiConstants.copyright,
                style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
