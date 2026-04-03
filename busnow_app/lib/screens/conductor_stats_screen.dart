import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'conductor_home.dart';
import 'maps_screen.dart';

class ConductorStatsScreen extends StatefulWidget {
  const ConductorStatsScreen({super.key});

  @override
  State<ConductorStatsScreen> createState() => _ConductorStatsScreenState();
}

class _ConductorStatsScreenState extends State<ConductorStatsScreen> {
  int xp = 1240;
  String rank = 'Route Veteran';
  List<dynamic> badges = ['Expert', 'Warrior', 'Streak'];
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/conductor/stats'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if(mounted) {
           setState(() {
             xp = data['xp'] ?? xp;
             rank = data['rank'] ?? rank;
             badges = data['badges'] != null && data['badges'].isNotEmpty ? data['badges'] : badges;
           });
        }
      }
    } catch(e) { debugPrint(e.toString()); }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorHomeScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapsScreen()));
    }
    // Profile is 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF0F5298)),
          onPressed: () {},
        ),
        title: const Text('Urban Velocity', style: TextStyle(color: Color(0xFF0F5298), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'), // Placeholder for profile pic
              backgroundColor: Colors.black12,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Circular Progress
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F6),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: (xp % 2000) / 2000,
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005AB3)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$xp', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF14142B), height: 1.0, letterSpacing: -1)),
                            const Text('XP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF005AB3))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(rank, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                    const SizedBox(height: 4),
                    Text('${2000 - xp} XP to next rank', style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (xp % 2000) / 2000,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005AB3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('RANK PROGRESSION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F), letterSpacing: 1.5)),
            const SizedBox(height: 16),
            
            // Rank List
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildRankItem('Transit Legend', '5000+ XP', '🏆', false),
                  _buildRankItem('Road Guardian', '2000-5000 XP', '🥇', false),
                  _buildRankItem('Route Veteran', '500-2000 XP', '🥈', true),
                  _buildRankItem('Rookie Reporter', '0-500 XP', '🥉', false),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EARNED BADGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F), letterSpacing: 1.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('3 / 8 UNLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF005AB3))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadgeItem(Icons.directions_bus, 'Expert', const Color(0xFFFFEABB), const Color(0xFFD49A00), true),
                _buildBadgeItem(Icons.bolt, 'Warrior', const Color(0xFFFFE5CC), const Color(0xFFE65C00), false),
                _buildBadgeItem(Icons.calendar_today, 'Streak', const Color(0xFFD5F5E3), const Color(0xFF008A3D), false),
                _buildBadgeItem(Icons.star, 'Locked', const Color(0xFFEAECEF), const Color(0xFF8E8E9F), false, isLocked: true),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F), letterSpacing: 1.5)),
            const SizedBox(height: 16),
            
            _buildActivityItem('+10', 'Crowd update submitted', 'Route 242 • 10 mins ago'),
            const SizedBox(height: 12),
            _buildActivityItem('+15', 'Peak hour update', 'Malleswaram Hub • 2 hrs ago'),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0F5298),
            unselectedItemColor: const Color(0xFF999999),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'BUSES'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'STATS'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankItem(String title, String subtitle, String iconStr, bool isCurrent) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF005AB3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(iconStr, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : const Color(0xFF8E8E9F))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isCurrent ? Colors.white70 : const Color(0xFFB0B0C0))),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String label, Color bgColor, Color fgColor, bool isPillVariant, {bool isLocked = false}) {
    return Container(
      width: 75,
      height: 90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fgColor, size: 32),
          const SizedBox(height: 8),
          if (isPillVariant)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            )
          else
            Text(label, style: TextStyle(color: fgColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String xpGained, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F5FF),
              shape: BoxShape.circle,
            ),
            child: Text(xpGained, style: const TextStyle(color: Color(0xFF005AB3), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14142B))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E9F))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFD0D0E0)),
        ],
      ),
    );
  }
}
