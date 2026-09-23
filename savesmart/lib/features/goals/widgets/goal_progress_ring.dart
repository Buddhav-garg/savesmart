import 'package:flutter/material.dart';

class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({required this.progress, this.size = 72, super.key});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.clamp(0, 1) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 7,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
          ),
          Text('$percentage%', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
