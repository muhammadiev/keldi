import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/admin_home.dart';
import '../home/home.dart'; // or your home screen import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Login va parolni kiriting");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Real login against the Django backend
    final result = await ApiService.login(login, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final role = (result.data is Map) ? result.data["role"] : "teacher";
      final target = (role == "admin")
          ? const AdminHomeScreen()
          : const HomeScreen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0617) : const Color(0xFFFAF8FF);
    final cardColor = isDark ? const Color(0xFF1C1430) : Colors.white;
    final textColor = isDark ? const Color(0xFFDFD4FF) : const Color(0xFF2A1845);
    final lavender = isDark ? const Color(0xFFCC99FF) : const Color(0xFFB794F4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: lavender,
                ),
                const SizedBox(height: 24),
                Text(
                  "Keldim / Ketdim",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Xodimlar uchun tizimga kirish",
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Login field
                TextField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    labelText: "Login",
                    prefixIcon: Icon(Icons.person, color: lavender),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Parol",
                    prefixIcon: Icon(Icons.lock, color: lavender),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 12),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: lavender,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      "Kirish",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  "Demo (backend):\nteacher1 / demo12345    (o‘qituvchi)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}