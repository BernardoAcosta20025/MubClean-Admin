import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importar intl para formatear fechas
import 'package:mubclean_admin/main.dart'; // Tu instancia global de supabase
import 'package:mubclean_admin/request_detail_page.dart';

class RequestsListPage extends StatefulWidget {
  const RequestsListPage({super.key});

  @override
  State<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends State<RequestsListPage> {
  // Stream que escucha SOLICITUDES NUEVAS
  final _bookingsStream = supabase
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('status', 'pending_quote') // <--- FILTRO CLAVE: Solo las que esperan cotización
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Solicitudes Nuevas"),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
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
                  Text("Al día: No hay solicitudes pendientes", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final item = bookings[index];
              final date = DateTime.parse(item['scheduled_date']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(date);

              return Card(
                color: const Color(0xFF2C2C2C),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cleaning_services, color: Colors.orange),
                  ),
                  title: const Text(
                    "Solicitud de Cotización", // O podrías poner el nombre del cliente si haces join
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        "📅 $formattedDate - ${item['scheduled_time']}", 
                        style: const TextStyle(color: Colors.grey)
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "📍 ${item['address_street']}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailPage(bookingId: item['id']), // Pasamos solo el ID
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
}