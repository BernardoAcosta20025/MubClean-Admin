import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mubclean_admin/login_admin_page.dart'; // Crearemos esto en el paso 3

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // ¡USA LAS MISMAS CREDENCIALES DE TU APP DE CLIENTE!
    url: 'https://nvswszwballqzzuziwyx.supabase.co/', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52c3dzendiYWxscXp6dXppd3l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MTIyNTUsImV4cCI6MjA3ODQ4ODI1NX0.OxfXYVGveWAlMxsSVB4MBIA-3TT_mKuXrCfOWkQs0AY',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MubClean Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith( // TEMA OSCURO PARA ADMIN
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey, // Color serio
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
      home: const LoginAdminPage(),
    );
  }
}