import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mock_data.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';
import '../../deposits/data/deposit_repository.dart';
import '../../deposits/domain/deposit.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/data/auto_save_repository.dart';
import '../../goals/domain/auto_save_rule.dart';

class AppSession extends ChangeNotifier {
  AppSession._()
    : _goals = List<MockGoal>.from(mockGoals),
      _deposits = List<MockDeposit>.from(mockDeposits),
      _client = ApiClient() {
    _authRepository = AuthRepository(_client);
    _goalRepository = GoalRepository(_client);
    _depositRepository = DepositRepository(_client);
    _autoSaveRepository = AutoSaveRepository(_client);
  }

  static final AppSession instance = AppSession._();

  final List<MockGoal> _goals;
  final List<MockDeposit> _deposits;
  final Map<String, List<AutoSaveRule>> _rulesByGoal = {};
  final ApiClient _client;
  late final AuthRepository _authRepository;
  late final GoalRepository _goalRepository;
  late final DepositRepository _depositRepository;
  late final AutoSaveRepository _autoSaveRepository;
  UserSession? _userSession;
  bool _isLoading = false;

  List<MockGoal> get goals => List.unmodifiable(_goals);
  List<MockDeposit> get deposits => List.unmodifiable(_deposits);
  List<AutoSaveRule> rulesForGoal(String goalId) =>
      List.unmodifiable(_rulesByGoal[goalId] ?? const []);
  UserProfile? get user => _userSession?.user;
  bool get isAuthenticated => _userSession != null;
  bool get isLoading => _isLoading;

  Future<void> login({required String phone, required String pin}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final session = await _authRepository.login(phone: phone, pin: pin);
      _userSession = session;
      _client.setToken(session.token);
      final apiGoals = await _goalRepository.listGoals();
      _goals
        ..clear()
        ..addAll(apiGoals.map(_toMockGoal));
      final apiDeposits = await _depositRepository.listDeposits();
      _deposits
        ..clear()
        ..addAll(apiDeposits.map(_toMockDeposit));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGoal({
    required String name,
    required String icon,
    required int targetPaise,
    required DateTime targetDate,
  }) async {
    final goal = await _goalRepository.createGoal(
      name: name,
      icon: icon,
      targetPaise: targetPaise,
      targetDate: targetDate,
    );
    _goals.add(_toMockGoal(goal));
    notifyListeners();
  }

  Future<MockGoal> contributeToGoal({
    required String goalId,
    required int amountPaise,
    required String idempotencyKey,
  }) async {
    final goal = await _goalRepository.contribute(
      goalId: goalId,
      amountPaise: amountPaise,
      idempotencyKey: idempotencyKey,
    );
    final updated = _toMockGoal(goal);
    final index = _goals.indexWhere((item) => item.id == goalId);
    if (index == -1) {
      _goals.add(updated);
    } else {
      _goals[index] = updated;
    }
    notifyListeners();
    return updated;
  }

  Future<Deposit> bookDeposit({
    required String kind,
    required int tenureDays,
    int? principalPaise,
    int? installmentPaise,
    int? debitDate,
    String payout = 'on_maturity',
    String renewal = 'none',
    String? nomineeName,
    String? nomineeRelation,
    int? nomineeSharePct,
    required String idempotencyKey,
  }) async {
    final deposit = await _depositRepository.book(
      kind: kind,
      tenureDays: tenureDays,
      principalPaise: principalPaise,
      installmentPaise: installmentPaise,
      debitDate: debitDate,
      payout: payout,
      renewal: renewal,
      nomineeName: nomineeName,
      nomineeRelation: nomineeRelation,
      nomineeSharePct: nomineeSharePct,
      idempotencyKey: idempotencyKey,
    );
    _deposits.add(_toMockDeposit(deposit));
    notifyListeners();
    return deposit;
  }

  Future<List<AutoSaveRule>> createAutoSaveRule({
    required String goalId,
    required String type,
    int? amountPaise,
    double? percent,
    String? schedule,
  }) async {
    final rules = await _autoSaveRepository.createRule(
      goalId: goalId,
      type: type,
      amountPaise: amountPaise,
      percent: percent,
      schedule: schedule,
    );
    _rulesByGoal[goalId] = rules;
    notifyListeners();
    return rules;
  }

  Future<AutoSaveRule> toggleAutoSaveRule({
    required String goalId,
    required AutoSaveRule rule,
  }) async {
    final updated = await _autoSaveRepository.setPaused(
      goalId: goalId,
      ruleId: rule.id,
      paused: !rule.paused,
    );
    final rules = [...rulesForGoal(goalId)];
    final index = rules.indexWhere((item) => item.id == rule.id);
    if (index >= 0) rules[index] = updated;
    _rulesByGoal[goalId] = rules;
    notifyListeners();
    return updated;
  }

  void addGoal(MockGoal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  MockGoal _toMockGoal(dynamic goal) => MockGoal(
    id: goal.id as String,
    name: goal.name as String,
    iconKey: goal.icon as String,
    saved: goal.savedPaise as int,
    target: goal.targetPaise as int,
    due:
        '${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
    targetDate: goal.targetDate as DateTime,
  );

  MockDeposit _toMockDeposit(Deposit deposit) => MockDeposit(
    name: '${deposit.kind} · ${deposit.daysToMaturity} days',
    kind: deposit.kind == 'FD' ? 'FIXED DEPOSIT' : 'RECURRING DEPOSIT',
    amountPaise: deposit.principalPaise,
    installmentPaise: deposit.installmentPaise ?? 0,
    rate: '${deposit.ratePct.toStringAsFixed(2)}% p.a.',
    maturity:
        'Matures ${deposit.maturityDate.day}/${deposit.maturityDate.month}/${deposit.maturityDate.year}',
  );
}
