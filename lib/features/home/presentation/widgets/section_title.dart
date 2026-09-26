import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.outlinedAction = false,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool outlinedAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (actionText != null)
          if (outlinedAction)
            OutlinedButton(
              onPressed: onActionTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3694F4),
                side: const BorderSide(color: Color(0xFF3694F4)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(actionText!, style: const TextStyle(fontSize: 13)),
            )
          else
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4F8FC5)),
              ),
            ),
      ],
    );
  }
}
