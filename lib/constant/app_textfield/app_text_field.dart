import 'package:flutter/material.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        // Local Theme override so cursor / text-selection highlight / selection
        // handles all use green instead of inheriting the app's root theme
        // primary color (that's what was showing blue on tap).
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondary,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppColors.secondary,
              selectionColor: AppColors.secondary.withValues(alpha: 0.25),
              selectionHandleColor: AppColors.secondary,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            enabled: enabled,
            onChanged: onChanged,
            validator: validator,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.secondary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.white,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.secondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.gray300),
              ),
            ),
          ),
        ),
      ],
    );
  }
}