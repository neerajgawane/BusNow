import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ApiClient {
  static const String baseUrl = 'http://10.0.12.41:3000';
  static IO.Socket? socket;
  static String? _token;

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        'role': 'passenger',
      }),
    );
    return jsonDecode(res.body);
  }

  // Conductor: Update crowd level
  static Future<void> updateCrowd(
    int busId,
    String crowdLevel,
    double lat,
    double lng,
  ) async {
    await http.patch(
      Uri.parse('$baseUrl/api/buses/$busId/crowd'),
      headers: _headers,
      body: jsonEncode({'crowd_level': crowdLevel, 'lat': lat, 'lng': lng}),
    );
  }

  // Passenger: Get incoming buses for stop
  static Future<List<dynamic>> getBusesForStop(int stopId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/stops/$stopId/buses'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  // Socket.io
  static void initSocket() {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
        'Authorization': 'Bearer $_token',
      }).build(),
    );
    socket!.connect();
  }

  static void subscribeToStop(int stopId) {
    socket?.emit('stop:subscribe', {'stop_id': stopId});
  }

  static void joinBusRoom(int busId) {
    socket?.emit('bus:join', {'bus_id': busId});
  }

  static void onBusCrowdUpdate(Function(dynamic) callback) {
    socket?.on('bus:crowd_update', callback);
  }

  static void dispose() => socket?.disconnect();
}
