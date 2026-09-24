class Nominee {
  const Nominee({
    required this.id,
    required this.name,
    required this.relation,
    required this.sharePct,
  });

  final String id;
  final String name;
  final String relation;
  final double sharePct;

  factory Nominee.fromJson(Map<String, dynamic> json) => Nominee(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    relation: json['relation']?.toString() ?? '',
    sharePct: (json['sharePct'] as num).toDouble(),
  );
}
