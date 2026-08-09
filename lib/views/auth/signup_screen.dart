import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_radius/app_radius.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/components/app_button.dart';
import '../../widgets/components/app_text_field.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  // split into first/last name to match the design
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // business logic untouched — same signUpWithEmail / signInWithGoogle / signInWithApple calls
  Future<void> _handleResult(bool success) async {
    if (success && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- "Already have an account? Log in" (top right) ----
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- heading ----
              Text(
                'Welcome to Momflex',
                style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Create your account to start your journey towards stability and support. "
                    "Together, we'll find the right assistance for you and your family.",
                textAlign: TextAlign.justify,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ---- fields ----
              AppTextField(
                label: 'First Name*',
                hint: 'Cena',
                controller: _firstNameController,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Last Name*',
                hint: 'John',
                controller: _lastNameController,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'E-mail*',
                hint: 'Cena@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password*',
                hint: 'Create a password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  viewModel.errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ---- terms text ----
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'By continuing you agree to Momflex '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ---- continue button (same signUpWithEmail call, name = first + last) ----
              AppButton(
                label: 'Continue',
                isLoading: viewModel.isLoading,
                onPressed: () async {
                  final fullName =
                  '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                      .trim();
                  final success = await viewModel.signUpWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                    fullName: fullName,
                  );
                  await _handleResult(success);
                },
              ),

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Or',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- social icons (Google / Facebook / Apple) ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIconButton(
                    icon: Icons.g_mobiledata_rounded,
                    iconColor: const Color(0xFFEA4335),
                    onTap: viewModel.isLoading
                        ? null
                        : () async {
                      final success = await viewModel.signInWithGoogle();
                      await _handleResult(success);
                    },
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _SocialIconButton(
                    icon: Icons.facebook_rounded,
                    iconColor: const Color(0xFF1877F2),
                    // no signInWithFacebook in AuthViewModel yet — wire this up
                    // once that method exists, same pattern as Google/Apple above.
                    onTap: null,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _SocialIconButton(
                    icon: Icons.apple_rounded,
                    iconColor: AppColors.black,
                    onTap: viewModel.isLoading
                        ? null
                        : () async {
                      final success = await viewModel.signInWithApple();
                      await _handleResult(success);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SocialIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 26, color: iconColor),
      ),
    );
  }
}