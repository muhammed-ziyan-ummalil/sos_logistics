abstract class OwnerKycState {}

class OwnerKycInitial extends OwnerKycState {}

class OwnerKycLoading extends OwnerKycState {}

/// status: none | pending | approved | rejected  (persons.kyc_status)
class OwnerKycLoaded extends OwnerKycState {
  final String status;
  final String? kycMessage;
  final Map<String, dynamic>? document; // null = nothing submitted yet
  OwnerKycLoaded({required this.status, this.kycMessage, this.document});
}

class OwnerKycSubmitting extends OwnerKycState {}

class OwnerKycSubmitSuccess extends OwnerKycState {
  final String message;
  OwnerKycSubmitSuccess(this.message);
}

class OwnerKycError extends OwnerKycState {
  final String message;
  OwnerKycError(this.message);
}
