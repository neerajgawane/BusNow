import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'conductor_home.dart';
import 'passenger_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController(text: '');
  final _passCtrl = TextEditingController(text: '');
  bool _isPassenger = true;
  bool _obscurePass = true;
  bool _loading = false;
  String? _error;

  void _login() async {
  setState(() { _loading = true; _error = null; });
  final role = _isPassenger ? 'passenger' : 'conductor';
  final phone = _phoneCtrl.text.isEmpty
      ? (_isPassenger ? '9988776655' : '9876543210')
      : _phoneCtrl.text.trim();
  final pass = _passCtrl.text.isEmpty
      ? (_isPassenger ? 'passenger123' : 'conductor123')
      : _passCtrl.text.trim();

  final bool isDemoPassenger = phone == '9988776655' && pass == 'passenger123';
  final bool isDemoConductor = phone == '9876543210' && pass == 'conductor123';

  Map<String, dynamic>? user;

  if (isDemoPassenger || isDemoConductor) {
    // Existing demo short-circuit
    user = {
      'name': isDemoPassenger ? 'Demo Passenger' : 'Demo Conductor',
      'id': isDemoPassenger ? 1 : 2,
      'bus_id': 1,
      'route_id': 1,
    };
  } else {
    // ── Check locally registered users ──
    final prefs = await SharedPreferences.getInstance();
    final existingUsers = prefs.getStringList('registered_phones') ?? [];

    if (existingUsers.contains(phone)) {
      final savedPass = prefs.getString('user_pass_$phone');
      if (savedPass == pass) {
        user = {
          'name': prefs.getString('user_name_$phone') ?? 'User',
          'id': phone.hashCode.abs(),
          'bus_id': 1,
          'route_id': 1,
        };
      }
    } else {
      // Fallback to real API if not found locally
      user = await ApiService.login(phone, pass, role);
    }
  }

  if (!mounted) return;
  setState(() => _loading = false);

  if (user != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', user['name'] ?? '');
    await prefs.setString('role', role);
    await prefs.setInt('bus_id', user['bus_id'] ?? 1);
    await prefs.setInt('route_id', user['route_id'] ?? 1);
    await prefs.setInt('user_id', user['id'] ?? 0);

    if (!mounted) return;
    if (_isPassenger) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassengerHomeScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorHomeScreen()));
    }
  } else {
    setState(() => _error = 'Invalid phone or password');
  }
}

  // ── Dynamic theme based on role ──
  Color get _primaryColor => _isPassenger ? const Color(0xFF0F5298) : const Color(0xFF0F5298);
  Color get _primaryDark => _isPassenger ? const Color(0xFF003C71) : const Color(0xFF003C71);
  Color get _accentBg => _isPassenger ? const Color(0xFFE5EFFF) : const Color(0xFFFFF3E0);
  String get _title => _isPassenger ? 'Passenger' : 'Conductor';
  String get _subtitle => _isPassenger ? 'Track buses & plan your commute' : 'Update crowds & earn rewards';
  IconData get _icon => _isPassenger ? Icons.person_pin_circle : Icons.badge;
  String get _hintPhone => _isPassenger ? '9988776655' : '9876543210';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── App Branding ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.directions_bus, size: 28, color: _primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Text('BusNow', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Role Toggle ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildRoleTab('Passenger', Icons.person, true),
                        _buildRoleTab('Conductor', Icons.engineering, false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Role Icon + Title ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_isPassenger),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(_title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(_subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Login Card ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('PHONE NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryColor, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: _hintPhone,
                            hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
                            prefixIcon: Icon(Icons.phone, color: _primaryColor.withOpacity(0.5)),
                            filled: true,
                            fillColor: _accentBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryColor, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
                            prefixIcon: Icon(Icons.lock, color: _primaryColor.withOpacity(0.5)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF8E8E9F)),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            filled: true,
                            fillColor: _accentBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 4,
                            shadowColor: _primaryColor.withOpacity(0.4),
                          ),
                          child: _loading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Login as $_title', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Register Link ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New here? ', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Quick hint for demo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Leave fields empty for demo login',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, IconData icon, bool isPassengerTab) {
    final isSelected = _isPassenger == isPassengerTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPassenger = isPassengerTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? _primaryColor : Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? (isPassengerTab ? const Color(0xFF0F5298) : const Color(0xFFE65100)) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
