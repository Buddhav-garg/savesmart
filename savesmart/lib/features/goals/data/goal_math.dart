int requiredMonthlySavingPaise({
  required int targetPaise,
  required int savedPaise,
  required DateTime targetDate,
  DateTime? today,
}) {
  final remainingPaise = targetPaise - savedPaise;
  if (remainingPaise <= 0) return 0;

  final start = today ?? DateTime.now();
  final months =
      (targetDate.year - start.year) * 12 + targetDate.month - start.month;
  final safeMonths = months <= 0 ? 1 : months;
  return (remainingPaise / safeMonths).ceil();
}
