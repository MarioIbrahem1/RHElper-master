import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  final IconData icon;
  final String hintText;
  final String label;
  final bool isPassword;
  final String? Function(String?)? validatorIsContinue;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final FocusNode focusNode;

  const InputField({
    super.key,
    required this.icon,
    required this.hintText,
    required this.label,
    this.isPassword = false,
    this.validatorIsContinue,
    this.keyboardType = TextInputType.text,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white54 : Colors.black54;
    final borderColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.98,
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword ? _isObscure : false,
          validator: widget.validatorIsContinue,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
            prefixIcon: Icon(widget.icon, color: textColor),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                : null,
            hintText: widget.hintText,
            labelText: widget.label,
            labelStyle: TextStyle(color: textColor),
            hintStyle: TextStyle(color: hintColor),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: borderColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}