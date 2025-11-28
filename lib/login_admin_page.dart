import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mubclean_admin/main.dart';
import 'package:mubclean_admin/dashboard_page.dart';
import 'package:mubclean_admin/update_password_page.dart'; // <--- IMPORTANTE

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Escuchamos si el usuario viene de un link de recuperación
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _adminLogin() async {
    setState(() => _isLoading = true);
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = res.user?.id;

      if (userId != null) {
        // Verificación de Rol
        final data = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        final role = data['role'];

        if (role == 'admin') {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          }
        } else {
          await supabase.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ACCESO DENEGADO: No tienes permisos.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inesperado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escribe tu correo arriba para recuperar.'),
          ),
        );
      }
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Correo Enviado"),
            content: const Text("Revisa tu bandeja de entrada."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 20),
              const Text(
                "MubClean ADMIN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Acceso exclusivo para personal",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                  labelText: 'Correo Corporativo',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recoverPassword,
                  child: const Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _adminLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("INGRESAR AL PANEL"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
