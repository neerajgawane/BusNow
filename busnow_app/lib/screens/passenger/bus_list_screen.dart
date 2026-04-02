import 'package:flutter/material.dart';
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

class _BusListScreenState extends State<BusListScreen> {
  List<dynamic> _buses = [];

  @override
  void initState() {
    super.initState();
    _loadBuses();
    ApiClient.subscribeToStop(widget.stopId);
    ApiClient.onBusCrowdUpdate((_) => _loadBuses());
  }

  Future<void> _loadBuses() async {
    final buses = await ApiClient.getBusesForStop(widget.stopId);
    setState(() => _buses = buses);
  }

  Color _crowdColor(String level) => switch (level) {
    'empty' => Colors.green,
    'moderate' => Colors.yellow.shade700,
    'full' => Colors.orange,
    'overcrowded' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stopName),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBuses),
        ],
      ),
      body: _buses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _buses.length,
              itemBuilder: (_, i) {
                final bus = _buses[i];
                final isBoard = bus['recommendation'] == 'BOARD';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _crowdColor(bus['crowd_level']),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Bus ${bus['bus_number']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'ETA: ${bus['eta_minutes']} mins • ${bus['crowd_level'].toString().toUpperCase()}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isBoard ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBoard ? '✅ BOARD' : '⏳ WAIT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
