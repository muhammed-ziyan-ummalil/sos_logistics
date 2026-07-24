import '../../../core/app_constants.dart';

/// Human derivation of the per-kg fee so the total is not mystifying:
/// "250 kg x (Rs 100/kg base + Rs 50/kg-km x 6.84 km) = Rs 110,500".
/// The rates are PER KG/LITRE and already multiplied by the order weight -
/// the old "Base Rs 25,000 + extra km Rs 85,500" read like flat trip charges.
/// Falls back to the flat wording when the breakdown carries no weight.
String feeDerivationText(Map<String, dynamic> fee) {
  final cs = AppConstants.currencySymbol;
  final total = double.tryParse('${fee['total_fee'] ?? 0}') ?? 0;
  final base = double.tryParse('${fee['base_fee'] ?? 0}') ?? 0;
  final extra = double.tryParse('${fee['extra_km_charge'] ?? 0}') ?? 0;
  final weight = double.tryParse('${fee['weight_kg'] ?? 1}') ?? 1;
  final minPerKg = double.tryParse('${fee['min_fee_per_kg'] ?? 0}') ?? 0;
  final perKm = double.tryParse('${fee['per_km_fee'] ?? 0}') ?? 0;
  final extraKm = double.tryParse('${fee['extra_km'] ?? 0}') ?? 0;

  if (weight > 1 && minPerKg > 0) {
    final extraPart = extraKm > 0
        ? ' + $cs${_trim(perKm)}/kg-km x ${extraKm.toStringAsFixed(2)} km'
        : '';
    return '${_trim(weight)} kg x ($cs${_trim(minPerKg)}/kg base$extraPart) '
        '= $cs${total.toStringAsFixed(0)}';
  }
  return 'Base $cs${base.toStringAsFixed(0)}'
      '${extra > 0 ? ' + extra km $cs${extra.toStringAsFixed(0)}' : ''}';
}

String _trim(double v) =>
    v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
