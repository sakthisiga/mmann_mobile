import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../farm/state/farm_notifier.dart';
import '../data/auth_api_service.dart';
import '../data/auth_models.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final storageService = ref.watch(secureStorageProvider);
  return AuthNotifier(apiService, storageService, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;
  final Ref _ref;

  AuthNotifier(this._apiService, this._storageService, this._ref)
      : super(const AuthState()) {
    checkAuthStatus();
  }

  void _applyUserLanguage(String? lang) {
    if (lang != null && lang.isNotEmpty) {
      final baseCode = lang.split('-')[0].toLowerCase();
      if (['ta', 'te', 'kn', 'ml', 'en'].contains(baseCode)) {
        _ref.read(localeProvider.notifier).setLocale(Locale(baseCode));
      }
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final cachedUser = await DatabaseService.getCachedUserProfile();
      if (cachedUser != null) {
        final profile = UserProfile(
          id: cachedUser['id'] as String,
          mobile: cachedUser['mobile'] as String,
          displayName: cachedUser['display_name'] as String?,
          stateCode: cachedUser['state_code'] as String?,
          language: cachedUser['language'] as String?,
          age: (cachedUser['age'] as num?)?.toInt(),
        );
        final org = OrgSummary(
          id: cachedUser['active_org_id'] as String? ?? '',
          name: '${profile.displayName ?? "Farmer"}\'s Farm Holding',
          category: 'personal_farm',
          stateCode: profile.stateCode ?? 'TN',
          role: cachedUser['role'] as String? ?? 'owner',
          village: cachedUser['village'] as String?,
          district: cachedUser['district'] as String?,
        );

        _applyUserLanguage(profile.language);

        state = state.copyWith(
          isAuthenticated: true,
          currentUser: profile,
          activeOrg: org,
        );
        _ref.read(farmNotifierProvider.notifier).loadFarms();
      } else {
        state = state.copyWith(isAuthenticated: true);
        _ref.read(farmNotifierProvider.notifier).loadFarms();
      }

      // Sync latest tenant and profile from server (e.g. village, district, age)
      _syncProfileFromServer();
    } else {
      await DatabaseService.clearAll();
      _ref.read(farmNotifierProvider.notifier).reset();
    }
  }

  Future<void> _syncProfileFromServer() async {
    try {
      final me = await _apiService.getMe();
      if (me['org'] != null) {
        final org = OrgSummary.fromJson(me['org'] as Map<String, dynamic>);
        state = state.copyWith(activeOrg: org);

        if (me['user'] != null) {
          final user = UserProfile.fromJson(me['user'] as Map<String, dynamic>);
          state = state.copyWith(currentUser: user);
          await DatabaseService.cacheUserProfile({
            'id': user.id,
            'mobile': user.mobile,
            'display_name': user.displayName,
            'state_code': user.stateCode,
            'language': user.language,
            'age': user.age,
            'active_org_id': org.id,
            'role': org.role,
            'village': org.village,
            'district': org.district,
          });
        }
      }
    } catch (_) {}
  }

  void setPendingRegistration(RegistrationDraft draft) {
    state = state.copyWith(
      pendingRegistration: draft,
      pendingMobile: draft.mobile,
    );
  }

  void clearPendingRegistration() {
    state = state.copyWith(clearPendingRegistration: true);
  }

  Future<bool> requestOtp(
    String mobile,
    String language, {
    RegistrationDraft? registration,
    bool? isRegistration,
  }) async {
    final effectiveIsReg = isRegistration ?? (registration != null && registration.fullName.isNotEmpty);
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      pendingRegistration: registration ?? state.pendingRegistration,
    );
    try {
      final success = await _apiService.requestOtp(
        mobile: mobile,
        language: language,
        isRegistration: effectiveIsReg,
      );
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isOtpSent: true,
          pendingMobile: mobile,
          pendingRegistration: registration ?? state.pendingRegistration,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to send OTP. Please check your mobile number.',
        );
        return false;
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail'] as String? ?? e.message)
          : e.message;
      state = state.copyWith(
        isLoading: false,
        errorMessage: detail ?? 'Connection error. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(
    String otp, {
    String? displayName,
    String? stateCode,
    String? language,
    int? age,
    String? village,
    String? taluk,
    String? district,
    bool? isRegistration,
  }) async {
    final mobile = state.pendingMobile ?? state.pendingRegistration?.mobile;
    if (mobile == null) {
      state = state.copyWith(errorMessage: 'Mobile number not found.');
      return false;
    }

    final reg = state.pendingRegistration;
    final effectiveIsReg = isRegistration ?? (reg != null && reg.fullName.isNotEmpty);
    final resolvedName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (reg?.fullName.isNotEmpty == true ? reg!.fullName : null);
    final resolvedAge = age ?? reg?.age;
    final resolvedVillage = (village != null && village.isNotEmpty)
        ? village
        : (reg?.village.isNotEmpty == true ? reg!.village : null);
    final resolvedTaluk = (taluk != null && taluk.isNotEmpty)
        ? taluk
        : (reg?.taluk.isNotEmpty == true ? reg!.taluk : null);
    final resolvedDistrict = (district != null && district.isNotEmpty)
        ? district
        : (reg?.district.isNotEmpty == true ? reg!.district : null);
    final resolvedLanguage = (language != null && language.isNotEmpty)
        ? language
        : ((reg != null && reg.language != null && reg.language!.isNotEmpty)
            ? reg.language
            : _ref.read(localeProvider).languageCode);

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.verifyOtp(
        mobile: mobile,
        otp: otp,
        displayName: resolvedName,
        stateCode: stateCode,
        language: resolvedLanguage,
        age: resolvedAge,
        village: resolvedVillage,
        taluk: resolvedTaluk,
        district: resolvedDistrict,
        isRegistration: effectiveIsReg,
      );

      // Purge prior user's offline database & in-memory farm state completely
      await DatabaseService.clearAll();
      _ref.read(farmNotifierProvider.notifier).reset();

      // Save tokens in encrypted secure storage
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      if (response.user != null && response.org != null) {
        await _storageService.saveOrgContext(
          userId: response.user!.id,
          orgId: response.org!.id,
        );

        // Cache in offline SQLite
        await DatabaseService.cacheUserProfile({
          'id': response.user!.id,
          'mobile': response.user!.mobile,
          'display_name': response.user!.displayName,
          'state_code': response.user!.stateCode,
          'language': response.user!.language,
          'age': response.user!.age,
          'active_org_id': response.org!.id,
          'role': response.org!.role,
          'village': response.org!.village ?? resolvedVillage,
          'district': response.org!.district ?? resolvedDistrict,
        });

        _applyUserLanguage(response.user!.language);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isNewUser: response.newUser,
        currentUser: response.user,
        activeOrg: response.org,
      );

      // Immediately fetch this new/active user's isolated farms
      _ref.read(farmNotifierProvider.notifier).loadFarms();

      return true;
    } on DioException catch (e) {
      final code = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['code'] as String? ?? '')
          : '';
      String message;
      if (code == 'otp_invalid') {
        message = 'Invalid OTP code. Please check and try again.';
      } else if (code == 'otp_expired') {
        message = 'OTP has expired. Please request a new code.';
      } else if (code == 'otp_attempts_exceeded') {
        message = 'Too many attempts. Locked for 15 minutes.';
      } else {
        message = e.response?.data is Map<String, dynamic>
            ? (e.response?.data['detail'] as String? ?? 'Verification failed.')
            : 'Verification failed. Please check the code.';
      }

      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e, stack) {
      // ignore: avoid_print
      print('VERIFY OTP EXCEPTION: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed: ${e.toString().split('\n').first}',
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    int? age,
    String? stateCode,
    String? language,
    String? district,
    String? taluk,
    String? village,
  }) async {
    try {
      final curUser = state.currentUser;
      final curOrg = state.activeOrg;

      final effectiveAge = age ?? curUser?.age;
      final effectiveState = stateCode ?? curOrg?.stateCode ?? curUser?.stateCode;
      final effectiveLang = language ?? curUser?.language ?? _ref.read(localeProvider).languageCode;
      final effectiveDistrict = district ?? curOrg?.district;
      final effectiveTaluk = taluk ?? curOrg?.taluk;
      final effectiveVillage = village ?? curOrg?.village;

      final res = await _apiService.updateProfile(
        displayName: displayName,
        age: effectiveAge,
        stateCode: effectiveState,
        language: effectiveLang,
        district: effectiveDistrict,
        taluk: effectiveTaluk,
        village: effectiveVillage,
      );

      UserProfile? updatedUser;
      OrgSummary? updatedOrg;

      if (res['user'] != null) {
        updatedUser = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
      }
      if (res['org'] != null) {
        updatedOrg = OrgSummary.fromJson(res['org'] as Map<String, dynamic>);
      }

      state = state.copyWith(
        currentUser: updatedUser ?? state.currentUser,
        activeOrg: updatedOrg ?? state.activeOrg,
      );

      final user = state.currentUser;
      final org = state.activeOrg;

      if (user != null && org != null) {
        await DatabaseService.cacheUserProfile({
          'id': user.id,
          'mobile': user.mobile,
          'display_name': user.displayName,
          'state_code': user.stateCode,
          'language': user.language,
          'age': user.age,
          'active_org_id': org.id,
          'role': org.role,
          'village': org.village,
          'district': org.district,
        });

        if (user.language != null) {
          _applyUserLanguage(user.language);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void completeOnboarding() {
    state = state.copyWith(isNewUser: false);
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    await DatabaseService.clearAll();
    _ref.read(farmNotifierProvider.notifier).reset();
    state = const AuthState();
  }
}
