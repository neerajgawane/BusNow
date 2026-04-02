import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api_client.dart';

class BusListScreen extends StatefulWidget {
  final int stopId;
  final String stopName;
  const BusListScreen({
    super.key,
    required this.stopId,
    required this.stopName,
  });
  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> with TickerProviderStateMixin {
  List<dynamic> _buses = [];
  bool _loading = true;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadBuses();
    ApiClient.subscribeToStop(widget.stopId);
    ApiClient.onBusCrowdUpdate((_) => _loadBuses());
  }

  Future<void> _loadBuses() async {
    final buses = await ApiClient.getBusesForStop(widget.stopId);
    if (mounted) {
      setState(() {
        _buses = buses;
        _loading = false;
      });
    }
  }

  Color _crowdColor(String level) => switch (level.toLowerCase()) {
    'empty' => Colors.green,
    'moderate' => Colors.yellow.shade700,
    'full' => Colors.orange,
    'overcrowded' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    // Provide a default center in Chennai for demo if no buses yet
    LatLng centerLatlng = const LatLng(13.0012, 80.2565); // T. Nagar area roughly
    if (_buses.isNotEmpty) {
      final b = _buses.first;
      if (b['current_lat'] != null && b['current_lng'] != null) {
        centerLatlng = LatLng(
            double.tryParse(b['current_lat'].toString()) ?? centerLatlng.latitude,
            double.tryParse(b['current_lng'].toString()) ?? centerLatlng.longitude);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.stopName),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // MAP VIEW AREA
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerLatlng,
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.busnow',
                      ),
                      MarkerLayer(
                        markers: _buses.where((b) => b['current_lat'] != null && b['current_lng'] != null).map((b) {
                          final lat = double.tryParse(b['current_lat'].toString()) ?? 0.0;
                          final lng = double.tryParse(b['current_lng'].toString()) ?? 0.0;
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 60,
                            height: 60,
                            child: Hero(
                              tag: "bus_marker_${b['bus_number']}",
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _crowdColor(b['crowd_level']),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                                ),
                                child: const Icon(Icons.directions_bus, color: Colors.white, size: 30),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // JAW-DROPPING ETA RECOMMENDATIONS
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                    ),
                    child: _buses.isEmpty
                        ? const Center(child: Text("No buses running currently.", style: TextStyle(fontSize: 18)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                            itemCount: _buses.length,
                            itemBuilder: (context, i) {
                              final bus = _buses[i];
                              final isBoard = bus['recommendation'] == 'BOARD';
                              final crowdColor = _crowdColor(bus['crowd_level']);
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: isBoard
                                      ? LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100])
                                      : LinearGradient(colors: [Colors.orange.shade50, Colors.red.shade50]),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isBoard ? Colors.green.shade300 : Colors.red.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isBoard ? Colors.green : Colors.red).withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // ETA / Status Circle
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: isBoard ? Colors.green : Colors.redAccent,
                                          shape: BoxShape.circle,
                                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${bus['eta_minutes']}',
                                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                              ),
                                              const Text('MINS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Meta
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bus ${bus['bus_number']}',
                                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.people, size: 16, color: crowdColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  bus['crowd_level'].toString().toUpperCase(),
                                                  style: TextStyle(color: crowdColor, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isBoard ? Colors.green : Colors.redAccent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isBoard ? '✅ SAFE TO BOARD' : '⏳ WAIT FOR NEXT BUS',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
