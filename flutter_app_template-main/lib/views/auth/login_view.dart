import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/responsive_layout.dart';
import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../helpers/feedback_helper.dart';
import '../../mixins/form_validation_mixin.dart';
import '../../routes/app_routes.dart';
import '../../validators/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Sign-in screen.
///
/// The reference implementation for every form in the app. Note what it does
/// *not* do: no network calls, no token handling, no navigation-on-success.
/// It collects input, asks [AuthViewModel] to sign in, and lets `RouteGuard`
/// handle where the user goes next.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with FormValidationMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateForm()) return;
    context.unfocus();

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // The widget can be gone by the time the request returns.
    if (!mounted) return;
    final exception = viewModel.exception;
    if (!success && exception != null) {
      FeedbackHelper.showError(context, exception, onRetry: _submit);
    }
  }

  @override
  Widget build(BuildContext context) {
    // `watch` rebuilds this screen when the busy flag or visibility toggle
    // changes; the submit handler uses `read` because it needs no rebuild.
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ContentContainer(
            maxWidth: 480,
            child: Form(
              key: formKey,
              autovalidateMode: autovalidateMode,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: UiConstants.spaceXxl),
                    Text(
                      context.l10n.authLoginTitle,
                      style: context.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: UiConstants.spaceXl),
                    AppTextField.email(
                      controller: _emailController,
                      label: context.l10n.authEmailLabel,
                      validator: fieldValidator(Validators.email),
                      enabled: !viewModel.isBusy,
                    ),
                    const SizedBox(height: UiConstants.spaceMd),
                    AppTextField.password(
                      controller: _passwordController,
                      label: context.l10n.authPasswordLabel,
                      obscureText: viewModel.obscurePassword,
                      onToggleObscure: viewModel.togglePasswordVisibility,
                      validator: fieldValidator(Validators.password),
                      enabled: !viewModel.isBusy,
                      onSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton.text(
                        label: '${context.l10n.authPasswordLabel}?',
                        onPressed: () =>
                            context.pushNamed(AppRoutes.forgotPasswordName),
                      ),
                    ),
                    const SizedBox(height: UiConstants.spaceMd),
                    AppButton(
                      label: context.l10n.authLoginButton,
                      isLoading: viewModel.isBusy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: UiConstants.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.authNoAccount,
                          style: context.textTheme.bodyMedium,
                        ),
                        AppButton.text(
                          label: context.l10n.authSignUpButton,
                          onPressed: viewModel.isBusy
                              ? null
                              : () => context.pushNamed(AppRoutes.signUpName),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
