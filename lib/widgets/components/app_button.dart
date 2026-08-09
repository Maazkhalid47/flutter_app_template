import 'package:flutter/material.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_sizes/app_sizes.dart';
import '../../constant/app_text_styles/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightLg,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.textOnPrimary,
          ),
        )
            : Text(label, style: AppTextStyles.buttonText),
      ),
    );
  }
}