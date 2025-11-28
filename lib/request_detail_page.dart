import 'package:flutter/material.dart';
import 'package:mubclean_admin/main.dart';

class RequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const RequestDetailPage({super.key, required this.booking});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final _priceController = TextEditingController();
  bool _isLoading = false;
  
  Map<String, dynamic>? _clientData;
  List<Map<String, dynamic>> _technicians = []; 
  String? _selectedTechId;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    if (widget.booking['price'] != null) {
      _priceController.text = widget.booking['price'].toString();
    }
    if (widget.booking['technician_id'] != null) {
        _selectedTechId = widget.booking['technician_id'].toString(); 
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadClientData(),
      _loadTechnicians(),
    ]);
  }

  Future<void> _loadClientData() async {
    try {
      final userId = widget.booking['user_id'];
      final data = await supabase
          .from('profiles')
          .select('full_name, phone, email')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _clientData = data);
    } catch (e) {
      debugPrint('Error cliente: $e');
    }
  }

  Future<void> _loadTechnicians() async {
    try {
      // Buscamos técnicos disponibles
      final data = await supabase
          .from('technicians')
          .select('id, full_name')
          .eq('is_available', true)
          .order('full_name', ascending: true);
      
      if (mounted) setState(() => _technicians = data);
    } catch (e) {
      debugPrint('Error técnicos: $e');
    }
  }

  // --- FUNCIÓN 1: COTIZAR Y ASIGNAR (BLOQUEA AL TÉCNICO) ---
  Future<void> _sendQuoteAndAssign() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta precio")));
      return;
    }
    if (_selectedTechId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta técnico")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Actualizar Reserva
      await supabase.from('bookings').update({
        'price': double.parse(_priceController.text),
        'status': 'quoted', 
        'technician_id': _selectedTechId, 
      }).eq('id', widget.booking['id']);

      // 2. Bloquear al Técnico (Ocuparlo)
      await supabase.from('technicians').update({
        'is_available': false
      }).eq('id', _selectedTechId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Asignado y Cotizado!"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN 2: FINALIZAR SERVICIO (LIBERA AL TÉCNICO) ---
  Future<void> _finishService() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('bookings').update({
        'status': 'done', 
      }).eq('id', widget.booking['id']);

      // Liberar al técnico
      if (widget.booking['technician_id'] != null) {
        await supabase.from('technicians').update({
          'is_available': true
        }).eq('id', widget.booking['technician_id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Servicio Finalizado"), backgroundColor: Colors.blue));
        Navigator.pop(context);
      }
    } catch (e) {
       // Error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'];
    final isPending = status == 'pending';
    final isQuoted = status == 'quoted';
    final isScheduled = status == 'scheduled';
    final isDone = status == 'done';

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
            
            // 1. SERVICIO
            const _SectionTitle("Servicio y Ubicación"),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _InfoRow(
                    Icons.cleaning_services, 
                    Colors.orange, 
                    widget.booking['service_type'] ?? 'Servicio', 
                    widget.booking['details'] ?? 'Sin detalles'
                  ),
                  const Divider(color: Colors.grey, height: 30),
                  _InfoRow(
                    Icons.location_on, 
                    Colors.redAccent, 
                    "Dirección", 
                    widget.booking['address'] ?? 'No especificada'
                  ),
                ],
              ),
            ),

            // --- AQUÍ ESTÁN LAS FOTOS RECUPERADAS ---
            const SizedBox(height: 20),
            const Text("Evidencia Fotográfica:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                _PhotoBox(), // Foto 1
                const SizedBox(width: 10),
                _PhotoBox(isPlus: true), // Foto 2 con indicador
              ],
            ),
            // -----------------------------------------

            const SizedBox(height: 25),
            
            // 2. ASIGNACIÓN
            const _SectionTitle("Asignar Técnico"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Seleccionar Técnico',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.person_search, color: Colors.white),
                ),
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                value: _selectedTechId,
                items: _technicians.map((tech) {
                  return DropdownMenuItem(
                    value: tech['id'].toString(),
                    child: Text(tech['full_name'] ?? 'Sin Nombre'),
                  );
                }).toList(),
                // Solo permite cambiar si está pendiente
                onChanged: isPending ? (v) => setState(() => _selectedTechId = v) : null,
              ),
            ),

            const SizedBox(height: 30),
            
            // 3. CLIENTE
            const _SectionTitle("Datos del Cliente"),
            if (_clientData == null)
               const LinearProgressIndicator(color: Colors.blueGrey)
            else ...[
              _InfoTile(Icons.person, _clientData!['full_name'] ?? 'Anónimo'),
              _InfoTile(Icons.phone, _clientData!['phone'] ?? 'Sin teléfono'),
              _InfoTile(Icons.email, _clientData!['email'] ?? '-'),
            ],

            const SizedBox(height: 30),

            // 4. ACCIONES (BOTONES DINÁMICOS)
            const _SectionTitle("Estatus y Acciones"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey),
              ),
              child: Column(
                children: [
                  if (!isDone)
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      enabled: isPending, // Solo editable al principio
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        prefixText: "\$ ", prefixStyle: TextStyle(color: Colors.green, fontSize: 24),
                        hintText: "0.00", hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  
                  const Divider(color: Colors.grey),
                  
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(status),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String? status) {
    if (status == 'pending') {
      return ElevatedButton(
        onPressed: _isLoading ? null : _sendQuoteAndAssign,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR Y ASIGNAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (status == 'quoted') {
      return const ElevatedButton(
        onPressed: null, 
        child: Text("ESPERANDO PAGO DEL CLIENTE", style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'scheduled') {
      return ElevatedButton(
        onPressed: () => _updateStatus('done'), // Para probar finalizar
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        child: const Text("FINALIZAR SERVICIO (Liberar Técnico)", style: TextStyle(color: Colors.white)),
      );
    } else {
      return const Text("SERVICIO COMPLETADO ✅", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
     // ... (Implementación simplificada para el botón de finalizar)
     _finishService();
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

class _PhotoBox extends StatelessWidget {
  final bool isPlus;
  const _PhotoBox({this.isPlus = false});
  @override
  Widget build(BuildContext context) => Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: Center(child: isPlus ? const Text("+2", style: TextStyle(color: Colors.white)) : const Icon(Icons.image, color: Colors.white54)));
}