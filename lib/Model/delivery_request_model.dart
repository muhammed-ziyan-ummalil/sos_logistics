import 'delivery_quote_model.dart';

class DeliveryRequestModel {
  final int id;
  final String requestType;
  final String sourceType;
  final int sourceId;
  final String requesterType;
  final int requesterId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final double distanceKm;
  final int estimatedDurationMin;
  final String status;
  final String expiresAt;
  final int? acceptedQuoteId;
  final int? deliveryId;
  final List<DeliveryQuoteModel> quotes;

  DeliveryRequestModel({
    required this.id,
    required this.requestType,
    required this.sourceType,
    required this.sourceId,
    required this.requesterType,
    required this.requesterId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.status,
    required this.expiresAt,
    this.acceptedQuoteId,
    this.deliveryId,
    this.quotes = const [],
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestModel(
      id: int.tryParse('${json['id']}') ?? 0,
      requestType: json['request_type'] ?? '',
      sourceType: json['source_type'] ?? '',
      sourceId: int.tryParse('${json['source_id']}') ?? 0,
      requesterType: json['requester_type'] ?? '',
      requesterId: int.tryParse('${json['requester_id']}') ?? 0,
      pickupAddress: json['pickup_address'] ?? '',
      pickupLat: double.tryParse('${json['pickup_lat']}') ?? 0,
      pickupLng: double.tryParse('${json['pickup_lng']}') ?? 0,
      dropAddress: json['drop_address'] ?? '',
      dropLat: double.tryParse('${json['drop_lat']}') ?? 0,
      dropLng: double.tryParse('${json['drop_lng']}') ?? 0,
      distanceKm: double.tryParse('${json['distance_km']}') ?? 0,
      estimatedDurationMin: int.tryParse('${json['estimated_duration_min']}') ?? 0,
      status: json['status'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      acceptedQuoteId: int.tryParse('${json['accepted_quote_id']}'),
      deliveryId: int.tryParse('${json['delivery_id']}'),
      quotes: (json['quotes'] as List?)
              ?.map((q) => DeliveryQuoteModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
