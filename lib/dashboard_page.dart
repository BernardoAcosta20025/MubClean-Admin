import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mubclean_admin/main.dart';
import 'package:mubclean_admin/login_admin_page.dart';
import 'package:mubclean_admin/requests_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginAdminPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      // MENÚ LATERAL (DRAWER)
      drawer: Drawer(
        backgroundColor: const Color(0xFF2C2C2C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text('MubClean Admin', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white70),
              title: const Text('Resumen', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
           ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.white70),
              title: const Text('Solicitudes Nuevas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cerrar el menú lateral
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RequestsListPage()),
                );
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              "¡Bienvenido, Jefe!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              "Aquí gestionarás los servicios.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}