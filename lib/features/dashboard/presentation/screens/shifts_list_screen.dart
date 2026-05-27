import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class ShiftsListScreen extends ConsumerWidget {
  const ShiftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final ac = context.appColors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ac.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: ac.surface,
        onRefresh: () async => ref.invalidate(shiftsProvider),
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _ShiftsHeader(l10n: l10n)),

            // ── Content ───────────────────────────────────────────────────
            shiftsAsync.when(
              loading: () => const SliverFillRemaining(
                child: AppLoadingWidget(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(message: e.toString()),
              ),
              data: (shifts) {
                if (shifts.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyShiftsView(l10n: l10n),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ShiftCard(
                      shift: shifts[index],
                      index: index,
                      onEdit: () => context.push(
                        AppRoutes.shiftEdit.replaceFirst(':shiftId', shifts[index].id),
                      ),
                      onDelete: () => _confirmDelete(context, ref, shifts[index], l10n),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────
      floatingActionButton: _AddShiftFab(
        onTap: () => context.push(AppRoutes.shiftNew),
        label: l10n.newShift,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Shift shift,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteShift),
        content: Text('¿Eliminar "${shift.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deleteShiftUseCaseProvider).call(shift.id);
      ref.invalidate(shiftsProvider);
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ShiftsHeader extends StatelessWidget {
  final AppLocalizations l10n;
  const _ShiftsHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            context.appColors.background,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workShifts.toUpperCase(),
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.workShifts,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift Card ────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  final Shift shift;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftCard({
    required this.shift,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int get _durationMinutes {
    int start = shift.startTime.hour * 60 + shift.startTime.minute;
    int end   = shift.endTime.hour * 60 + shift.endTime.minute;
    if (end < start) end += 24 * 60; // overnight
    int duration = end - start;
    if (shift.hasBreak && shift.breakStartTime != null && shift.breakEndTime != null) {
      final bs = shift.breakStartTime!.hour * 60 + shift.breakStartTime!.minute;
      final be = shift.breakEndTime!.hour * 60 + shift.breakEndTime!.minute;
      duration -= (be - bs).abs();
    }
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final h = _durationMinutes ~/ 60;
    final m = _durationMinutes % 60;
    final durLabel = m == 0 ? '${h}h' : '${h}h ${m}m';

    // Accent color cycles through palette
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
    ];
    final accent = colors[index % colors.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: ac.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder, width: 0.8),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Accent bar ─────────────────────────────────────────
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withValues(alpha: 0.5)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + badge
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.schedule_rounded,
                                color: accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                shift.name,
                                style: TextStyle(
                                  color: ac.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Duration chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                durLabel,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Time range ──────────────────────────────
                        _TimeRow(
                          icon: Icons.login_rounded,
                          label: 'Entrada',
                          value: _fmt(shift.startTime),
                          color: AppColors.success,
                          ac: ac,
                        ),
                        const SizedBox(height: 6),
                        _TimeRow(
                          icon: Icons.logout_rounded,
                          label: 'Salida',
                          value: _fmt(shift.endTime),
                          color: AppColors.error,
                          ac: ac,
                        ),

                        // ── Break ────────────────────────────────────
                        if (shift.hasBreak &&
                            shift.breakStartTime != null &&
                            shift.breakEndTime != null) ...[
                          const SizedBox(height: 6),
                          _TimeRow(
                            icon: Icons.free_breakfast_rounded,
                            label: 'Receso',
                            value:
                                '${_fmt(shift.breakStartTime!)} – ${_fmt(shift.breakEndTime!)}',
                            color: AppColors.warning,
                            ac: ac,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Actions ────────────────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      onTap: onEdit,
                    ),
                    const SizedBox(height: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final AppThemeColors ac;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _AddShiftFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _AddShiftFab({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyShiftsView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyShiftsView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return SingleChildScrollView(
      // SingleChildScrollView makes RefreshIndicator work in empty state
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noShiftsRegistered,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                l10n.noShiftsHint,
                style: TextStyle(color: ac.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $message',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
