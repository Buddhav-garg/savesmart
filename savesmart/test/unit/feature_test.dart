import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/features/deposits/data/deposit_math.dart';
import 'package:savesmart/features/goals/data/goal_math.dart';

void main() {
  group('F1 Goals', () {
    test('required monthly saving changes when the target changes', () {
      final first = requiredMonthlySavingPaise(
        targetPaise: 1500000,
        savedPaise: 500000,
        targetDate: DateTime(2027, 1),
        today: DateTime(2026, 9),
      );
      final higherTarget = requiredMonthlySavingPaise(
        targetPaise: 2000000,
        savedPaise: 500000,
        targetDate: DateTime(2027, 1),
        today: DateTime(2026, 9),
      );

      expect(first, 250000);
      expect(higherTarget, 375000);
    });

    test('required monthly saving changes when the date changes', () {
      final earlierDate = requiredMonthlySavingPaise(
        targetPaise: 1500000,
        savedPaise: 500000,
        targetDate: DateTime(2026, 11),
        today: DateTime(2026, 9),
      );
      final laterDate = requiredMonthlySavingPaise(
        targetPaise: 1500000,
        savedPaise: 500000,
        targetDate: DateTime(2027, 1),
        today: DateTime(2026, 9),
      );

      expect(earlierDate, 500000);
      expect(laterDate, 250000);
    });

    test('a completed goal requires no additional monthly saving', () {
      expect(
        requiredMonthlySavingPaise(
          targetPaise: 100000,
          savedPaise: 100000,
          targetDate: DateTime(2026, 12),
          today: DateTime(2026, 9),
        ),
        0,
      );
    });
  });

  group('F4 FD calculator', () {
    test('uses quarterly compounding', () {
      // ₹10,000 at 8% for one year: P × (1 + r/4)^4.
      expect(DepositMath.fdMaturity(1000000, 8, 365), 1082432);
    });

    test('senior rate adds 0.5 percentage points', () {
      expect(
        DepositMath.fdMaturity(1000000, 8, 365, isSenior: true),
        DepositMath.fdMaturity(1000000, 8.5, 365),
      );
      expect(
        DepositMath.fdMaturity(1000000, 8, 365, isSenior: true),
        greaterThan(DepositMath.fdMaturity(1000000, 8, 365)),
      );
    });
  });
}
