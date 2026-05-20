import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    );
  }
}
