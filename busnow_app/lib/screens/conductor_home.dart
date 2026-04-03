import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';
import '../utils/constants.dart';
import 'conductor_stats_screen.dart';
import 'maps_screen.dart';
import 'login_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  int xp = 0;
  String rank = 'Rookie Reporter';
  int routeXp = 0;
  int busId = 1;
  String conductorName = 'Conductor';
  String _selectedCrowd = 'moderate'; 
  Timer? _gpsTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    SocketService.connect();
    _loadUserData();
    _loadStats();
    _initGPS();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        busId = prefs.getInt('bus_id') ?? 1;
        conductorName = prefs.getString('name') ?? 'Conductor';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/conductor/stats'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            xp = data['xp'] ?? xp;
            rank = data['rank'] ?? rank;
            routeXp = data['xp'] ?? routeXp;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
       try {
         Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
         SocketService.emit('bus:location_update', {
           'bus_id': busId,
           'lat': position.latitude,
           'lng': position.longitude,
           'timestamp': DateTime.now().toIso8601String()
         });
       } catch (e) { debugPrint(e.toString()); }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    SocketService.disconnect();
    super.dispose();
  }

  void _updateCrowd(String level) async {
    setState(() {
      _selectedCrowd = level;
    });
    
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      pos = null;
    }
    
    final body = {
      'crowd_level': level,
      'lat': pos?.latitude ?? 13.0067,
      'lng': pos?.longitude ?? 80.2206,
    };
    
    try {
      await http.patch(
        Uri.parse('$baseUrl/buses/$busId/crowd'),
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $globalToken'
        },
        body: jsonEncode(body),
      );
      _loadStats();
      if(mounted) {
         setState(() {
           routeXp += 10;
           _lastUpdated = DateTime.now();
         });
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('✅ Crowd safely updated! (+10 XP)'),
             backgroundColor: Color(0xFF28A745),
           ),
         );
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorStatsScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapsScreen()));
    } else if (index == 3) {
      _showProfileSheet();
    }
  }

  void _showProfileSheet() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE5EFFF), child: Text(conductorName[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F5298)))),
            const SizedBox(height: 16),
            Text(conductorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('CONDUCTOR', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E9F), letterSpacing: 1)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await prefs.clear();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes} MIN${diff.inMinutes > 1 ? 'S' : ''} AGO';
    return '${diff.inHours} HR${diff.inHours > 1 ? 'S' : ''} AGO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Color(0xFF0F5298), size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bus ${busId == 1 ? "330" : "451"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                          Text('DADAR → ANDHERI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFF333333), size: 14),
                        const SizedBox(width: 4),
                        Text('$routeXp XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Live Crowding', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF222222), letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Tap to update current passenger load', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                    const SizedBox(height: 24),
                    
                    // Options
                    _buildOptionCard('empty', 'Empty', 'Less than 20% full', Icons.sentiment_satisfied_alt, const Color(0xFFDDF5E6), const Color(0xFF28A745)),
                    const SizedBox(height: 16),
                    _buildOptionCard('moderate', 'Moderate', '20-60% full', Icons.people_alt, const Color(0xFFFFF4E5), const Color(0xFFF5A623)),
                    const SizedBox(height: 16),
                    _buildOptionCard('full', 'Full', '60-90% full', Icons.person_add_alt_1, const Color(0xFFFFECE5), const Color(0xFFFF7B00)),
                    const SizedBox(height: 16),
                    _buildOptionCard('overcrowded', 'Overcrowded', 'More than 90% full', Icons.warning_amber_rounded, const Color(0xFFFFE5E5), const Color(0xFFE02020)),
                    
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 16, color: Color(0xFF666666)),
                          const SizedBox(width: 6),
                          Text(
                            _lastUpdated != null
                              ? 'LAST UPDATED: ${_getTimeAgo(_lastUpdated!)}'
                              : 'NO UPDATES YET',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF666666), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Bottom Profile Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.person, color: Colors.black54),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF14142B))),
                          const SizedBox(height: 2),
                          const Text('LEVEL 14 CONDUCTOR', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF666666), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Text('XP: $xp', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F5298))),
                  ],
                ),
              ),
            ),
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

  Widget _buildOptionCard(String value, String title, String subtitle, IconData icon, Color iconBgColor, Color iconColor) {
    bool isSelected = _selectedCrowd == value;
    
    return GestureDetector(
      onTap: () => _updateCrowd(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF0F5298), width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0F5298).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0F5298), size: 24),
          ],
        ),
      ),
    );
  }
}
