import 'package:flutter/material.dart';
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

  void _login() async {
    setState(() => _loading = true);
    final role = _isPassenger ? 'passenger' : 'conductor';
    final phone = _phoneCtrl.text.isEmpty ? '9876543210' : _phoneCtrl.text;
    final pass = _passCtrl.text.isEmpty ? (_isPassenger ? 'password' : 'BusNow@Conductor1') : _passCtrl.text;
    
    final user = await ApiService.login(phone, pass, role);
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (user != null) {
      if (_isPassenger) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassengerHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConductorHomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F5298), Color(0xFF1D78CD)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_bus, size: 48, color: Color(0xFF0F5298)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Urban Velocity', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
                  const SizedBox(height: 8),
                  const Text('TRANSIT REDEFINED', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2.0, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEBF0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPassenger = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isPassenger ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isPassenger ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                                ),
                                alignment: Alignment.center,
                                child: Text("I'm a Passenger", style: TextStyle(color: _isPassenger ? const Color(0xFF0F5298) : const Color(0xFF4A4A5A), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPassenger = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isPassenger ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isPassenger ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                                ),
                                alignment: Alignment.center,
                                child: Text("I'm a Conductor", style: TextStyle(color: !_isPassenger ? const Color(0xFF0F5298) : const Color(0xFF4A4A5A), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('PHONE NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A4A5A), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+91 98765 43210',
                        hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF8E8E9F)),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A4A5A), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF8E8E9F)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF8E8E9F)),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Access?', style: TextStyle(color: Color(0xFF0F5298), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005AB3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 4,
                        shadowColor: const Color(0xFF005AB3).withOpacity(0.4),
                      ),
                      child: _loading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New here? ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                          },
                          child: const Text('Register', style: TextStyle(color: Color(0xFF005AB3), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('HELP', style: TextStyle(fontSize: 10, color: Color(0xFFA0A0B0), fontWeight: FontWeight.bold)),
                            SizedBox(width: 24),
                            Text('PRIVACY', style: TextStyle(fontSize: 10, color: Color(0xFFA0A0B0), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('V2.4.0-KINETIC', style: TextStyle(fontSize: 10, color: Color(0xFFA0A0B0), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
