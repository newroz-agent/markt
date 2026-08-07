import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A consistent form field configured entirely through the app theme.
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enabled = true,
    this.readOnly = false,
    this.expands = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.contentPadding,
    this.semanticLabel,
    super.key,
  }) : assert(controller == null || initialValue == null),
       assert(!expands || (minLines == null && maxLines == null));

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enabled;
  final bool readOnly;
  final bool expands;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final EdgeInsetsGeometry? contentPadding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: contentPadding,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      enabled: enabled,
      readOnly: readOnly,
      expands: expands,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
    );

    if (semanticLabel == null) return field;
    return Semantics(textField: true, label: semanticLabel, child: field);
  }
}
