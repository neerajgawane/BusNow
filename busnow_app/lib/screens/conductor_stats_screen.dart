import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'conductor_home.dart';
import 'conductor_profile.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        if (mounted) {
          setState(() {
            xp = data['xp'] ?? xp;
            rank = data['rank'] ?? rank;
            badges = data['badges'] != null && data['badges'].isNotEmpty
                ? data['badges']
                : badges;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConductorHomeScreen()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MapsScreen()));
    }
  }

  void _goToProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConductorProfileScreen()));
  }

  // ── Sidebar drawer (matches passenger sidebar exactly) ───────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue header with logo + app name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F5298), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Row(
                children: [
                  // App icon box (white rounded square)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_bus_rounded,
                        color: Color(0xFF0F5298), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urban Velocity',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Conductor App',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      _goToProfile();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    badge: '3',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Trip History',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Saved Stops',
                    onTap: () => Navigator.pop(context),
                  ),

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: Color(0xFFEEEEF2), thickness: 1),
                  ),

                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Version at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F5298), size: 24),
            const SizedBox(width: 18),
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
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F5298),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Badge definitions ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _badgeDefs = [
    {
      'icon': Icons.directions_bus_rounded,
      'label': 'Expert',
      'sub': 'Top Reporter',
      'gradStart': Color(0xFFFFD700),
      'gradEnd': Color(0xFFFF8C00),
      'bg': Color(0xFFFFF8E1),
      'locked': false,
    },
    {
      'icon': Icons.bolt,
      'label': 'Warrior',
      'sub': '50 Updates',
      'gradStart': Color(0xFFFF6B35),
      'gradEnd': Color(0xFFE53935),
      'bg': Color(0xFFFFF3E0),
      'locked': false,
    },
    {
      'icon': Icons.local_fire_department_rounded,
      'label': 'Streak',
      'sub': '7-Day Run',
      'gradStart': Color(0xFF43E97B),
      'gradEnd': Color(0xFF009E60),
      'bg': Color(0xFFE8F5E9),
      'locked': false,
    },
    {
      'icon': Icons.shield_rounded,
      'label': 'Guardian',
      'sub': '???',
      'gradStart': Color(0xFFBDBDBD),
      'gradEnd': Color(0xFF9E9E9E),
      'bg': Color(0xFFF5F5F5),
      'locked': true,
    },
    {
      'icon': Icons.emoji_events_rounded,
      'label': 'Legend',
      'sub': '???',
      'gradStart': Color(0xFFBDBDBD),
      'gradEnd': Color(0xFF9E9E9E),
      'bg': Color(0xFFF5F5F5),
      'locked': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9FB),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF0F5298)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
              onTap: _goToProfile,
              child: const CircleAvatar(
                radius: 16,
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
            // ── XP ring card ─────────────────────────────────────────
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF005AB3)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$xp',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF14142B),
                                  height: 1.0,
                                  letterSpacing: -1),
                            ),
                            const Text(
                              'XP',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005AB3)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(rank,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14142B))),
                    const SizedBox(height: 4),
                    Text('${2000 - xp} XP to next rank',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF666666))),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (xp % 2000) / 2000,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF005AB3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'RANK PROGRESSION',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E9F),
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),

            // ── Rank list ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  borderRadius: BorderRadius.circular(16)),
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

            // ── Badges header ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EARNED BADGES',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E8E9F),
                      letterSpacing: 1.5),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('3 / 8 UNLOCKED',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005AB3))),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Attractive badge cards (horizontal scroll) ────────────
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _badgeDefs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _buildBadgeCard(_badgeDefs[i]),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E9F),
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),

            _buildActivityItem(
                '+10', 'Crowd update submitted', 'Route 242 • 10 mins ago'),
            const SizedBox(height: 12),
            _buildActivityItem(
                '+15', 'Peak hour update', 'Malleswaram Hub • 2 hrs ago'),
            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Bottom nav — 3 items, no Profile ────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: 'STATS'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _buildRankItem(
      String title, String subtitle, String iconStr, bool isCurrent) {
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
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? Colors.white
                            : const Color(0xFF8E8E9F))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isCurrent
                            ? Colors.white70
                            : const Color(0xFFB0B0C0))),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> b) {
    final bool locked = b['locked'] as bool;
    final Color bg = b['bg'] as Color;
    final Color gradStart = b['gradStart'] as Color;
    final Color gradEnd = b['gradEnd'] as Color;
    final IconData icon = b['icon'] as IconData;
    final String label = b['label'] as String;
    final String sub = b['sub'] as String;

    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: locked
              ? const Color(0xFFE0E0E0)
              : gradStart.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: gradStart.withOpacity(0.22),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Subtle shine arc top-right
          if (!locked)
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.30),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gradient icon circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: locked
                        ? null
                        : LinearGradient(
                            colors: [gradStart, gradEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: locked ? const Color(0xFFE0E0E0) : null,
                    boxShadow: locked
                        ? []
                        : [
                            BoxShadow(
                              color: gradStart.withOpacity(0.40),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: locked
                      ? const Icon(Icons.lock_outline_rounded,
                          size: 22, color: Color(0xFFBDBDBD))
                      : Icon(icon, size: 24, color: Colors.white),
                ),

                const SizedBox(height: 8),

                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: locked
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF14142B),
                    letterSpacing: 0.1,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: locked
                        ? const Color(0xFFCCCCCC)
                        : gradEnd.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // "★ NEW" ribbon on Expert badge
          if (!locked && label == 'Expert')
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '★',
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String xpGained, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
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
            child: Text(xpGained,
                style: const TextStyle(
                    color: Color(0xFF005AB3),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF14142B))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E9F))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFD0D0E0)),
        ],
      ),
    );
  }
}