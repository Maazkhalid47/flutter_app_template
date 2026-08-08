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

/// Password reset request screen.
///
/// The success message is deliberately vague ("if that address exists, we sent
/// a link"): confirming whether an email is registered turns this form into an
/// account-enumeration tool.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView>
    with FormValidationMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateForm()) return;
    context.unfocus();

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.sendPasswordReset(_emailController.text);

    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
      FeedbackHelper.showSuccess(context, context.l10n.commonOk);
      return;
    }
    final exception = viewModel.exception;
    if (exception != null) FeedbackHelper.showError(context, exception);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.authPasswordLabel,
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: UiConstants.spaceLg),
                  AppTextField.email(
                    controller: _emailController,
                    label: context.l10n.authEmailLabel,
                    validator: fieldValidator(Validators.email),
                    enabled: !viewModel.isBusy && !_sent,
                  ),
                  const SizedBox(height: UiConstants.spaceLg),
                  AppButton(
                    label: context.l10n.commonOk,
                    isLoading: viewModel.isBusy,
                    isEnabled: !_sent,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
