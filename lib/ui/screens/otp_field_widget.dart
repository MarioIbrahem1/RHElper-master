import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_helperr/utils/app_colors.dart'; // أضف هذا
import 'package:road_helperr/utils/responsive_helper.dart';

class OtpFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode currentFocus;
  final FocusNode? nextFocus;
  final Function({required String value, required FocusNode focusNode})
      nextField;
  final bool autofocus;

  const OtpFieldWidget({
    super.key,
    required this.controller,
    required this.currentFocus,
    required this.nextFocus,
    required this.nextField,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ResponsiveHelper.init(context);
        final isLight = Theme.of(context).brightness == Brightness.light;

        // ديناميك
        final Color fillColor =
            isLight ? Colors.white : AppColors.getCardColor(context);
        final Color borderColor = AppColors.getOtpFieldColor(context);
        final Color cursorColor = AppColors.getOtpFieldColor(context);

        return Container(
          alignment: Alignment.topCenter,
          margin: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveWidth(5)),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(ResponsiveHelper.getResponsiveWidth(2)),
            color: fillColor,
            boxShadow: [
              BoxShadow(
                color:
                    isLight ? Colors.black.withOpacity(0.05) : Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          width: ResponsiveHelper.getResponsiveWidth(100),
          height: ResponsiveHelper.getResponsiveHeight(50),
          child: TextFormField(
            focusNode: currentFocus,
            autofocus: autofocus,
            maxLines: 1,
            maxLength: 1,
            controller: controller,
            keyboardType: TextInputType.number,
            cursorColor: cursorColor,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black : Colors.white,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            onChanged: _handleOnChanged,
            decoration: InputDecoration(
              counterText: '',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveWidth(2)),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveWidth(2)),
                borderSide: BorderSide(
                  color: borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(2),
              ),
              fillColor: fillColor,
              filled: true,
            ),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.top,
          ),
        );
      },
    );
  }

  void _handleOnChanged(String value) {
    if (value.isNotEmpty) {
      nextField(value: value, focusNode: currentFocus);
      if (nextFocus != null) {
        nextFocus?.requestFocus();
      }
    }
  }
}
