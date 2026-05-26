class DeliveryQuoteModel {
  final int id;
  final int requestId;
  final int ownerId;
  final int vehicleId;
  final int? driverId;
  final double distanceKm;
  final double baseFee;
  final double perKmFee;
  final double extraKm;
  final double extraKmCharge;
  final double totalFee;
  final String status;
  final String? ownerName;
  final String? registrationNumber;
  final String? vehicleType;
  final String? driverName;

  DeliveryQuoteModel({
    required this.id,
    required this.requestId,
    required this.ownerId,
    required this.vehicleId,
    this.driverId,
    required this.distanceKm,
    required this.baseFee,
    required this.perKmFee,
    required this.extraKm,
    required this.extraKmCharge,
    required this.totalFee,
    required this.status,
    this.ownerName,
    this.registrationNumber,
    this.vehicleType,
    this.driverName,
  });

  factory DeliveryQuoteModel.fromJson(Map<String, dynamic> json) {
    return DeliveryQuoteModel(
      id: json['id'] ?? 0,
      requestId: json['request_id'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      driverId: json['driver_id'],
      distanceKm: double.tryParse('${json['distance_km']}') ?? 0,
      baseFee: double.tryParse('${json['base_fee']}') ?? 0,
      perKmFee: double.tryParse('${json['per_km_fee']}') ?? 0,
      extraKm: double.tryParse('${json['extra_km']}') ?? 0,
      extraKmCharge: double.tryParse('${json['extra_km_charge']}') ?? 0,
      totalFee: double.tryParse('${json['total_fee']}') ?? 0,
      status: json['status'] ?? '',
      ownerName: json['owner_name'],
      registrationNumber: json['registration_number'],
      vehicleType: json['vehicle_type'],
      driverName: json['driver_name'],
    );
  }
}
