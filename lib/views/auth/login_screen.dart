import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:momflex/views/auth/forgot_password_sheet.dart';
import 'package:provider/provider.dart';

import '../../constant/app_color/app_colors.dart';
import '../../constant/app_spacing/app_spacing.dart';
import '../../constant/app_text_styles/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/components/app_button.dart';
import '../../widgets/components/app_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              // ---- "Don't have an account? Sign Up" (top right) ----
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.signup),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
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
                'Welcome Back',
                style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to continue your journey towards stability and support.',
                textAlign: TextAlign.justify,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ---- fields ----
              AppTextField(
                label: 'E-mail*',
                hint: 'Cena@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Password*',
                hint: 'Enter your password',
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

              // ---- Forgot password ----
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => showForgotPasswordSheet(context),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

              // ---- log in button (same signInWithEmail call) ----
              AppButton(
                label: 'Log In',
                isLoading: viewModel.isLoading,
                onPressed: () async {
                  final success = await viewModel.signInWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
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
              // Wrap instead of Row: never overflows, even on narrow screens —
              // if it ever doesn't fit on one line, it wraps to the next
              // instead of throwing a RenderFlex overflow error.
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _SocialIconButton(
                      asset: 'assets/images/google.png',
                      onTap: viewModel.isLoading
                          ? null
                          : () async {
                        final success = await viewModel.signInWithGoogle();
                        await _handleResult(success);
                      },
                    ),
                    _SocialIconButton(
                      asset: 'assets/images/facebook.png',
                      // no signInWithFacebook in AuthViewModel yet — wire this up
                      // once that method exists, same pattern as Google/Apple above.
                      onTap: null,
                    ),
                    _SocialIconButton(
                      asset: 'assets/images/apple.jpeg',
                      onTap: viewModel.isLoading
                          ? null
                          : () async {
                        final success = await viewModel.signInWithApple();
                        await _handleResult(success);
                      },
                    ),
                  ],
                ),
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
  final String asset;
  final VoidCallback? onTap;

  const _SocialIconButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}