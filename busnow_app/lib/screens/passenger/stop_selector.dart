import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'bus_list_screen.dart';

class StopSelector extends StatefulWidget {
  const StopSelector({super.key});
  @override
  State<StopSelector> createState() => _StopSelectorState();
}

class _StopSelectorState extends State<StopSelector> {
  final List<Map<String, dynamic>> _stops = [
    {'stop_id': 1, 'name': 'Adyar Signal'},
    {'stop_id': 2, 'name': 'Kotturpuram'},
    {'stop_id': 3, 'name': 'Saidapet'},
    {'stop_id': 4, 'name': 'T. Nagar Bus Stand'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Stop'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: const Text(
              'Where are you waiting?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stops.length,
              itemBuilder: (_, i) {
                final stop = _stops[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1565C0),
                      child: Text(
                        '${stop['stop_id']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      stop['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Route 21C'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusListScreen(
                          stopId: stop['stop_id'],
                          stopName: stop['name'],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
