import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'maps_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedStop = 1;
  int _currentIndex = 0;
  List<dynamic> incomingBuses = [
    // Mock data for preview matching UI since socket might be slow
    {'route': '21C', 'eta_minutes': 4, 'crowd_level': 'empty'},
    {'route': 'M70', 'eta_minutes': 12, 'crowd_level': 'moderate'},
    {'route': '19B', 'eta_minutes': 1, 'crowd_level': 'overcrowded'},
  ];

  final List<Map<String, dynamic>> _stops = [
    {"stop_id": 1, "name": "Adyar Signal"},
    {"stop_id": 2, "name": "Kotturpuram"},
    {"stop_id": 3, "name": "Saidapet"},
    {"stop_id": 4, "name": "T. Nagar"},
  ];

  @override
  void initState() {
    super.initState();
    SocketService.connect();
    
    SocketService.on('stop:incoming_buses', (data) {
      if(mounted && data.isNotEmpty) setState(() => incomingBuses = data);
    });
    
    SocketService.on('bus:crowd_update', (data) {
       _subscribeToStop(_selectedStop);
    });
    
    SocketService.on('bus:location_update', (data) {
       _subscribeToStop(_selectedStop);
    });

    _subscribeToStop(_selectedStop);
  }

  void _subscribeToStop(int stopId) {
    SocketService.emit('stop:subscribe', {'stop_id': stopId});
  }

  void _onNavTap(int index) {
    if (index == 1) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassengerStatsScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapsScreen()));
    }
  }

  Color _getCrowdBgColor(String level) {
    if(level == 'empty') return const Color(0xFFDDF5E6);
    if(level == 'moderate') return const Color(0xFFFFECC6);
    if(level == 'full') return const Color(0xFFFFE0CC);
    return const Color(0xFFFFD6D6);
  }
  
  Color _getCrowdTextColor(String level) {
    if(level == 'empty') return const Color(0xFF008A3D);
    if(level == 'moderate') return const Color(0xFFD49A00);
    if(level == 'full') return const Color(0xFFE65C00);
    return const Color(0xFFD32F2F);
  }

  Color _getEtaColor(int eta) {
    if (eta <= 3) return const Color(0xFFD32F2F); // Red
    if (eta <= 8) return const Color(0xFF0F5298); // Blue
    return const Color(0xFF4A4A5A); // Grey
  }

  @override
  Widget build(BuildContext context) {
    String currentStopName = _stops.firstWhere((s) => s['stop_id'] == _selectedStop)['name'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Color(0xFF0F5298)), onPressed: () {}),
        title: const Text('Urban Velocity', style: TextStyle(color: Color(0xFF0F5298), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('YOUR LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A4A5A), letterSpacing: 1.0)),
                IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF0F5298), size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dropdown substitute container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F5298),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(currentStopName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E8E9F), size: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Horizontal Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stops.map((s) {
                  bool isSelected = s['stop_id'] == _selectedStop;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedStop = s['stop_id']);
                        _subscribeToStop(s['stop_id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F5298) : const Color(0xFFEAECEF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4A4A5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('UPCOMING BUSES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F), letterSpacing: 1.5)),
            const SizedBox(height: 16),
            
            // Bus List
            ...incomingBuses.map((bus) => _buildBusCard(bus)).toList(),
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
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'STATS'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    String route = bus['route'] ?? '21C';
    int eta = bus['eta_minutes'] ?? 5;
    String crowd = bus['crowd_level'] ?? 'moderate';
    
    Color etaColor = _getEtaColor(eta);
    Color crowdBgColor = _getCrowdBgColor(crowd);
    Color crowdTextColor = _getCrowdTextColor(crowd);
    
    // Status block
    Widget statusWidget;
    if (crowd == 'overcrowded') {
      statusWidget = const Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Make row items vertically centered
        children: [
          Icon(Icons.warning, color: Color(0xFFD32F2F), size: 16),
          SizedBox(width: 8),
        ],
      );
    } else {
      statusWidget = const Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Make row items vertically centered
        children: [
          Icon(Icons.check_circle, color: Color(0xFF008A3D), size: 16),
          SizedBox(width: 6),
          Text('Board this bus', style: TextStyle(color: Color(0xFF008A3D), fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROUTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F))),
                  Text(route, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF14142B))),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$eta', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: etaColor, height: 1.0, letterSpacing: -2)),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('MIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F), height: 1.0)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: crowdBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(crowd.toUpperCase(), style: TextStyle(color: crowdTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.wifi_tethering, color: Color(0xFFA0A0B0), size: 18),
                ],
              ),
            ],
          ),
        ),
        if (crowd != 'overcrowded')
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 12, bottom: 24),
            child: statusWidget,
          )
        else
          const SizedBox(height: 24),
      ],
    );
  }
}
