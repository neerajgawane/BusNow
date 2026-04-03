import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (globalToken != null && globalToken!.isNotEmpty)
          'Authorization': 'Bearer $globalToken',
      };

  /// Login — returns user map or null on failure
  static Future<Map<String, dynamic>?> login(
      String phone, String password, String role) async {
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
    } catch (e) {
      print('Login error: $e');
    }
    return null;
  }

  /// Register
  static Future<bool> register(
      String name, String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      print('Register error: $e');
    }
    return false;
  }

  /// Get incoming buses for a stop
  static Future<List<dynamic>> getIncomingBuses(int stopId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/stops/$stopId/buses'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('getIncomingBuses error: $e');
    }
    return [];
  }

  /// Update crowd level (conductor) — PATCH /api/buses/:id/crowd
  static Future<Map<String, dynamic>?> updateCrowd(
      int busId, String crowdLevel, double lat, double lng) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/buses/$busId/crowd'),
        headers: _headers,
        body: jsonEncode({'crowd_level': crowdLevel, 'lat': lat, 'lng': lng}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('updateCrowd error: $e');
    }
    return null;
  }

  /// Get conductor stats
  static Future<Map<String, dynamic>?> getConductorStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/conductor/stats'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('getConductorStats error: $e');
    }
    return null;
  }

  /// Get bus location
  static Future<Map<String, dynamic>?> getBusLocation(int busId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/buses/$busId/location'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('getBusLocation error: $e');
    }
    return null;
  }

  /// Get route stops
  static Future<List<dynamic>> getRouteStops(int routeId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/routes/$routeId/stops'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('getRouteStops error: $e');
    }
    return [];
  }
}
