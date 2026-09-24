import 'dart:math' as math;

class DepositMath {
  const DepositMath._();

  static int fdMaturity(
    int principalPaise,
    double ratePct,
    int tenureDays, {
    bool isSenior = false,
  }) {
    final effectiveRate = ratePct + (isSenior ? 0.5 : 0);
    final years = tenureDays / 365;
    const periods = 4;
    return (principalPaise *
            math.pow(1 + effectiveRate / periods / 100, periods * years))
        .round();
  }

  static double effectiveYieldPct({
    required int principalPaise,
    required int maturityPaise,
    required int tenureDays,
  }) {
    if (principalPaise <= 0 || maturityPaise <= 0 || tenureDays <= 0) return 0;
    return (math.pow(maturityPaise / principalPaise, 365 / tenureDays) - 1) *
        100;
  }
}
