import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/features/deposits/domain/withdrawal_quote.dart';
import 'package:savesmart/features/deposits/presentation/deposit_booking_screen.dart';
import 'package:savesmart/features/goals/domain/auto_save_rule.dart';
import 'package:savesmart/features/goals/widgets/milestone_celebration.dart';

void main() {
  group('F2 Add money to a goal', () {
    for (final milestone in [25, 50, 75, 100]) {
      testWidgets('shows the $milestone% milestone', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: MilestoneCelebration(milestone: milestone)),
        );

        expect(find.text('$milestone% milestone reached!'), findsOneWidget);
      });
    }

    testWidgets('respects reduce motion', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: MilestoneCelebration(milestone: 25)),
        ),
      );
      await tester.pump();

      final transition = tester.widget<ScaleTransition>(
        find.ancestor(
          of: find.text('25% milestone reached!'),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(transition.scale.value, 1);
    });
  });

  group('F3 Auto-save rules', () {
    test('paused rule retains its paused-since timestamp', () {
      final pausedAt = DateTime(2026, 9, 20);
      final rule = AutoSaveRule.fromJson({
        'id': 'rule-1',
        'goalId': 'goal-1',
        'type': 'round_up',
        'paused': true,
        'pausedSince': pausedAt.toIso8601String(),
      });

      expect(rule.paused, isTrue);
      expect(rule.pausedSince, pausedAt);
    });
  });

  group('F5 FD booking', () {
    testWidgets('rejects a principal below ₹1,000', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DepositBookingScreen(kind: 'FD')),
      );
      await tester.enterText(find.byType(TextField).first, '999');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review and confirm'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Review and confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('₹1,000'), findsOneWidget);
      expect(find.text('Review FD booking'), findsNothing);
    });
  });

  group('F6 RD booking', () {
    testWidgets('accepts debit date 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DepositBookingScreen(kind: 'RD')),
      );
      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.enterText(find.byType(TextField).at(2), '1');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review and confirm'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Review and confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Review RD booking'), findsOneWidget);
      expect(find.textContaining('RD debit date must'), findsNothing);
    });

    testWidgets('rejects debit dates outside 1–28', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DepositBookingScreen(kind: 'RD')),
      );
      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.enterText(find.byType(TextField).at(2), '29');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Review and confirm'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Review and confirm'));
      await tester.pumpAndSettle();

      expect(find.text('RD debit date must be between 1 and 28.'), findsOneWidget);
      expect(find.text('Review RD booking'), findsNothing);
    });
  });

  group('F8 Premature withdrawal quote', () {
    test('keeps the server supplied expiration timestamp', () {
      final expiry = DateTime(2026, 9, 24, 12);
      final quote = WithdrawalQuote.fromJson({
        'quoteId': 'quote-1',
        'depositId': 'deposit-1',
        'payablePaise': 100000,
        'penaltyPaise': 1000,
        'expiresAt': expiry.toIso8601String(),
      });

      expect(quote.expiresAt, expiry);
    });
  });
}
