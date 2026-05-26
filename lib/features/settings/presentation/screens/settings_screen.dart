import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final analysisIntervalAsync = ref.watch(analysisIntervalProvider);
    final userEmail = ref.watch(currentUserEmailProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.dark;
    final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('es');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _buildAccountSection(l10n, userEmail),
          const Divider(),
          _buildAppearanceSection(l10n, theme, themeMode, locale),
          const Divider(),
          _buildAIPipelineSection(analysisIntervalAsync, l10n, theme),
          const Divider(),
          _buildThresholdsSection(l10n),
          const Divider(),
          _buildAppInfoSection(l10n, theme),
          const Divider(),
          _buildLogoutButton(l10n),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n, String? userEmail) {
    return Column(
      children: [
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
            style: const TextStyle(fontSize: AppDimensions.fontCaption),
          ),
          trailing: const Icon(Icons.chevron_right, size: AppDimensions.spacing20),
          onTap: () => context.push(AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
    AppLocalizations l10n,
    ThemeData theme,
    ThemeMode themeMode,
    Locale locale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.appearance),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXs, AppDimensions.spacingXxl, AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 18,
                      color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(l10n.themeMode,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
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
              const SizedBox(height: AppDimensions.spacing20),
              Row(
                children: [
                  const Icon(Icons.language_outlined, size: 18,
                      color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(l10n.language,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              SegmentedButton<Locale>(
                segments: [
                  ButtonSegment(
                    value: const Locale('es'),
                    icon: const Text('🇪🇸',
                        style: TextStyle(fontSize: AppDimensions.fontBodyMd)),
                    label: Text(l10n.langSpanish),
                  ),
                  ButtonSegment(
                    value: const Locale('en'),
                    icon: const Text('🇺🇸',
                        style: TextStyle(fontSize: AppDimensions.fontBodyMd)),
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
      ],
    );
  }

  Widget _buildAIPipelineSection(
    AsyncValue<int> analysisIntervalAsync,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.activityAnalysis),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
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
                const SizedBox(height: AppDimensions.spacingXxl),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingXxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdsSection(AppLocalizations l10n) {
    return Column(
      children: [
        _SectionHeader(title: l10n.detectionThresholds),
        const _ThresholdTile(
          label: AppStrings.maxYawLabel,
          value: '${AiThresholds.maxYawAngle}°',
        ),
        const _ThresholdTile(
          label: AppStrings.minPitchLabel,
          value: '${AiThresholds.minPitchAngle}°',
        ),
        const _ThresholdTile(
          label: AppStrings.maxRollLabel,
          value: '${AiThresholds.maxRollAngle}°',
        ),
        _ThresholdTile(
          label: AppStrings.minPoseConfidenceLabel,
          value: '${(AiThresholds.minPoseConfidence * 100).toInt()}%',
        ),
        const _ThresholdTile(
          label: AppStrings.inactivityThresholdLabel,
          value: '${AiThresholds.inactivityThresholdSeconds} seg',
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXl),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXxl),
      ],
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
      padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXxl, AppDimensions.spacingXxl, AppDimensions.spacingXs),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontCaption,
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
        style: const TextStyle(fontSize: AppDimensions.fontBody),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: AppDimensions.fontBody,
          fontWeight: FontWeight.w500,
          color: AppColors.grey600,
        ),
      ),
    );
  }
}