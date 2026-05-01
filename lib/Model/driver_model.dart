class DriverProfile {
  final int    id;
  final String name;
  final String phone;
  final String kycStatus;
  final String status;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.kycStatus,
    required this.status,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
    id:        int.tryParse(j['id'].toString()) ?? 0,
    name:      j['name'] ?? '',
    phone:     j['phone'] ?? '',
    kycStatus: j['kyc_status'] ?? 'pending',
    status:    j['status'] ?? 'inactive',
  );

  bool get isVerified => kycStatus == 'verified';
  bool get isActive   => status == 'active';
}

class AvailabilityStatus {
  final String status;
  const AvailabilityStatus(this.status);
  bool get isOnline => status == 'online';
}
