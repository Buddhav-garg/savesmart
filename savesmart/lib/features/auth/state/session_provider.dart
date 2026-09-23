import 'package:flutter/foundation.dart';

import '../../../core/utils/mock_data.dart';

class AppSession extends ChangeNotifier {
  AppSession._() : _goals = List<MockGoal>.from(mockGoals);

  static final AppSession instance = AppSession._();

  final List<MockGoal> _goals;

  List<MockGoal> get goals => List.unmodifiable(_goals);

  void addGoal(MockGoal goal) {
    _goals.add(goal);
    notifyListeners();
  }
}
