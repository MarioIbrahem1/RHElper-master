import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final double iconSize;
  final double fontSize;
  final Function(bool) onToggle;

  const ServiceCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.iconSize,
    required this.fontSize,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isSelected),
      child: Card(
        color: isSelected ? Colors.blue : Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: fontSize)),
          ],
        ),
      ),
    );
  }
}
