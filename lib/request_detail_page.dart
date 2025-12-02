import 'package:flutter/material.dart';
import 'package:mubclean_admin/main.dart'; // Tu instancia de supabase

class RequestDetailPage extends StatefulWidget {
  final String bookingId; // Recibimos el ID para buscar todo fresco

  const RequestDetailPage({super.key, required this.bookingId});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final _priceController = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _clientProfile;
  List<dynamic> _items = [];
  List<dynamic> _evidence = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // 1. Cargar Booking con sus Relaciones (Items y Evidencia)
      final bookingData = await supabase
          .from('bookings')
          .select('*, booking_items(*), booking_evidence(*)')
          .eq('id', widget.bookingId)
          .single();
      
      // 2. Cargar Datos del Cliente
      final userId = bookingData['user_id'];
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // maybeSingle evita error si no hay perfil

      setState(() {
        _booking = bookingData;
        _items = bookingData['booking_items'] ?? [];
        _evidence = bookingData['booking_evidence'] ?? [];
        _clientProfile = profileData;
        
        // Pre-llenamos con el estimado que dio el cliente (si quieres)
        _priceController.text = bookingData['total_price'].toString();
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando: $e')));
        _isLoading = false; 
      }
    }
  }

  // --- FUNCIÓN MAESTRA: COTIZAR Y NOTIFICAR ---
  Future<void> _sendQuoteToClient() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un precio")));
      return;
    }

    setState(() => _isSending = true);

    try {
      final double precioFinal = double.parse(_priceController.text);
      final userId = _booking!['user_id'];

      // 1. Actualizar la Reserva (Poner precio real y cambiar estado)
      await supabase.from('bookings').update({
        'status': 'quoted', // Estatus: "Cotizado" (Ya no es pendiente)
        'total_price': precioFinal,
      }).eq('id', widget.bookingId);

      // 2. Enviar Notificación al Cliente
      await supabase.from('notifications').insert({
        'user_id': userId,
        'booking_id': widget.bookingId,
        'title': '¡Tu cotización está lista! 📄',
        'body': 'El técnico ha revisado tu solicitud. Precio final: \$$precioFinal. Toca para pagar.',
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Cotización enviada con éxito!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Volver a la lista
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Detalle de Solicitud"),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. INFO GENERAL
            const _SectionTitle("Ubicación y Fecha"),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _InfoRow(
                    Icons.calendar_today, 
                    Colors.orange, 
                    "Fecha Solicitada", 
                    "${_booking?['scheduled_date']} - ${_booking?['scheduled_time']}"
                  ),
                  const Divider(color: Colors.grey, height: 30),
                  _InfoRow(
                    Icons.location_on, 
                    Colors.redAccent, 
                    "Dirección", 
                    _booking?['address_street'] ?? 'No especificada'
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    Icons.person_pin_circle, 
                    Colors.blue, 
                    "Recibe", 
                    _booking?['receiver_name'] ?? 'No especificado'
                  ),
                ],
              ),
            ),

            // 2. CLIENTE
            const SizedBox(height: 25),
            const _SectionTitle("Datos del Cliente"),
            if (_clientProfile != null) ...[
              _InfoTile(Icons.person, _clientProfile!['full_name'] ?? 'Anónimo'),
              _InfoTile(Icons.phone, _clientProfile!['phone'] ?? 'Sin teléfono'),
            ] else 
              const Text("Información del perfil no disponible", style: TextStyle(color: Colors.grey)),

            // 3. MUEBLES (ITEMS)
            const SizedBox(height: 25),
            const _SectionTitle("Muebles a Limpiar"),
            ..._items.map((item) {
                final attrs = item['attributes'] ?? {};
                return Card(
                  color: const Color(0xFF2C2C2C),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      "${item['quantity']}x ${item['item_name']}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text(
                      "Tam: ${attrs['size']} | Mat: ${attrs['material']} | Suc: ${attrs['dirt_level']}",
                      style: const TextStyle(color: Colors.grey)
                    ),
                  ),
                );
            }),

            // 4. EVIDENCIA FOTOGRÁFICA
            const SizedBox(height: 25),
            const _SectionTitle("Evidencia (Fotos)"),
            if (_evidence.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidence.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _evidence[index]['photo_url'], 
                          width: 120, 
                          height: 120, 
                          fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Container(width: 120, color: Colors.grey, child: const Icon(Icons.broken_image)),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text("El cliente no subió fotos.", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 40),

            // 5. COTIZACIÓN FINAL (INPUT)
            const _SectionTitle("Definir Costo Final"),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: "\$ ",
                prefixStyle: TextStyle(color: Colors.green, fontSize: 24),
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // BOTÓN DE ACCIÓN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendQuoteToClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR COTIZACIÓN AL CLIENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _InfoRow(this.icon, this.color, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.grey))]))]);
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: Colors.blueGrey, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)))]));
}