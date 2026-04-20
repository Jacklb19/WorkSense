import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // ── Account section ─────────────────────────────────────
          _SectionHeader(title: AppStrings.accountSection),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text(AppStrings.user),
            subtitle: Text(userEmail ?? AppStrings.notAvailable),
          ),

          const Divider(),

          // ── AI Pipeline section ──────────────────────────────────
          _SectionHeader(title: AppStrings.activityAnalysis),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                Slider(
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
                Text(
                  'Frecuencia con la que se analiza la actividad del trabajador. '
                  'Valores menores son más precisos pero consumen más batería.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          const Divider(),

          // ── Thresholds info ──────────────────────────────────────
          _SectionHeader(title: AppStrings.detectionThresholds),
          _ThresholdTile(
            label: AppStrings.maxYawLabel,
            value: '${AiThresholds.maxYawAngle}°',
          ),
          _ThresholdTile(
            label: AppStrings.minPitchLabel,
            value: '${AiThresholds.minPitchAngle}°',
          ),
          _ThresholdTile(
            label: AppStrings.maxRollLabel,
            value: '${AiThresholds.maxRollAngle}°',
          ),
          _ThresholdTile(
            label: AppStrings.minPoseConfidenceLabel,
            value: '${(AiThresholds.minPoseConfidence * 100).toInt()}%',
          ),
          _ThresholdTile(
            label: AppStrings.inactivityThresholdLabel,
            value: '${AiThresholds.inactivityThresholdSeconds} seg',
          ),

          const Divider(),

          // ── App info ─────────────────────────────────────────────
          _SectionHeader(title: AppStrings.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppStrings.version),
            trailing: Text(
              AppConstants.appVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text(AppStrings.application),
            trailing: Text(
              AppConstants.appName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),

          const Divider(),

          // ── Logout ───────────────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                AppStrings.logout,
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThresholdTile extends StatelessWidget {
  final String label;
  final String value;

  const _ThresholdTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.grey600,
        ),
      ),
    );
  }
}
