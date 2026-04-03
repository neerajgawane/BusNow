import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final success = await ApiService.register(name, phone, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please login.'), backgroundColor: Color(0xFF28A745)),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Phone number already registered or server error.');
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
              padding: const EdgeInsets.only(top: 80, bottom: 50),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add, size: 40, color: Color(0xFF0F5298)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('JOIN THE NETWORK', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('FULL NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A4A5A), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Conductor Raj',
                        hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF8E8E9F)),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 24),

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

                    if (_error != null) ...[
                      const SizedBox(height: 16),
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
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005AB3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 4,
                        shadowColor: const Color(0xFF005AB3).withOpacity(0.4),
                      ),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(color: Color(0xFF005AB3), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
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
