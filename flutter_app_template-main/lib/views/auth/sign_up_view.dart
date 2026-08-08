import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/responsive_layout.dart';
import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../helpers/feedback_helper.dart';
import '../../mixins/form_validation_mixin.dart';
import '../../validators/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Registration screen.
///
/// Same shape as [LoginView], with one extra rule worth copying: the confirm
/// field is validated against the password field's *current* value, so the
/// check stays correct while the user edits either one.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with FormValidationMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateForm()) return;
    context.unfocus();

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    if (!mounted) return;
    final exception = viewModel.exception;
    if (!success && exception != null) {
      FeedbackHelper.showError(context, exception, onRetry: _submit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: context.pop)),
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
                    Text(
                      context.l10n.authSignUpTitle,
                      style: context.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: UiConstants.spaceXl),
                    AppTextField(
                      controller: _nameController,
                      label: context.l10n.appName,
                      prefixIcon: Icons.person_outline,
                      enabled: !viewModel.isBusy,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: UiConstants.spaceMd),
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
                      isNewPassword: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: UiConstants.spaceMd),
                    AppTextField.password(
                      controller: _confirmController,
                      label: context.l10n.authPasswordLabel,
                      obscureText: viewModel.obscurePassword,
                      onToggleObscure: viewModel.togglePasswordVisibility,
                      validator: fieldValidator(
                        (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      enabled: !viewModel.isBusy,
                      isNewPassword: true,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: UiConstants.spaceLg),
                    AppButton(
                      label: context.l10n.authSignUpButton,
                      isLoading: viewModel.isBusy,
                      onPressed: _submit,
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
