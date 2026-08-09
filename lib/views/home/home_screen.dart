import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';
import '../../repository/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/components/app_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text('You\'re In', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user?.email ?? user?.name ?? 'Signed in',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              AppButton(
                label: 'Sign Out',
                onPressed: () async {
                  await AuthRepository.instance.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
