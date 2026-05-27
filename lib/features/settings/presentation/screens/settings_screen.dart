import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/locale_provider.dart';
import 'package:worksense_app/shared/providers/theme_provider.dart';

// ── Analysis interval provider ────────────────────────────────────────────────

final analysisIntervalProvider =
    AsyncNotifierProvider<AnalysisIntervalNotifier, int>(() {
  return AnalysisIntervalNotifier();
});

class AnalysisIntervalNotifier extends AsyncNotifier<int> {
  static const _key = 'analysis_interval_seconds';

  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key);
    return stored ?? AiThresholds.defaultAnalysisIntervalSeconds;
  }

  Future<void> setInterval(int seconds) async {
    state = AsyncData(seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, seconds);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final l10n     = AppLocalizations.of(context);
    final analysisIntervalAsync = ref.watch(analysisIntervalProvider);
    final userEmail = ref.watch(currentUserEmailProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;
    final locale    = ref.watch(localeProvider).valueOrNull ?? const Locale('es');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // ── Account section ─────────────────────────────────────
          _SectionHeader(title: l10n.accountSection),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.user),
            subtitle: Text(userEmail ?? l10n.notAvailable),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text(l10n.myProfile),
            subtitle: Text(
              l10n.myProfileSubtitle,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(AppRoutes.profile),
          ),

          const Divider(),

          // ── Appearance section ───────────────────────────────────
          _SectionHeader(title: l10n.appearance),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Theme toggle ──────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.dark_mode_outlined, size: 18,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(l10n.themeMode,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode, size: 16),
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode, size: 16),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.settings_suggest, size: 16),
                      label: Text(l10n.themeSystem),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).setMode(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Language toggle ───────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.language_outlined, size: 18,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(l10n.language,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment(
                      value: const Locale('es'),
                      icon: const Text('🇪🇸', style: TextStyle(fontSize: 14)),
                      label: Text(l10n.langSpanish),
                    ),
                    ButtonSegment(
                      value: const Locale('en'),
                      icon: const Text('🇺🇸', style: TextStyle(fontSize: 14)),
                      label: Text(l10n.langEnglish),
                    ),
                  ],
                  selected: {locale},
                  onSelectionChanged: (s) =>
                      ref.read(localeProvider.notifier).setLocale(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── AI Pipeline section ──────────────────────────────────
          _SectionHeader(title: l10n.activityAnalysis),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: analysisIntervalAsync.when(
              data: (analysisInterval) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.analysisInterval,
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
                    l10n.analysisIntervalDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const Divider(),

          // ── Thresholds info ──────────────────────────────────────
          _SectionHeader(title: l10n.detectionThresholds),
          _ThresholdTile(
            label: l10n.maxYawLabel,
            value: '${AiThresholds.maxYawAngle}°',
          ),
          _ThresholdTile(
            label: l10n.minPitchLabel,
            value: '${AiThresholds.minPitchAngle}°',
          ),
          _ThresholdTile(
            label: l10n.maxRollLabel,
            value: '${AiThresholds.maxRollAngle}°',
          ),
          _ThresholdTile(
            label: l10n.minPoseConfidenceLabel,
            value: '${(AiThresholds.minPoseConfidence * 100).toInt()}%',
          ),
          _ThresholdTile(
            label: l10n.inactivityThresholdLabel,
            value: '${AiThresholds.inactivityThresholdSeconds} seg',
          ),

          const Divider(),

          // ── App info ─────────────────────────────────────────────
          _SectionHeader(title: l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            trailing: Text(
              AppConstants.appVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: Text(l10n.application),
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
              label: Text(
                l10n.logout,
                style: const TextStyle(color: AppColors.error),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(loginNotifierProvider.notifier).signOut();
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
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
