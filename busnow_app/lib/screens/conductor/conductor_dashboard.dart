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

class _ConductorDashboardState extends State<ConductorDashboard> with SingleTickerProviderStateMixin {
  String? _selectedCrowd;
  bool _submitting = false;

  late AnimationController _xpController;
  late Animation<double> _xpScale;

  @override
  void initState() {
    super.initState();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _xpScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_xpController);
  }

  @override
  void dispose() {
    _xpController.dispose();
    super.dispose();
  }

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
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await ApiClient.updateCrowd(auth.busId, level, pos.latitude, pos.longitude);
      
      auth.addXp(10);
      _xpController.forward(from: 0.0); // Trigger XP animation!
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crowd updated to ${level.toUpperCase()}! (+10 XP)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _submitting = false);
  }

  void _showBadgesModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆 Your Badges', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.star, color: Colors.white)),
              title: const Text('Route Expert', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Consistently reporting on this route.'),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.local_fire_department, color: Colors.white)),
              title: const Text('Peak Warrior', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('10 updates during rush hour.'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Conductor Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: 'Badges',
            onPressed: _showBadgesModal,
          )
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gamification Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR REWARDS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _xpScale,
                            builder: (context, child) => Transform.scale(
                              scale: _xpScale.value,
                              child: Text('${auth.xp} XP', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      ScaleTransition(
                        scale: _xpScale,
                        child: const Icon(Icons.stars, color: Colors.amber, size: 56),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Bus Assigment
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
                    ),
                    title: Text('Bus ${auth.busId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: const Text('Route 21C • Adyar → T. Nagar', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Current Crowd Level',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: _crowdOptions.map((opt) {
                      final isSelected = _selectedCrowd == opt['level'];
                      return InkWell(
                        onTap: _submitting ? null : () => _submitCrowd(opt['level'] as String),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? (opt['color'] as Color) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: (opt['color'] as Color).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                size: 48,
                                color: isSelected ? Colors.white : (opt['color'] as Color),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
