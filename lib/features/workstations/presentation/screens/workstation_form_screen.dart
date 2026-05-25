import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

enum _RoiPreset {
  centerDesk(
    'Puesto centrado',
    'Pensado para una persona sentada frente a la camara.',
    WorkstationRoi(x: 0.20, y: 0.15, width: 0.60, height: 0.70),
  ),
  wideDesk(
    'Puesto amplio',
    'Ideal cuando la camara esta mas lejos o el encuadre es abierto.',
    WorkstationRoi(x: 0.12, y: 0.12, width: 0.76, height: 0.76),
  ),
  preciseDesk(
    'Puesto preciso',
    'Mas estricto para reducir interferencias de personas cercanas.',
    WorkstationRoi(x: 0.28, y: 0.18, width: 0.44, height: 0.64),
  );

  final String label;
  final String description;
  final WorkstationRoi roi;

  const _RoiPreset(this.label, this.description, this.roi);
}

class WorkstationFormScreen extends ConsumerStatefulWidget {
  final String? workstationId;
  const WorkstationFormScreen({super.key, this.workstationId});

  @override
  ConsumerState<WorkstationFormScreen> createState() =>
      _WorkstationFormScreenState();
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
  bool _isLoadingData = false;
  String? _selectedEmployeeId;
  _RoiPreset _selectedRoiPreset = _RoiPreset.centerDesk;
  String? _editingId;

  bool get _isEditing => widget.workstationId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingWorkstation();
    } else {
      _deviceIdController.text = const Uuid().v4();
    }
  }

  Future<void> _loadExistingWorkstation() async {
    setState(() => _isLoadingData = true);
    try {
      final workstations = await ref.read(workstationsProvider.future);
      final ws = workstations.where((w) => w.id == widget.workstationId).firstOrNull;
      if (ws != null && mounted) {
        setState(() {
          _editingId = ws.id;
          _nameController.text = ws.name;
          _deviceIdController.text = ws.deviceId ?? '';
          _latitude = ws.latitude;
          _longitude = ws.longitude;
          _geofenceRadius = ws.geofenceRadius ?? 100.0;
          _selectedEmployeeId = ws.assignedEmployeeId;
          if (ws.roi != null) {
            _selectedRoiPreset = _RoiPreset.values.firstWhere(
              (p) => p.roi.x == ws.roi!.x && p.roi.y == ws.roi!.y,
              orElse: () => _RoiPreset.centerDesk,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicacion estan deshabilitados.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicacion fueron denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Los permisos de ubicacion estan denegados permanentemente.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.locationSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes asignar el propietario de la workstation.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    final companyId = currentUser?.companyId ?? AppConstants.defaultCompanyId;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);

    try {
      final workstation = Workstation(
        id: _editingId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        companyId: companyId,
        deviceId: _deviceIdController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        geofenceRadius: _geofenceRadius,
        assignedEmployeeId: _selectedEmployeeId,
        roi: _selectedRoiPreset.roi,
      );

      await ref.read(saveWorkstationUseCaseProvider)(workstation);

      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Estación actualizada correctamente'
              : AppStrings.workstationSaved),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildEmployeeSelector() {
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
            child: Text(
              AppStrings.noEmployeesRegistered,
              style: const TextStyle(
                color: AppColors.orangeWarning,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedEmployeeId,
          decoration: const InputDecoration(
            labelText: 'Empleado propietario',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: employees
              .map(
                (employee) => DropdownMenuItem<String>(
                  value: employee.id,
                  child: Text(employee.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedEmployeeId = value);
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error al cargar empleados: $err'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar estación' : AppStrings.newWorkstation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        child: AppContentConstrainer(
          width: AppContentWidth.form,
          center: false,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.workstationNameLabel,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppStrings.workstationNameRequired
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                TextFormField(
                  controller: _deviceIdController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.deviceIdLabel,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppStrings.deviceIdRequired
                      : null,
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildEmployeeSelector(),
                const SizedBox(height: AppDimensions.spacing24),
                _buildGeolocationSection(),
                const SizedBox(height: AppDimensions.spacing24),
                _buildGeofenceSection(),
                const SizedBox(height: AppDimensions.spacing24),
                _buildRoiSection(),
                const SizedBox(height: AppDimensions.spacing32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeolocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.geolocation,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontTitle),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        OutlinedButton.icon(
          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          icon: _isLoadingLocation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_on),
          label: const Text(AppStrings.useCurrentLocation),
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Ubicacion: $_latitude, $_longitude',
            style: const TextStyle(color: AppColors.success),
          ),
        ],
      ],
    );
  }

  Widget _buildGeofenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildRoiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zona de deteccion del puesto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontTitle),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          _selectedRoiPreset.description,
          style: TextStyle(color: context.appOnSurfaceSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        DropdownButtonFormField<_RoiPreset>(
          initialValue: _selectedRoiPreset,
          decoration: const InputDecoration(
            labelText: 'Preset de encuadre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.crop_free),
          ),
          items: _RoiPreset.values
              .map(
                (preset) => DropdownMenuItem<_RoiPreset>(
                  value: preset,
                  child: Text(preset.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedRoiPreset = value);
          },
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            'Se aplicara automaticamente el preset "${_selectedRoiPreset.label}" '
            'para concentrar la deteccion continua en la zona util del puesto.',
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSaving ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: AppColors.white),
            )
          : const Text(
              'Guardar estación',
              style: TextStyle(fontSize: AppDimensions.fontTitle),
            ),
    );
  }
}