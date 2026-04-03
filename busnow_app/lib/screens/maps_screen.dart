import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/socket_service.dart';
import 'conductor_home.dart';
import 'conductor_stats_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? mapController;
  int _currentIndex = 2; // Map is selected
  
  LatLng _busLocation = const LatLng(13.0067, 80.2206); // Default Adyar
  final List<LatLng> _routePoints = const [
    LatLng(13.0067, 80.2206),
    LatLng(13.0142, 80.2263),
    LatLng(13.0201, 80.2237),
    LatLng(13.0418, 80.2341),
  ];

  @override
  void initState() {
    super.initState();
    SocketService.on('bus:location_update', (data) {
       if (mounted) {
         setState(() {
            _busLocation = LatLng(data['lat'], data['lng']);
         });
         mapController?.animateCamera(CameraUpdate.newLatLng(_busLocation));
       }
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorHomeScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorStatsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('bus_1'),
        position: _busLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Bus 21C', snippet: 'Live Location Tracking'),
      ),
    };
    
    for(int i = 0; i < _routePoints.length; i++) {
        markers.add(
           Marker(
               markerId: MarkerId('stop_$i'),
               position: _routePoints[i],
               infoWindow: InfoWindow(title: 'Stop ${i+1}'),
               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
           )
        );
    }

    return Scaffold(
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
      body: Stack(
        children: [
          // The Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _busLocation, zoom: 14),
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            polylines: {
               Polyline(
                   polylineId: const PolylineId('route_1'),
                   points: _routePoints,
                   color: const Color(0xFF0F5298),
                   width: 5,
               )
            },
          ),
          
          // Floating Search Bar
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
          
          // Floating Bottom Cards
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'loc_btn',
                        onPressed: () {},
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: Color(0xFF0F5298)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'dir_btn',
                        onPressed: () {},
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.navigation, color: Color(0xFF0F5298)),
                      ),
                    ],
                  ),
                ),
                // Bottom Sheet Card
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
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
                                Text('21C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F5298))),
                              ],
                            ),
                          ),
                          
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ETA 4 mins', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.people_alt, color: Color(0xFFE02020), size: 14),
                                  SizedBox(width: 4),
                                  Text('OVERCROWDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE02020), letterSpacing: 0.5)),
                                ],
                              ),
                            ],
                          ),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFF3F4F8), borderRadius: BorderRadius.circular(16)),
                            child: const Column(
                              children: [
                                Text('NEXT STOP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8E8E9F))),
                                SizedBox(height: 2),
                                Text('Saidapet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F5298))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.track_changes, color: Colors.white, size: 20),
                        label: const Text('Track this bus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005AB3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: const Color(0xFF005AB3).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ClipRect(
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
}
