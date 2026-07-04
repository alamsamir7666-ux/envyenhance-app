import 'package:flutter/material.dart';

/// Small pill-shaped label used for sale %, stock state, "new", etc.
/// Solid-fill variant reads as urgent (sale, sold out); soft variant
/// reads as informational (category tag, benefit chip).
class AppBadge extends StatelessWidget {
  const AppBadge.solid({
    required this.text,
    required Color this.color,
    this.textColor = Colors.white,
    super.key,
  }) : soft = false;

  const AppBadge.soft({
    required this.text,
    required Color this.color,
    required this.textColor,
    super.key,
  }) : soft = true;

  final String text;
  final Color color;
  final Color textColor;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.14) : color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: soft ? color : textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
