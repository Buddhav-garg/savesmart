import 'package:flutter_test/flutter_test.dart';

import 'package:savesmart/features/goals/data/goal_math.dart';

void main() {
  test('calculates the remaining monthly saving in paise', () {
    final monthly = requiredMonthlySavingPaise(
      targetPaise: 1500000,
      savedPaise: 500000,
      targetDate: DateTime(2026, 7, 1),
      today: DateTime(2026, 3, 1),
    );

    expect(monthly, 250000);
  });

  test('returns zero when the goal is already complete', () {
    expect(
      requiredMonthlySavingPaise(
        targetPaise: 100000,
        savedPaise: 100000,
        targetDate: DateTime(2026, 7, 1),
        today: DateTime(2026, 3, 1),
      ),
      0,
    );
  });
}
