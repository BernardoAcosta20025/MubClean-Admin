import 'package:flutter/material.dart';
import 'package:mubclean_admin/main.dart'; // Import for supabase

// Modelo simple para representar a un técnico.
class Technician {
  final String id;
  final String fullName;

  Technician({required this.id, required this.fullName});
}

class AssignTechnicianPage extends StatefulWidget {
  final String bookingId; // ID de la reserva a la que se asignará el técnico

  const AssignTechnicianPage({super.key, required this.bookingId});

  @override
  State<AssignTechnicianPage> createState() => _AssignTechnicianPageState();
}

class _AssignTechnicianPageState extends State<AssignTechnicianPage> {
  final _formKey = GlobalKey<FormState>();
  Technician? _selectedTechnician;
  bool _isLoading = false;

  // Lista de técnicos simulada. Deberías reemplazar esto con una llamada a tu API.
  // Por ejemplo, podrías buscar perfiles con el rol 'technician'.
  final List<Technician> _availableTechnicians = [
    Technician(id: 'tech_001', fullName: 'Juan Pérez'),
    Technician(id: 'tech_002', fullName: 'Maria Rodriguez'),
    Technician(id: 'tech_003', fullName: 'Carlos Gomez'),
    Technician(id: 'tech_004', fullName: 'Ana Torres'),
  ];

  @override
  void initState() {
    super.initState();
    // Aquí podrías llamar a una función para cargar los técnicos desde Supabase
    // _loadTechnicians();
  }

  /*
  // Ejemplo de cómo cargarías los técnicos desde Supabase
  Future<void> _loadTechnicians() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'technician');
      
      if (mounted) {
        setState(() {
          _availableTechnicians = (data as List)
              .map((item) => Technician(id: item['id'], fullName: item['full_name']))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando técnicos: $e');
    }
  }
  */

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await supabase.from('bookings').update({
          'technician_id': _selectedTechnician!.id,
          'status': 'assigned', // Cambiamos el estado a "Asignado"
        }).eq('id', widget.bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Técnico asignado correctamente!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volver a la página de detalle
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al asignar técnico: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Técnico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Menú desplegable para seleccionar el técnico
              DropdownButtonFormField<Technician>(
                value: _selectedTechnician,
                decoration: const InputDecoration(
                  labelText: 'Técnico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                hint: const Text('Seleccione un técnico disponible'),
                isExpanded: true,
                items: _availableTechnicians.map((Technician technician) {
                  return DropdownMenuItem<Technician>(
                    value: technician,
                    child: Text(technician.fullName),
                  );
                }).toList(),
                onChanged: (Technician? newValue) {
                  setState(() {
                    _selectedTechnician = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, seleccione un técnico.';
                  }
                  return null; // La validación pasó
                },
              ),
              const SizedBox(height: 32),

              // Botón para enviar el formulario
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar Asignación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
