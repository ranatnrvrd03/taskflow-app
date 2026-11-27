import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class Session {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static String? token;
  static AppUser? user;
  static VoidCallback? onLoggedOut;

  static bool get isLoggedIn => token != null && user != null;
  static bool get isCeo => user?.isCeo ?? false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    try {
      user = rawUser == null ? null : AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    } catch (_) {
      user = null;
    }
    if (token == null || user == null) {
      token = null;
      user = null;
    }
  }

  static Future<void> save(String newToken, AppUser newUser) async {
    token = newToken;
    user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_userKey, jsonEncode(newUser.toJson()));
  }

  static Future<void> logout() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    onLoggedOut?.call();
  }
}