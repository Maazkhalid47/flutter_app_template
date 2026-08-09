import 'package:flutter/material.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_sizes/app_sizes.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppSizes.inputHeight,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              errorText: errorText,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppPadding.inputHorizontal,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.input,
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
