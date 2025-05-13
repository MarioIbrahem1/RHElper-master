import 'package:flutter/material.dart';
import 'package:road_helperr/utils/app_colors.dart'; // تأكد أن المسار صحيح

class EditTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;

  const EditTextField({
    super.key,
    required this.label,
    required this.icon,
    this.iconSize = 20,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        style: TextStyle(
          color: isLight ? AppColors.getLabelTextField(context) : Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color:
                isLight ? AppColors.getLabelTextField(context) : Colors.white,
          ),
          prefixIcon: Icon(
            icon,
            size: iconSize,
            color:
                isLight ? AppColors.getLabelTextField(context) : Colors.white,
          ),
          filled: true,
          fillColor: isLight ? Colors.grey[200] : const Color(0xFF022C5A),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: isLight ? Colors.grey : Colors.transparent,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
