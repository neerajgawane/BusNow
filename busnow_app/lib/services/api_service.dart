import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<Map<String, dynamic>?> login(String phone, String password, String role) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password, 'role': role}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        globalToken = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', globalToken!);
        await prefs.setString('role', role);
        return data['user'];
      }
    } catch (e) { print(e); }
    return null;
  }

  static Future<bool> register(String name, String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
      );
      return res.statusCode == 201;
    } catch (e) { print(e); }
    return false;
  }

  static Future<List<dynamic>> getIncomingBuses(int stopId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stops/$stopId/buses'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) { print(e); }
    return [];
  }
}
