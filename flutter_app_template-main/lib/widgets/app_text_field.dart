import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's text input.
///
/// Beyond consistent styling, it sets the small things that are easy to forget
/// and hurt real users: the right keyboard type, autofill hints (so password
/// managers work), correct capitalisation, and a password visibility toggle
/// that is actually reachable.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.onToggleObscure,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  /// Email input, pre-configured. The named constructors exist so a screen
  /// cannot forget the keyboard type or the autofill hint.
  factory AppTextField.email({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool enabled = true,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    key: key,
    controller: controller,
    label: label,
    validator: validator,
    enabled: enabled,
    focusNode: focusNode,
    keyboardType: TextInputType.emailAddress,
    prefixIcon: Icons.alternate_email,
    autofillHints: const [AutofillHints.email],
  );

  /// Password input with a working visibility toggle.
  factory AppTextField.password({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
    bool enabled = true,
    bool isNewPassword = false,
    TextInputAction textInputAction = TextInputAction.done,
    void Function(String)? onSubmitted,
    Key? key,
  }) => AppTextField(
    key: key,
    controller: controller,
    label: label,
    validator: validator,
    enabled: enabled,
    obscureText: obscureText,
    onToggleObscure: onToggleObscure,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    prefixIcon: Icons.lock_outline,
    autofillHints: [
      isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
  );

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      // An obscured field must stay on one line; Flutter asserts otherwise.
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textCapitalization: keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: _buildSuffix(context),
        // Hide the character counter unless a limit was actually set.
        counterText: maxLength == null ? '' : null,
      ),
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    if (onToggleObscure != null) {
      return IconButton(
        onPressed: onToggleObscure,
        icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        tooltip: obscureText ? 'Show password' : 'Hide password',
      );
    }
    return suffix;
  }
}
