import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';

class WorkstationFormScreen extends ConsumerStatefulWidget {
  const WorkstationFormScreen({super.key});

  @override
  ConsumerState<WorkstationFormScreen> createState() => _WorkstationFormScreenState();
}

class _WorkstationFormScreenState extends ConsumerState<WorkstationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  
  double? _latitude;
  double? _longitude;
  double _geofenceRadius = 100.0;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    // Pre-llenar deviceId con UUID para fines del form (se puede adaptar si hay plugin info)
    _deviceIdController.text = const Uuid().v4();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están denegados permanentemente.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación obtenida con éxito.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // As in employees_provider, default to "default" if no companyId in session.
    final companyId = 'default';

    setState(() => _isSaving = true);

    try {
      final newWorkstation = Workstation(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        companyId: companyId,
        deviceId: _deviceIdController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        geofenceRadius: _geofenceRadius,
        assignedEmployeeId: _selectedEmployeeId,
      );

      await ref.read(saveWorkstationUseCaseProvider)(newWorkstation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estación guardada exitosamente'), backgroundColor: AppColors.success),
        );
        context.go('/workstations');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildEmployeeSelector() {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No hay empleados registrados',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedEmployeeId,
          decoration: const InputDecoration(
            labelText: 'Asignar Empleado (Opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Ninguno'),
            ),
            ...employees.map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedEmployeeId = value;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error al cargar empleados: $err'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Estación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del puesto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                  value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'ID del dispositivo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                  value == null || value.trim().isEmpty ? 'El ID no puede estar vacío' : null,
              ),
              const SizedBox(height: 16),
              _buildEmployeeSelector(),
              const SizedBox(height: 24),
              const Text(
                'Geolocalización',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.location_on),
                label: const Text('Usar mi ubicación actual'),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text('Ubicación: $_latitude, $_longitude', style: const TextStyle(color: AppColors.success)),
              ],
              const SizedBox(height: 24),
              Text(
                'Radio de geovalla: ${_geofenceRadius.toInt()} m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _geofenceRadius,
                min: 50.0,
                max: 500.0,
                divisions: 9,
                activeColor: AppColors.primary,
                label: '${_geofenceRadius.toInt()}m',
                onChanged: (value) {
                  setState(() => _geofenceRadius = value);
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white))
                  : const Text('Guardar Estación', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
