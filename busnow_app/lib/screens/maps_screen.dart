import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import 'conductor_home.dart';
import 'conductor_stats_screen.dart';
import 'passenger_home.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  int _currentIndex = 2;
  String? _role;

  LatLng _busLocation = const LatLng(15.4589, 75.0078); // Default Dharwad New Bus Stand
  String _busColor = 'empty';

  final List<LatLng> _routePoints = const [
    LatLng(15.4589, 75.0078),  // Dharwad New Bus Stand
    LatLng(15.4560, 75.0095),  // Dharwad BRTS Terminal
    LatLng(15.4530, 75.0110),  // Jubilee Circle
    LatLng(15.4498, 75.0118),  // Court Circle
    LatLng(15.4470, 75.0130),  // NTTF
    LatLng(15.4440, 75.0155),  // Hosayellapur Cross
    LatLng(15.4410, 75.0175),  // Toll Naka
    LatLng(15.4375, 75.0200),  // Vidyagiri
    LatLng(15.4345, 75.0225),  // Gandhinagar
    LatLng(15.4310, 75.0255),  // Yelakki Shelter Colony Cross
    LatLng(15.4275, 75.0280),  // Lakamanahalli
    LatLng(15.4240, 75.0310),  // Navalur
    LatLng(15.4205, 75.0340),  // Sattur
    LatLng(15.4170, 75.0370),  // SDM Medical College
    LatLng(15.4135, 75.0400),  // Navalur Railway Station
    LatLng(15.4100, 75.0430),  // Sanjivini Park
    LatLng(15.4060, 75.0460),  // KMF1
    LatLng(15.4020, 75.0490),  // Iskcon Temple
    LatLng(15.3980, 75.0520),  // RTO Office
    LatLng(15.3940, 75.0555),  // Rayapur
    LatLng(15.3900, 75.0590),  // Navanagar
    LatLng(15.3860, 75.0625),  // APMC 3rd Gate
    LatLng(15.3820, 75.0660),  // Shantiniketan
    LatLng(15.3780, 75.0700),  // Bairidevarkoppa
    LatLng(15.3740, 75.0740),  // Unkal Lake
    LatLng(15.3700, 75.0775),  // Unakal
    LatLng(15.3665, 75.0810),  // Unakal Cross
    LatLng(15.3630, 75.0845),  // BVB
    LatLng(15.3595, 75.0880),  // Vidyanagar
    LatLng(15.3560, 75.0915),  // KIMS
    LatLng(15.3525, 75.0950),  // Hosur Regional Terminal
    LatLng(15.3490, 75.0985),  // Hosur Cross
    LatLng(15.3455, 75.1020),  // Hubli Central
    LatLng(15.3420, 75.1055),  // Dr. B R Ambedkar Railway Station
    LatLng(15.3385, 75.1090),  // HDMC
    LatLng(15.3350, 75.1124),  // Hubli CBT
  ];

  final List<String> _stopNames = [
    'Dharwad New Bus Stand', 'Dharwad BRTS Terminal', 'Jubilee Circle',
    'Court Circle', 'NTTF', 'Hosayellapur Cross', 'Toll Naka',
    'Vidyagiri', 'Gandhinagar', 'Yelakki Shelter Colony Cross',
    'Lakamanahalli', 'Navalur', 'Sattur', 'SDM Medical College',
    'Navalur Railway Station', 'Sanjivini Park', 'KMF1', 'Iskcon Temple',
    'RTO Office', 'Rayapur', 'Navanagar', 'APMC 3rd Gate',
    'Shantiniketan', 'Bairidevarkoppa', 'Unkal Lake', 'Unakal',
    'Unakal Cross', 'BVB', 'Vidyanagar', 'KIMS',
    'Hosur Regional Terminal', 'Hosur Cross', 'Hubli Central',
    'Dr. B R Ambedkar Railway Station', 'HDMC', 'Hubli CBT',
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
    SocketService.on('bus:location_update', (data) {
      if (mounted && data['lat'] != null && data['lng'] != null) {
        setState(() {
          _busLocation = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          );
        });
        _mapController.move(_busLocation, _mapController.camera.zoom);
      }
    });
    SocketService.on('bus:crowd_update', (data) {
      if (mounted && data['crowd_level'] != null) {
        setState(() => _busColor = data['crowd_level']);
      }
    });
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _role = prefs.getString('role') ?? 'passenger');
  }

  Color _getCrowdColor(String level) {
    switch (level) {
      case 'empty': return const Color(0xFF28A745);
      case 'moderate': return const Color(0xFFF5A623);
      case 'full': return const Color(0xFFFF7B00);
      case 'overcrowded': return const Color(0xFFE02020);
      default: return const Color(0xFF0F5298);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    final isConductor = _role == 'conductor';
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => isConductor ? const ConductorHomeScreen() : const PassengerHomeScreen(),
      ));
    } else if (index == 1) {
      if (isConductor) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorStatsScreen()));
      }
    } else if (index == 3) {
      _showProfileSheet();
    }
  }

  void _showProfileSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User';
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE5EFFF), child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F5298)))),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text((_role ?? 'passenger').toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E9F), letterSpacing: 1)),
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

  @override
  Widget build(BuildContext context) {
    final crowdColor = _getCrowdColor(_busColor);

    final markers = <Marker>[
      // Bus marker
      Marker(
        point: _busLocation,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: crowdColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: crowdColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
        ),
      ),
    ];

    // Stop markers
    for (int i = 0; i < _routePoints.length; i++) {
      markers.add(Marker(
        point: _routePoints[i],
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F5298),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        ),
      ));
    }

    // Center the map on the midpoint of the route
    final midIndex = _routePoints.length ~/ 2;
    final mapCenter = _routePoints[midIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F5298)), onPressed: () => Navigator.pop(context)),
        title: const Text('Live Map', style: TextStyle(color: Color(0xFF0F5298), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.busnow',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: const Color(0xFF0F5298),
                  ),
                ],
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for stops or routes...',
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          // Floating Bus Info Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFE5EFFF), borderRadius: BorderRadius.circular(16)),
                        child: const Column(
                          children: [
                            Text('BUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F5298))),
                            Text('BRTS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F5298))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_alt, color: crowdColor, size: 14),
                              const SizedBox(width: 4),
                              Text(_busColor.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: crowdColor, letterSpacing: 0.5)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F8), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            const Text('STOPS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F))),
                            const SizedBox(height: 2),
                            Text('${_stopNames.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F5298))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stop chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _stopNames.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F5298))),
                          backgroundColor: const Color(0xFFE5EFFF),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            ],
          ),
        ),
      ),
    );
  }
}
