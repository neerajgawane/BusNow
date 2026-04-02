import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user;

  Future<bool> login(String phone, String password) async {
    final data = await ApiClient.login(phone, password);
    if (data['token'] != null) {
      token = data['token'];
      user = data['user'];
      ApiClient.setToken(token!);
      ApiClient.initSocket();
      notifyListeners();
      return true;
    }
    return false;
  }

  String get role => user?['role'] ?? '';
  int get busId => user?['bus_id'] ?? 0;
  bool get isConductor => role == 'conductor';
}
