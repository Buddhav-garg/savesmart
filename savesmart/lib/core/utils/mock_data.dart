class MockGoal {
  const MockGoal({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.saved,
    required this.target,
    required this.due,
    required this.targetDate,
  });

  final String id;
  final String name;
  final String iconKey;
  final int saved;
  final int target;
  final String due;
  final DateTime targetDate;

  double get progress => saved / target;
}

class MockDeposit {
  const MockDeposit({
    required this.name,
    required this.kind,
    required this.amountPaise,
    required this.installmentPaise,
    required this.rate,
    required this.maturity,
  });

  final String name;
  final String kind;
  final int amountPaise;
  final int installmentPaise;
  final String rate;
  final String maturity;
}

final mockGoals = <MockGoal>[
  MockGoal(
    id: 'travel',
    name: 'Japan trip',
    iconKey: 'travel',
    saved: 8450000,
    target: 15000000,
    due: 'Oct 2025',
    targetDate: DateTime(2025, 10, 31),
  ),
  MockGoal(
    id: 'home',
    name: 'New home',
    iconKey: 'home',
    saved: 32000000,
    target: 50000000,
    due: 'Mar 2026',
    targetDate: DateTime(2026, 3, 31),
  ),
  MockGoal(
    id: 'emergency',
    name: 'Safety net',
    iconKey: 'safety',
    saved: 9500000,
    target: 20000000,
    due: 'Dec 2025',
    targetDate: DateTime(2025, 12, 31),
  ),
];

const mockDeposits = <MockDeposit>[
  MockDeposit(
    name: 'Smart FD · 12 months',
    kind: 'FIXED DEPOSIT',
    amountPaise: 10000000,
    installmentPaise: 0,
    rate: '7.25% p.a.',
    maturity: 'Matures 18 Jun 2026',
  ),
  MockDeposit(
    name: 'Monthly RD · 24 months',
    kind: 'RECURRING DEPOSIT',
    amountPaise: 12000000,
    installmentPaise: 500000,
    rate: '7.00% p.a.',
    maturity: 'Matures 04 Jan 2027',
  ),
];
