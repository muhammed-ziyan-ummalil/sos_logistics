class EarningsData {
  final double         totalEarnings;
  final List<DailyEarning> daily;

  const EarningsData({required this.totalEarnings, required this.daily});

  factory EarningsData.fromJson(Map<String, dynamic> j) => EarningsData(
    totalEarnings: double.tryParse(j['total_earnings'].toString()) ?? 0,
    daily: ((j['daily'] ?? []) as List)
        .map((e) => DailyEarning.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class DailyEarning {
  final String date;
  final double netEarnings;
  final int    deliveries;

  const DailyEarning({
    required this.date,
    required this.netEarnings,
    required this.deliveries,
  });

  factory DailyEarning.fromJson(Map<String, dynamic> j) => DailyEarning(
    date:         j['date'] ?? '',
    netEarnings:  double.tryParse(j['net_earnings'].toString()) ?? 0,
    deliveries:   int.tryParse(j['deliveries'].toString()) ?? 0,
  );
}
