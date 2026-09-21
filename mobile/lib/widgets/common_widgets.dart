import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class AppButton extends StatelessWidget {
  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isOutlined;
  final bool isDestructive;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    this.text,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isOutlined = false,
    this.isDestructive = false,
    this.icon,
    this.height = 52.0,
  });

  String get buttonText => text ?? label ?? '';
  bool get outline => isSecondary || isOutlined;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.actionBlue;
    Color fg = Colors.white;
    BorderSide border = BorderSide.none;

    if (outline) {
      bg = Colors.transparent;
      fg = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
      border = BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border, width: 1.5);
    } else if (isDestructive) {
      bg = AppColors.dangerBg;
      fg = AppColors.danger;
      border = const BorderSide(color: Color(0xFFFCA5A5), width: 1);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (label) {
      case 'PAID':
      case 'SUCCESSFUL':
      case 'IN_STOCK':
      case 'ACTIVE':
        bg = AppColors.successBg;
        fg = const Color(0xFF047857);
        break;
      case 'PARTIAL':
      case 'PENDING':
      case 'LOW_STOCK':
        bg = AppColors.warningBg;
        fg = const Color(0xFFB45309);
        break;
      case 'OVERDUE':
      case 'OUT_OF_STOCK':
      case 'CANCELLED':
      case 'FAILED':
        bg = AppColors.dangerBg;
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final bool? isPositive;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.actionBlue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor ?? AppColors.actionBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GstSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double taxable;
  final double gst;
  final double roundOff;
  final double grandTotal;

  const GstSummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.taxable,
    required this.gst,
    required this.roundOff,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildRow('Taxable Value', AppFormatters.formatCurrency(taxable), isDark),
          const SizedBox(height: 8),
          _buildRow('CGST (9%)', AppFormatters.formatCurrency(gst / 2), isDark),
          const SizedBox(height: 8),
          _buildRow('SGST (9%)', AppFormatters.formatCurrency(gst / 2), isDark),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildRow('Discount Applied', '- ${AppFormatters.formatCurrency(discount)}', isDark, isGreen: true),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                AppFormatters.formatCurrency(grandTotal),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.actionBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.success : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class StickyBottomBar extends StatelessWidget {
  final String title;
  final String amount;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool isLoading;

  const StickyBottomBar({
    super.key,
    required this.title,
    required this.amount,
    required this.buttonText,
    required this.onButtonPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: AppButton(
              text: buttonText,
              onPressed: onButtonPressed,
              isLoading: isLoading,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }
}
