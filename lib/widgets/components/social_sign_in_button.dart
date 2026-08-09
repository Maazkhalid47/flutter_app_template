import 'package:flutter/material.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_sizes/app_sizes.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';

class SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightLg,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
