import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enableObscureToggle = false,
    this.enabled,
    this.readOnly = false,
    this.focusNode,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onTap,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enableObscureToggle;
  final bool? enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final String? helperText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = widget.enabled ?? !widget.readOnly;

    Widget? suffix;
    if (widget.enableObscureToggle) {
      suffix = IconButton(
        onPressed: widget.readOnly
            ? null
            : () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      );
    } else {
      suffix = widget.suffixIcon;
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    );

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      obscureText: widget.enableObscureToggle ? _obscure : widget.obscureText,
      enabled: effectiveEnabled,
      readOnly: widget.readOnly,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onTap: widget.onTap,
      decoration: InputDecoration(
        hintText: widget.hint ?? widget.label,
        helperText: widget.helperText ?? ' ',
        helperStyle: widget.helperText != null
            ? null
            : const TextStyle(height: 1.2, color: Colors.transparent),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: widget.prefixIcon,
        prefixIconColor: AppColors.primary,
        suffixIcon: suffix,
        enabledBorder: border,
        disabledBorder: border,
        border: border,
        focusedBorder: focusedBorder,
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: focusedBorder.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.4),
        ),
        errorStyle: const TextStyle(height: 1.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
