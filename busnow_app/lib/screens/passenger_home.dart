import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';
import '../utils/constants.dart';
import 'maps_screen.dart';
import 'login_screen.dart';
import 'passenger_profile.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedStop = 1;
  int _currentIndex = 0;
  bool _loading = true;
  List<dynamic> incomingBuses = [];

  final List<Map<String, dynamic>> _stops = [
    {"stop_id": 1,  "name": "Dharwad New Bus Stand"},
    {"stop_id": 2,  "name": "Dharwad BRTS Terminal"},
    {"stop_id": 3,  "name": "Jubilee Circle"},
    {"stop_id": 4,  "name": "Court Circle"},
    {"stop_id": 5,  "name": "NTTF"},
    {"stop_id": 6,  "name": "Hosayellapur Cross"},
    {"stop_id": 7,  "name": "Toll Naka"},
    {"stop_id": 8,  "name": "Vidyagiri"},
    {"stop_id": 9,  "name": "Gandhinagar"},
    {"stop_id": 10, "name": "Yelakki Shelter Colony Cross"},
    {"stop_id": 11, "name": "Lakamanahalli"},
    {"stop_id": 12, "name": "Navalur"},
    {"stop_id": 13, "name": "Sattur"},
    {"stop_id": 14, "name": "SDM Medical College"},
    {"stop_id": 15, "name": "Navalur Railway Station"},
    {"stop_id": 16, "name": "Sanjivini Park"},
    {"stop_id": 17, "name": "KMF1"},
    {"stop_id": 18, "name": "Iskcon Temple"},
    {"stop_id": 19, "name": "RTO Office"},
    {"stop_id": 20, "name": "Rayapur"},
    {"stop_id": 21, "name": "Navanagar"},
    {"stop_id": 22, "name": "APMC 3rd Gate"},
    {"stop_id": 23, "name": "Shantiniketan"},
    {"stop_id": 24, "name": "Bairidevarkoppa"},
    {"stop_id": 25, "name": "Unkal Lake"},
    {"stop_id": 26, "name": "Unakal"},
    {"stop_id": 27, "name": "Unakal Cross"},
    {"stop_id": 28, "name": "BVB"},
    {"stop_id": 29, "name": "Vidyanagar"},
    {"stop_id": 30, "name": "KIMS"},
    {"stop_id": 31, "name": "Hosur Regional Terminal"},
    {"stop_id": 32, "name": "Hosur Cross"},
    {"stop_id": 33, "name": "Hubli Central"},
    {"stop_id": 34, "name": "Dr. B R Ambedkar Railway Station"},
    {"stop_id": 35, "name": "HDMC"},
    {"stop_id": 36, "name": "Hubli CBT"},
  ];

  // Static fallback bus data for demo — used when API is unavailable
  List<Map<String, dynamic>> _getStaticBuses(int stopId) {
    // Calculate a simple fake ETA based on stop position
    final etaBus1 = (stopId <= 18) ? (stopId * 2) : ((36 - stopId) * 2 + 1);
    final etaBus2 = (stopId <= 18) ? ((18 - stopId).abs() * 2 + 3) : ((stopId - 18) * 2);
    return [
      {
        'bus_id': 1,
        'bus_number': 'BRTS-001',
        'crowd_level': _crowdOverrides[1] ?? 'moderate',
        'eta_minutes': etaBus1.clamp(1, 45),
        'lat': 15.4589,
        'lng': 75.0078,
      },
      {
        'bus_id': 2,
        'bus_number': 'BRTS-002',
        'crowd_level': _crowdOverrides[2] ?? 'empty',
        'eta_minutes': etaBus2.clamp(1, 45),
        'lat': 15.3980,
        'lng': 75.0520,
      },
    ];
  }

  // Track crowd level overrides from conductor updates
  final Map<int, String> _crowdOverrides = {};

  @override
  void initState() {
    super.initState();
    SocketService.connect(token: globalToken);

    SocketService.on('stop:incoming_buses', (data) {
      if (mounted && data is List) {
        setState(() {
          if (data.isNotEmpty) {
            incomingBuses = data;
          } else {
            incomingBuses = _getStaticBuses(_selectedStop);
          }
          _loading = false;
        });
      }
    });

    // Listen for real-time crowd updates and instantly reflect them
    SocketService.on('bus:crowd_update', (data) {
      if (mounted && data is Map) {
        final busId = data['bus_id'];
        final crowdLevel = data['crowd_level'];
        if (busId != null && crowdLevel != null) {
          setState(() {
            _crowdOverrides[busId] = crowdLevel;
            // Update the current bus list immediately
            for (int i = 0; i < incomingBuses.length; i++) {
              if (incomingBuses[i]['bus_id'] == busId) {
                incomingBuses[i] = Map<String, dynamic>.from(incomingBuses[i]);
                incomingBuses[i]['crowd_level'] = crowdLevel;
              }
            }
          });
        }
      }
      _subscribeToStop(_selectedStop);
    });

    SocketService.on('bus:location_update', (data) {
      _subscribeToStop(_selectedStop);
    });

    _subscribeToStop(_selectedStop);
    _fetchBusesRest(_selectedStop);
  }

  void _subscribeToStop(int stopId) {
    SocketService.emit('stop:subscribe', {'stop_id': stopId});
  }

  Future<void> _fetchBusesRest(int stopId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/stops/$stopId/buses'),
        headers: {
          if (globalToken != null && globalToken!.isNotEmpty)
            'Authorization': 'Bearer $globalToken',
        },
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            incomingBuses = data;
            _loading = false;
          });
        } else {
          // API returned empty — use static fallback
          if (mounted) {
            setState(() {
              incomingBuses = _getStaticBuses(stopId);
              _loading = false;
            });
          }
        }
      } else {
        // Non-200 response — use static fallback
        if (mounted) {
          setState(() {
            incomingBuses = _getStaticBuses(stopId);
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      // Network error — use static fallback
      if (mounted) {
        setState(() {
          incomingBuses = _getStaticBuses(stopId);
          _loading = false;
        });
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MapsScreen()));
    }
    // index 2 = Alerts (no-op for now)
  }

  /// Opens the sidebar drawer
  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sidebar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(-1, 0), end: Offset.zero)
                .animate(curved),
            child: _DrawerContent(
              stops: _stops,
              onNavigateToProfile: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PassengerProfileScreen()),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Shows the stop picker bottom sheet
  void _showStopPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT STOP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E9F),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._stops.map((s) {
              final isSelected = s['stop_id'] == _selectedStop;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F5298)
                        : const Color(0xFFEAECEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: isSelected ? Colors.white : const Color(0xFF8E8E9F),
                    size: 20,
                  ),
                ),
                title: Text(
                  s['name'],
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0F5298)
                        : const Color(0xFF14142B),
                    fontSize: 16,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF0F5298), size: 22)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStop = s['stop_id'];
                    _loading = true;
                    incomingBuses = [];
                  });
                  _subscribeToStop(s['stop_id']);
                  _fetchBusesRest(s['stop_id']);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getCrowdBgColor(String level) {
    if (level == 'empty') return const Color(0xFFDDF5E6);
    if (level == 'moderate') return const Color(0xFFFFECC6);
    if (level == 'full') return const Color(0xFFFFE0CC);
    return const Color(0xFFFFD6D6);
  }

  Color _getCrowdTextColor(String level) {
    if (level == 'empty') return const Color(0xFF008A3D);
    if (level == 'moderate') return const Color(0xFFD49A00);
    if (level == 'full') return const Color(0xFFE65C00);
    return const Color(0xFFD32F2F);
  }

  Color _getEtaColor(int eta) {
    if (eta <= 3) return const Color(0xFFD32F2F);
    if (eta <= 8) return const Color(0xFF0F5298);
    return const Color(0xFF4A4A5A);
  }

  @override
  Widget build(BuildContext context) {
    final currentStopName =
        _stops.firstWhere((s) => s['stop_id'] == _selectedStop)['name'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F5298), size: 26),
          onPressed: () => _openDrawer(context),
        ),
        title: const Text(
          'Urban Velocity',
          style: TextStyle(
            color: Color(0xFF0F5298),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PassengerProfileScreen()),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                backgroundColor: Colors.black12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E9F),
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location,
                      color: Color(0xFF0F5298), size: 20),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Stop selector (functional dropdown) ──
            GestureDetector(
              onTap: _showStopPicker,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F5298),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentStopName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14142B),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF8E8E9F), size: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stop chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stops.map((s) {
                  final isSelected = s['stop_id'] == _selectedStop;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStop = s['stop_id'];
                          _loading = true;
                          incomingBuses = [];
                        });
                        _subscribeToStop(s['stop_id']);
                        _fetchBusesRest(s['stop_id']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F5298)
                              : const Color(0xFFEAECEF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0F5298)
                                        .withOpacity(0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          s['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A4A5A),
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

            // ── Section title ──
            Row(
              children: [
                const Text(
                  'UPCOMING BUSES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E9F),
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (!_loading)
                  Text(
                    '${incomingBuses.length} found',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F5298),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Bus list ──
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F5298))),
              )
            else if (incomingBuses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus_outlined,
                          size: 52, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No buses on this route right now.',
                        style: TextStyle(
                            fontSize: 15, color: Color(0xFF8E8E9F)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...incomingBuses.map((bus) => _buildBusCard(bus)).toList(),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Bottom nav (3 items, no Profile) ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0F5298),
            unselectedItemColor: const Color(0xFF999999),
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.directions_bus), label: 'BUSES'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications), label: 'ALERTS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    final String busNumber = bus['bus_number'] ?? '';
    final String route = bus['route'] ?? 'BRTS';
    final int eta = bus['eta_minutes'] ?? 5;
    final String crowd = bus['crowd_level'] ?? 'moderate';

    final Color etaColor = _getEtaColor(eta);
    final Color crowdBgColor = _getCrowdBgColor(crowd);
    final Color crowdTextColor = _getCrowdTextColor(crowd);
    final bool isCrowded = crowd == 'overcrowded' || crowd == 'full';

    final Widget statusWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isCrowded
            ? const Color(0xFFFFE5E5)
            : const Color(0xFFDDF5E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCrowded ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: isCrowded
                ? const Color(0xFFD32F2F)
                : const Color(0xFF008A3D),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isCrowded ? 'Wait for next bus' : 'Board this bus',
            style: TextStyle(
              color: isCrowded
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF008A3D),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Route
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROUTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E8E9F),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    busNumber.isNotEmpty ? busNumber : route,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF14142B),
                    ),
                  ),
                ],
              ),
              // ETA
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$eta',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: etaColor,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        'MIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E8E9F),
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
              // Crowd + live indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: crowdBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      crowd.toUpperCase(),
                      style: TextStyle(
                        color: crowdTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.wifi_tethering,
                      color: Color(0xFFA0A0B0), size: 18),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 10, bottom: 24),
          child: statusWidget,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sidebar drawer widget
// ─────────────────────────────────────────────
class _DrawerContent extends StatelessWidget {
  final List<Map<String, dynamic>> stops;
  final VoidCallback onNavigateToProfile;

  const _DrawerContent({
    required this.stops,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.76,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A3D7A), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.directions_bus_filled,
                          color: Color(0xFF0F5298), size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Urban Velocity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Passenger App',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Menu items
              _drawerItem(
                icon: Icons.person_outline_rounded,
                label: 'My Profile',
                onTap: onNavigateToProfile,
              ),
              _drawerItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                badge: '3',
                onTap: () => Navigator.pop(context),
              ),
              _drawerItem(
                icon: Icons.history_rounded,
                label: 'Trip History',
                onTap: () => Navigator.pop(context),
              ),
              _drawerItem(
                icon: Icons.favorite_border_rounded,
                label: 'Saved Stops',
                onTap: () => Navigator.pop(context),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Divider(color: Color(0xFFF0F0F5)),
              ),

              _drawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => Navigator.pop(context),
              ),
              _drawerItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => Navigator.pop(context),
              ),
              _drawerItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                onTap: () => Navigator.pop(context),
              ),

              const Spacer(),

              // App version
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0F5298), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14142B),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5298),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}