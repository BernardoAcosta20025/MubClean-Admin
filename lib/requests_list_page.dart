import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mubclean_admin/main.dart';
import 'package:mubclean_admin/request_detail_page.dart'; // NECESARIO

class RequestsListPage extends StatefulWidget {
  const RequestsListPage({super.key});

  @override
  State<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends State<RequestsListPage> {
  
  // Stream que escucha cambios en tiempo real en la tabla 'bookings'
  final _bookingsStream = supabase
      .from('bookings')
      .stream(primaryKey: ['id'])
      // Nota: Eliminamos el filtro '.eq('status', 'pending')' para ver todas
      // las solicitudes cotizadas también (para que la app tenga datos).
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes Nuevas"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      backgroundColor: const Color(0xFF121212), // Fondo oscuro
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No hay solicitudes pendientes", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final item = bookings[index];
              final isPending = item['status'] == 'pending';
              
              return Card(
                color: const Color(0xFF2C2C2C),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.blueGrey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPending ? Icons.cleaning_services : Icons.done_all, 
                      color: isPending ? Colors.orange : Colors.blueGrey
                    ),
                  ),
                  title: Text(
                    item['service_type'] ?? 'Servicio',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(item['details'] ?? 'Sin detalles', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(item['created_at']),
                            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  
                  // LÍNEA 87: UBICACIÓN CORRECTA DEL ONTAP
                  onTap: () {
                    // Navegamos y pasamos todos los datos del pedido (item)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailPage(booking: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}