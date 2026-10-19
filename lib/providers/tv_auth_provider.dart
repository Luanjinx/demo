import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tv_login_model.dart';
import '../utils/constant.dart';
import '../webservice/api_service.dart';

class TVAuthProvider extends ChangeNotifier {
  final TVApiService _api = TVApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  TVUserData? _currentUser;
  TVUserData? get currentUser => _currentUser;

  // TV Code Login State
  String? _tvCode;
  String? get tvCode => _tvCode;

  Timer? _pollTimer;
  bool _isPolling = false;
  bool get isPolling => _isPolling;

  TVAuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();

    // Device ID
    String? storedDeviceId = prefs.getString(Constant.keyDeviceId);
    if (storedDeviceId == null || storedDeviceId.isEmpty) {
      final seed = "tv_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}";
      storedDeviceId = sha256.convert(utf8.encode(seed)).toString();
      await prefs.setString(Constant.keyDeviceId, storedDeviceId);
    }
    Constant.deviceId = storedDeviceId;

    // User session
    final storedUserId = prefs.getString(Constant.keyUserId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      _isLoggedIn = true;
      Constant.userId = storedUserId;
      Constant.userName = prefs.getString(Constant.keyUserName);
      Constant.userEmail = prefs.getString(Constant.keyUserEmail);
      Constant.userImage = prefs.getString(Constant.keyUserImage);
      Constant.isUserLogin = true;
      _currentUser = TVUserData(
        id: int.tryParse(storedUserId),
        name: Constant.userName,
        email: Constant.userEmail,
        image: Constant.userImage,
      );
    }
    notifyListeners();
  }

  // Generate 4-digit TV Code and start polling
  Future<void> requestTVCode() async {
    _isLoading = true;
    _tvCode = null;
    notifyListeners();

    stopPolling();

    final result = await _api.getTvLoginCode();
    if (result.status == 200 && result.result != null && result.result!.isNotEmpty) {
      _tvCode = result.result![0].uniqueCode;
      _startPolling();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _startPolling() {
    if (_tvCode == null || _tvCode!.isEmpty) return;
    _isPolling = true;

    // Poll every 3 seconds for up to 5 minutes (100 ticks)
    int ticks = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      ticks++;
      if (ticks > 100) {
        stopPolling();
        return;
      }

      final userData = await _api.checkTvLogin(uniqueCode: _tvCode!);
      if (userData != null && userData.id != null) {
        stopPolling();
        await _saveUserSession(userData);
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  Future<void> _saveUserSession(TVUserData user) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = user;
    _isLoggedIn = true;
    Constant.userId = user.id.toString();
    Constant.userName = user.name;
    Constant.userEmail = user.email;
    Constant.userImage = user.image;
    Constant.isUserLogin = true;

    await prefs.setString(Constant.keyUserId, user.id.toString());
    if (user.name != null) await prefs.setString(Constant.keyUserName, user.name!);
    if (user.email != null) await prefs.setString(Constant.keyUserEmail, user.email!);
    if (user.image != null) await prefs.setString(Constant.keyUserImage, user.image!);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constant.keyUserId);
    await prefs.remove(Constant.keyUserName);
    await prefs.remove(Constant.keyUserEmail);
    await prefs.remove(Constant.keyUserImage);

    _isLoggedIn = false;
    _currentUser = null;
    Constant.userId = null;
    Constant.userName = null;
    Constant.userEmail = null;
    Constant.userImage = null;
    Constant.isUserLogin = false;

    stopPolling();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
