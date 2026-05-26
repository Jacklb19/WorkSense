import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/chat/data/chat_repository.dart';
import 'package:worksense_app/features/chat/domain/entities/chat_message.dart';
import 'package:worksense_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

// ── Admin: lista de conversaciones ───────────────────────────────────────────

class AdminChatListScreen extends ConsumerWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnersAsync = ref.watch(chatPartnersProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'Conversaciones',
          style: theme.textTheme.headlineSmall?.copyWith(color: context.appOnSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingMd),
            child: partnersAsync.when(
              data: (ids) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingXs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
child: Text(
                          '${ids.length}',
                          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: partnersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
        error: (_, __) => Center(
child: Text('Error cargando conversaciones',
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
          ),
        data: (partnerIds) {
          if (partnerIds.isEmpty) {
            return const _EmptyChatList();
          }

          final employees = employeesAsync.valueOrNull ?? [];
          final employeeMap = {for (final e in employees) e.id: e};

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: context.appSurface,
            onRefresh: () async {
              ref.invalidate(chatPartnersProvider);
              ref.invalidate(adminEmployeesProvider);
            },
            child: AppContentConstrainer(
              width: AppContentWidth.list,
              child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              itemCount: partnerIds.length,
              separatorBuilder: (_, __) => Divider(
                color: context.appGlassBorder,
                height: 1,
                indent: AppDimensions.dividerIndent,
              ),
              itemBuilder: (context, i) {
                final partnerId = partnerIds[i];
                final employee = employeeMap[partnerId];
                return _ConversationTile(
                  partnerId: partnerId,
                  employee: employee,
                  onTap: () => context.push(
                    AppRoutes.chat
                        .replaceFirst(':userId', partnerId)
                        .replaceFirst(
                            ':userName',
                            Uri.encodeComponent(
                                employee?.displayName ?? 'Empleado')),
                  ),
                );
              },
            ),
            ),
          );
        },
      ),
    );
  }
}

// ── Employee: pantalla de chat con el admin ───────────────────────────────────

class EmployeeChatScreen extends ConsumerWidget {
  const EmployeeChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cu = ref.watch(currentUserProvider).valueOrNull;
    final companyId = cu?.companyId ?? '';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'Mensajes',
          style: theme.textTheme.headlineSmall?.copyWith(color: context.appOnSurface),
        ),
      ),
      body: companyId.isEmpty
          ? Center(
              child: Text('Cargando…',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
            )
          : _EmployeeChatBody(companyId: companyId),
    );
  }
}

class _EmployeeChatBody extends StatefulWidget {
  final String companyId;
  const _EmployeeChatBody({required this.companyId});

  @override
  State<_EmployeeChatBody> createState() => _EmployeeChatBodyState();
}

class _EmployeeChatBodyState extends State<_EmployeeChatBody> {
  String? _adminId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final id = await ChatRepository.instance.fetchAdminId(widget.companyId);
    if (mounted) setState(() { _adminId = id; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      );
    }

    if (_adminId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing32),
          child: Text(
            'No se encontró un administrador.\nContacta a soporte.',
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AppContentConstrainer(
      width: AppContentWidth.list,
      child: ListView(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
      children: [
        _AdminConversationCard(
          adminId: _adminId!,
          onTap: () {
            context.push(
              AppRoutes.chat
                  .replaceFirst(':userId', _adminId!)
                  .replaceFirst(':userName', Uri.encodeComponent('Administrador')),
            );
          },
        ),
      ],
    ),
    );
  }
}

class _AdminConversationCard extends StatelessWidget {
  final String adminId;
  final VoidCallback onTap;

  const _AdminConversationCard({
    required this.adminId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Chatear con administrador',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingXl),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            border: Border.all(color: context.appGlassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.white, size: 24),
              ),
              const SizedBox(width: AppDimensions.spacingXl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrador',
                      style: theme.textTheme.titleSmall?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Envía un mensaje a tu empresa',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.appOnSurfaceSecondary, size: AppDimensions.spacing20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de conversación (admin) ──────────────────────────────────────────────

class _ConversationTile extends StatefulWidget {
  final String partnerId;
  final Employee? employee;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.partnerId,
    required this.employee,
    required this.onTap,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  ChatMessage? _lastMsg;
  final int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.employee?.displayName ?? 'Empleado';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'E';

    return Semantics(
      button: true,
      label: 'Conversación con $name',
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingLg),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: theme.textTheme.headlineLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _unread > 9 ? '9+' : '$_unread',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppDimensions.spacingXl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
child: Text(
                              name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: context.appOnSurface,
                                fontWeight: _unread > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ),
                        if (_lastMsg != null)
                          Text(
                            _fmtDate(_lastMsg!.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _unread > 0
                                  ? AppColors.primary
                                  : AppColors.grey400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      widget.employee?.email ?? 'Ver conversación →',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.grey400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChatList extends StatelessWidget {
  const _EmptyChatList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),
            Text(
              'Sin conversaciones',
              style: TextStyle(
                color: context.appOnSurface,
                fontSize: AppDimensions.fontBodyLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Los mensajes con empleados\naparecerán aquí.',
              style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurfaceSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}