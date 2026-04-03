import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static IO.Socket? _socket;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Connect with JWT token for authenticated socket handshake
  static void connect({String? token}) {
    if (_socket != null && _socket!.connected) return;

    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(10000)
        .build();

    // Add auth token if available
    if (token != null && token.isNotEmpty) {
      opts['auth'] = {'token': token};
    } else if (globalToken != null && globalToken!.isNotEmpty) {
      opts['auth'] = {'token': globalToken};
    }

    _socket = IO.io(socketUrl, opts);
    _socket?.connect();

    _socket?.onConnect((_) {
      print('✅ Socket Connected');
      _reconnectAttempts = 0;
    });

    _socket?.onConnectError((data) {
      print('❌ Socket Connect Error: $data');
    });

    _socket?.onDisconnect((_) {
      print('⚡ Socket Disconnected');
    });

    _socket?.onReconnect((_) {
      print('🔄 Socket Reconnected');
      _reconnectAttempts = 0;
    });

    _socket?.onReconnectAttempt((_) {
      _reconnectAttempts++;
      print('🔄 Reconnect attempt #$_reconnectAttempts');
    });

    _socket?.onReconnectError((_) {
      print('❌ Reconnect error');
    });

    _socket?.onReconnectFailed((_) {
      print('❌ Reconnect failed after $_maxReconnectAttempts attempts');
    });
  }

  /// Subscribe to a stop room (passenger)
  static void subscribeToStop(int stopId) {
    _socket?.emit('stop:subscribe', {'stop_id': stopId});
  }

  /// Join bus room (conductor)
  static void joinBus(int busId) {
    _socket?.emit('bus:join', {'bus_id': busId});
  }

  /// Emit crowd update (conductor)
  static void emitCrowdUpdate(int busId, String crowdLevel, double lat, double lng) {
    _socket?.emit('bus:crowd_update', {
      'bus_id': busId,
      'crowd_level': crowdLevel,
      'lat': lat,
      'lng': lng,
    });
  }

  /// Emit location update (conductor)
  static void emitLocationUpdate(int busId, double lat, double lng) {
    _socket?.emit('bus:location_update', {
      'bus_id': busId,
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static bool get isConnected => _socket?.connected ?? false;

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _reconnectAttempts = 0;
  }
}
