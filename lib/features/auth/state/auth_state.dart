import '../data/auth_models.dart';

class RegistrationDraft {
  final String fullName;
  final int? age;
  final String mobile;
  final String village;
  final String taluk;
  final String district;
  final String? language;

  const RegistrationDraft({
    this.fullName = '',
    this.age,
    this.mobile = '',
    this.village = '',
    this.taluk = '',
    this.district = '',
    this.language,
  });

  RegistrationDraft copyWith({
    String? fullName,
    int? age,
    String? mobile,
    String? village,
    String? taluk,
    String? district,
    String? language,
  }) {
    return RegistrationDraft(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      mobile: mobile ?? this.mobile,
      village: village ?? this.village,
      taluk: taluk ?? this.taluk,
      district: district ?? this.district,
      language: language ?? this.language,
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isOtpSent;
  final bool isNewUser;
  final String? pendingMobile;
  final RegistrationDraft? pendingRegistration;
  final UserProfile? currentUser;
  final OrgSummary? activeOrg;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isOtpSent = false,
    this.isNewUser = false,
    this.pendingMobile,
    this.pendingRegistration,
    this.currentUser,
    this.activeOrg,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isOtpSent,
    bool? isNewUser,
    String? pendingMobile,
    RegistrationDraft? pendingRegistration,
    bool clearPendingRegistration = false,
    UserProfile? currentUser,
    OrgSummary? activeOrg,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isNewUser: isNewUser ?? this.isNewUser,
      pendingMobile: pendingMobile ?? this.pendingMobile,
      pendingRegistration: clearPendingRegistration
          ? null
          : (pendingRegistration ?? this.pendingRegistration),
      currentUser: currentUser ?? this.currentUser,
      activeOrg: activeOrg ?? this.activeOrg,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
