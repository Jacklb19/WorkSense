import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: workstations para el kiosko
//
// Bug fix: workstationsStreamProvider solo lee la BD local (Drift).
// Si el dispositivo nunca sincronizó, retorna [] aunque Supabase tenga datos.
// Este provider hace fallback a Supabase cuando la BD local está vacía
// y guarda los resultados localmente para futuras consultas.
// ─────────────────────────────────────────────────────────────────────────────
final kioskWorkstationsProvider =
    StreamProvider.autoDispose<List<WorkstationRecord>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  // 1. Obtener companyId — intentar desde currentUserProvider primero
  String? companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;

  // 2. Si no está listo, esperar al valor resuelto
  if (companyId == null || companyId.isEmpty) {
    try {
      final user = await ref.watch(currentUserProvider.future);
      companyId = user.companyId;
    } catch (_) {}
  }

  // 3. Último recurso: metadata del token JWT
  if (companyId == null || companyId.isEmpty) {
    final authUser = Supabase.instance.client.auth.currentUser;
    companyId = authUser?.appMetadata['company_id']?.toString() ??
        authUser?.userMetadata?['company_id']?.toString();
  }

  if (companyId == null || companyId.isEmpty) {
    yield [];
    return;
  }

  final cid = companyId;

  // 4. Verificar BD local
  final local = await db.getWorkstationRecordsByCompany(cid);

  // 5. Fallback a Supabase si la BD local está vacía
  if (local.isEmpty) {
    try {
      debugPrint('[KioskWaiting] BD local vacía. Descargando workstations de Supabase...');
      final response = await Supabase.instance.client
          .from('workstations')
          .select('id, name, company_id, device_id, assigned_employee_id, status')
          .eq('company_id', cid);

      final remoteList = List<Map<String, dynamic>>.from(response as List);
      debugPrint('[KioskWaiting] Recibidas ${remoteList.length} workstations.');

      for (final w in remoteList) {
        try {
          await db.insertWorkstationRecord(
            WorkstationRecordsCompanion(
              id: drift.Value(w['id'] as String),
              name: drift.Value((w['name'] as String?) ?? 'Sin nombre'),
              companyId: drift.Value(w['company_id'] as String),
              deviceId: drift.Value(w['device_id'] as String?),
              assignedEmployeeId:
                  drift.Value(w['assigned_employee_id'] as String?),
              status: drift.Value((w['status'] as String?) ?? 'IDLE'),
            ),
          );
        } catch (e) {
          debugPrint('[KioskWaiting] Error guardando workstation ${w['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('[KioskWaiting] Error descargando de Supabase: $e');
    }
  }

  // 6. Stream en tiempo real desde la BD local (ya poblada)
  yield* db.watchWorkstationRecordsByCompany(cid);
});

// ─────────────────────────────────────────────────────────────────────────────
// KioskWaitingScreen
// ─────────────────────────────────────────────────────────────────────────────
class KioskWaitingScreen extends ConsumerWidget {
  const KioskWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(kioskWorkstationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────────────────────────
          const _BackgroundBlobs(),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                const _TopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero icon
                        const _HeroSection(),

                        const SizedBox(height: 40),

                        // ── Kiosko de entrada ─────────────────────────────
                        const _SectionLabel(label: 'ACCESO BIOMÉTRICO'),
                        const SizedBox(height: 12),
                        _EntranceButton(
                          onTap: () => context.push(AppRoutes.entrance),
                        ),

                        const SizedBox(height: 32),

                        // ── Monitor de puesto ─────────────────────────────
                        const _SectionLabel(label: 'MONITOR DE PUESTO'),
                        const SizedBox(height: 12),
                        _WorkstationSelector(
                          workstationsAsync: workstationsAsync,
                          onSelect: (id) => context.push('/kiosk/$id'),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Logout
                _LogoutButton(
                  onTap: () =>
                      ref.read(loginNotifierProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Background
// ═══════════════════════════════════════════════════════════════════════════════

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.primary.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accent.withValues(alpha: 0.14),
                AppColors.accent.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Top bar
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.70),
            border: const Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 0.6),
            ),
          ),
          child: Row(
            children: [
              // Brand
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.accentLight],
                ).createShader(b),
                child: const Text(
                  'WORKSENSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'EN LÍNEA',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Hero section
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Icon ring
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.40),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.settings_input_antenna_rounded,
                  color: Colors.white, size: 44),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scaleXY(begin: 0.85, end: 1.0, curve: Curves.easeOutBack),

        const SizedBox(height: 20),

        const Text(
          'CONFIGURAR DISPOSITIVO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

        const SizedBox(height: 8),
        const Text(
          'Selecciona la función que este dispositivo\ncumplirá en la oficina.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textOnCamera60, fontSize: 13, height: 1.5),
        ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section label
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Entrance button
// ═══════════════════════════════════════════════════════════════════════════════

class _EntranceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EntranceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.face_retouching_natural,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiosco de Entrada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Reconocimiento facial · Fichaje automático',
                        style: TextStyle(
                          color: AppColors.textOnCamera60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary, size: 16),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Workstation selector
// ═══════════════════════════════════════════════════════════════════════════════

class _WorkstationSelector extends StatelessWidget {
  final AsyncValue<List<WorkstationRecord>> workstationsAsync;
  final ValueChanged<String> onSelect;

  const _WorkstationSelector({
    required this.workstationsAsync,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return workstationsAsync.when(
      loading: () => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Text(
                  'Cargando puestos de trabajo...',
                  style: TextStyle(
                      color: AppColors.textOnCamera60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),

      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Error al cargar: $e',
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ),
          ],
        ),
      ),

      data: (workstations) {
        if (workstations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.computer_outlined,
                    color: AppColors.grey600, size: 32),
                SizedBox(height: 10),
                Text(
                  'Sin puestos de trabajo creados',
                  style: TextStyle(
                      color: AppColors.textOnCamera60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  'Crea estaciones desde el panel de administración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textOnCamera38, fontSize: 11),
                ),
              ],
            ),
          );
        }

        return Column(
          children: workstations
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < workstations.length - 1 ? 10 : 0),
                  child: _WorkstationTile(
                    workstation: e.value,
                    onTap: () => onSelect(e.value.id),
                  ).animate(delay: (e.key * 60).ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.2, end: 0),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ── Workstation tile ──────────────────────────────────────────────────────────

class _WorkstationTile extends StatelessWidget {
  final WorkstationRecord workstation;
  final VoidCallback onTap;

  const _WorkstationTile({required this.workstation, required this.onTap});

  Color get _statusColor {
    switch (workstation.status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'BREAK':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  String get _statusLabel {
    switch (workstation.status.toUpperCase()) {
      case 'ACTIVE':
        return 'Activa';
      case 'BREAK':
        return 'En pausa';
      default:
        return 'Libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.glassBorder, width: 0.8),
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color: _statusColor.withValues(alpha: 0.28)),
                  ),
                  child: Icon(Icons.computer_rounded,
                      color: _statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workstation.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.grey600, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Logout button
// ═══════════════════════════════════════════════════════════════════════════════

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: AppColors.textOnCamera38, size: 16),
              SizedBox(width: 8),
              Text(
                'CERRAR SESIÓN DEL DISPOSITIVO',
                style: TextStyle(
                  color: AppColors.textOnCamera38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
