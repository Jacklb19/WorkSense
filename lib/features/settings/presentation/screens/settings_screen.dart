import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/primary_button.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

// Settings provider using shared_preferences
final analysisIntervalProvider =
    StateNotifierProvider<AnalysisIntervalNotifier, int>((ref) {
  return AnalysisIntervalNotifier();
});

class AnalysisIntervalNotifier extends StateNotifier<int> {
  static const _key = 'analysis_interval_seconds';

  AnalysisIntervalNotifier()
      : super(AiThresholds.defaultAnalysisIntervalSeconds) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key);
    if (stored != null) {
      state = stored;
    }
  }

  Future<void> setInterval(int seconds) async {
    state = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, seconds);
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisInterval = ref.watch(analysisIntervalProvider);
    final userEmail = ref.watch(currentUserEmailProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // ── Header ──────────────────────────────────
          Text('Settings', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxl),

          // ── Account Section ─────────────────────────
          _SectionHeader(title: AppStrings.accountSection),
          const SizedBox(height: AppSpacing.sm),
          WsCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (userEmail ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.user,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userEmail ?? AppStrings.notAvailable,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Activity Analysis Section ────────────────
          _SectionHeader(title: AppStrings.activityAnalysis),
          const SizedBox(height: AppSpacing.sm),
          WsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.analysisInterval,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '$analysisInterval seg',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.borderColor,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: analysisInterval.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    label: '$analysisInterval seg',
                    onChanged: (value) {
                      ref
                          .read(analysisIntervalProvider.notifier)
                          .setInterval(value.round());
                    },
                  ),
                ),
                Text(
                  'Frecuencia con la que se analiza la actividad del trabajador. '
                  'Valores menores son más precisos pero consumen más batería.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Detection Thresholds ────────────────────
          _SectionHeader(title: AppStrings.detectionThresholds),
          const SizedBox(height: AppSpacing.sm),
          WsCard(
            child: Column(
              children: [
                _ThresholdRow(
                  label: AppStrings.maxYawLabel,
                  value: '${AiThresholds.maxYawAngle}°',
                ),
                _ThresholdRow(
                  label: AppStrings.minPitchLabel,
                  value: '${AiThresholds.minPitchAngle}°',
                ),
                _ThresholdRow(
                  label: AppStrings.maxRollLabel,
                  value: '${AiThresholds.maxRollAngle}°',
                ),
                _ThresholdRow(
                  label: AppStrings.minPoseConfidenceLabel,
                  value: '${(AiThresholds.minPoseConfidence * 100).toInt()}%',
                ),
                _ThresholdRow(
                  label: AppStrings.inactivityThresholdLabel,
                  value: '${AiThresholds.inactivityThresholdSeconds} seg',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── App Info ────────────────────────────────
          _SectionHeader(title: AppStrings.about),
          const SizedBox(height: AppSpacing.sm),
          WsCard(
            child: Column(
              children: [
                _ThresholdRow(
                  label: AppStrings.version,
                  value: AppConstants.appVersion,
                ),
                _ThresholdRow(
                  label: AppStrings.application,
                  value: AppConstants.appName,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Logout ──────────────────────────────────
          PrimaryButton(
            label: AppStrings.logout,
            backgroundColor: AppColors.dangerCardBg,
            foregroundColor: AppColors.dangerCardFg,
            onTap: () => _handleLogout(context, ref),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(loginNotifierProvider.notifier).signOut();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ThresholdRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderColor, width: 0.5),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
