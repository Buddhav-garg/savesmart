import 'package:flutter/material.dart';

class DaysToMaturityBar extends StatelessWidget {
  const DaysToMaturityBar({required this.days, super.key});
  final int days;

  @override
  Widget build(BuildContext context) {
    final progress = (days / 3650).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 5),
        Text(
          days == 0 ? 'Matures today' : '$days days to maturity',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
