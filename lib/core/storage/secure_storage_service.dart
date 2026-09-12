import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _orgIdKey = 'org_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      debugPrint('SecureStorage write failed, falling back to SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final val = await _storage.read(key: _accessTokenKey);
      if (val != null) return val;
    } catch (e) {
      debugPrint('SecureStorage read failed, falling back to SharedPreferences: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    try {
      final val = await _storage.read(key: _refreshTokenKey);
      if (val != null) return val;
    } catch (e) {
      debugPrint('SecureStorage read failed, falling back to SharedPreferences: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveOrgContext({required String userId, required String orgId}) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _orgIdKey, value: orgId);
    } catch (e) {
      debugPrint('SecureStorage saveOrgContext failed, falling back to SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_orgIdKey, orgId);
    }
  }

  Future<String?> getUserId() async {
    try {
      final val = await _storage.read(key: _userIdKey);
      if (val != null) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getOrgId() async {
    try {
      final val = await _storage.read(key: _orgIdKey);
      if (val != null) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgIdKey);
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_orgIdKey);
  }
}

