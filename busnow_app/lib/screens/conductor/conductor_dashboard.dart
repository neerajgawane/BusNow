import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/auth_provider.dart';

class ConductorDashboard extends StatefulWidget {
  const ConductorDashboard({super.key});
  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  String? _selectedCrowd;
  bool _submitting = false;

  final _crowdOptions = [
    {
      'level': 'empty',
      'label': 'Empty',
      'color': Colors.green,
      'icon': Icons.sentiment_very_satisfied,
    },
    {
      'level': 'moderate',
      'label': 'Moderate',
      'color': Colors.yellow.shade700,
      'icon': Icons.sentiment_satisfied,
    },
    {
      'level': 'full',
      'label': 'Full',
      'color': Colors.orange,
      'icon': Icons.sentiment_dissatisfied,
    },
    {
      'level': 'overcrowded',
      'label': 'Overcrowded',
      'color': Colors.red,
      'icon': Icons.sentiment_very_dissatisfied,
    },
  ];

  Future<void> _submitCrowd(String level) async {
    setState(() {
      _submitting = true;
      _selectedCrowd = level;
    });
    try {
      final pos = await Geolocator.getCurrentPosition();
      final busId = context.read<AuthProvider>().busId;
      await ApiClient.updateCrowd(busId, level, pos.latitude, pos.longitude);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crowd updated: $level (+10 XP)'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚌 Conductor Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFFE3F2FD),
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                  color: Color(0xFF1565C0),
                ),
                title: Text(
                  'Bus ${auth.busId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Route 21C • Adyar → T. Nagar'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tap current crowd level:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...(_crowdOptions.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(opt['icon'] as IconData, color: Colors.white),
                    label: Text(
                      opt['label'] as String,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => _submitCrowd(opt['level'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCrowd == opt['level']
                          ? (opt['color'] as Color)
                          : (opt['color'] as Color).withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
