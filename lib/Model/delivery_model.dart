class DeliveryOffer {
  final int    offerId;
  final int    deliveryId;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final double fee;
  final String deliveryType;
  final String expiresAt;

  const DeliveryOffer({
    required this.offerId,
    required this.deliveryId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.fee,
    required this.deliveryType,
    required this.expiresAt,
  });

  factory DeliveryOffer.fromJson(Map<String, dynamic> j) => DeliveryOffer(
    offerId:       int.tryParse(j['offer_id'].toString()) ?? 0,
    deliveryId:    int.tryParse(j['delivery_id'].toString()) ?? 0,
    pickupAddress: j['pickup_address'] ?? '',
    dropAddress:   j['drop_address'] ?? '',
    distanceKm:    double.tryParse(j['distance_km'].toString()) ?? 0,
    fee:           double.tryParse(j['fee'].toString()) ?? 0,
    deliveryType:  j['delivery_type'] ?? '',
    expiresAt:     j['expires_at'] ?? '',
  );
}

class ActiveDelivery {
  final int    id;
  final String state;
  final String deliveryType;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final double fee;
  final String? pickupLat;
  final String? pickupLng;
  final String? dropLat;
  final String? dropLng;

  const ActiveDelivery({
    required this.id,
    required this.state,
    required this.deliveryType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.fee,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
  });

  factory ActiveDelivery.fromJson(Map<String, dynamic> j) => ActiveDelivery(
    id:            int.tryParse(j['id'].toString()) ?? 0,
    state:         j['state'] ?? '',
    deliveryType:  j['delivery_type'] ?? '',
    pickupAddress: j['pickup_address'] ?? '',
    dropAddress:   j['drop_address'] ?? '',
    distanceKm:    double.tryParse(j['distance_km'].toString()) ?? 0,
    fee:           double.tryParse(j['fee'].toString()) ?? 0,
    pickupLat:     j['pickup_lat']?.toString(),
    pickupLng:     j['pickup_lng']?.toString(),
    dropLat:       j['drop_lat']?.toString(),
    dropLng:       j['drop_lng']?.toString(),
  );
}

class DeliveryHistoryItem {
  final int    id;
  final String state;
  final String deliveryType;
  final String pickupAddress;
  final String dropAddress;
  final double fee;
  final String createdAt;

  const DeliveryHistoryItem({
    required this.id,
    required this.state,
    required this.deliveryType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fee,
    required this.createdAt,
  });

  factory DeliveryHistoryItem.fromJson(Map<String, dynamic> j) => DeliveryHistoryItem(
    id:            int.tryParse(j['id'].toString()) ?? 0,
    state:         j['state'] ?? '',
    deliveryType:  j['delivery_type'] ?? '',
    pickupAddress: j['pickup_address'] ?? '',
    dropAddress:   j['drop_address'] ?? '',
    fee:           double.tryParse(j['fee'].toString()) ?? 0,
    createdAt:     j['created_at'] ?? '',
  );
}
