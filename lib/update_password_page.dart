import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mubclean_admin/main.dart';
import 'package:mubclean_admin/login_admin_page.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mínimo 6 caracteres")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Actualizar contraseña
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      // 2. Cerrar sesión por seguridad
      await supabase.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Contraseña actualizada! Inicia sesión de nuevo."),
            backgroundColor: Colors.green,
          )
        );
        
        // 3. Volver al Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginAdminPage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restablecer Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 60, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text("Crea tu nueva clave de acceso", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                prefixIcon: Icon(Icons.lock, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Guardar Nueva Contraseña", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}