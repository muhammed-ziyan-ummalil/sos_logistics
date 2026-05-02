abstract class OwnerBankDetailsState {}

class OwnerBankDetailsInitial extends OwnerBankDetailsState {}

class OwnerBankDetailsLoading extends OwnerBankDetailsState {}

class OwnerBankDetailsLoaded extends OwnerBankDetailsState {
  final Map<String, dynamic> details;
  OwnerBankDetailsLoaded(this.details);
}

class OwnerBankDetailsEmpty extends OwnerBankDetailsState {}

class OwnerBankDetailsError extends OwnerBankDetailsState {
  final String message;
  OwnerBankDetailsError(this.message);
}

class OwnerBankDetailsSaving extends OwnerBankDetailsState {}

class OwnerBankDetailsSaved extends OwnerBankDetailsState {}

class OwnerBankDetailsSaveError extends OwnerBankDetailsState {
  final String message;
  OwnerBankDetailsSaveError(this.message);
}
