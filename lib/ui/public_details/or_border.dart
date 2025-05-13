import 'package:flutter/material.dart';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrBorder extends StatelessWidget {
  const OrBorder({super.key});

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    final borderColor = AppColors.getBorderField(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                height: 2,
                thickness: 2,
                indent: 90,
                endIndent: 13,
                color: borderColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                lang.or,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF407BFF)
                      : Colors.white,
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                height: 2,
                thickness: 2,
                indent: 13,
                endIndent: 90,
                color: borderColor,
              ),
            ),
          ],
        ),
        // تم إزالة أزرار وسائل التواصل الاجتماعي
      ],
    );
  }
}
