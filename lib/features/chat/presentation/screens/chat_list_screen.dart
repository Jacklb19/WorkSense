import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/chat/data/chat_repository.dart';
import 'package:worksense_app/features/chat/domain/entities/chat_message.dart';
import 'package:worksense_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Admin: lista de conversaciones ───────────────────────────────────────────

class AdminChatListScreen extends ConsumerWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(chatPartnersProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Conversaciones',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: partnersAsync.when(
              data: (ids) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ids.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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
        error: (_, __) => const Center(
          child: Text('Error cargando conversaciones',
              style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        data: (partnerIds) {
          if (partnerIds.isEmpty) {
            return const _EmptyChatList();
          }

          final employees = employeesAsync.valueOrNull ?? [];
          final employeeMap = {for (final e in employees) e.id: e};

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            onRefresh: () async {
              ref.invalidate(chatPartnersProvider);
              ref.invalidate(adminEmployeesProvider);
            },
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              itemCount: partnerIds.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.glassBorder,
                height: 1,
                indent: 72,
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
    final cu = ref.watch(currentUserProvider).valueOrNull;
    final companyId = cu?.companyId ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: companyId.isEmpty
          ? const Center(
              child: Text('Cargando…',
                  style:
                      TextStyle(color: AppColors.textSecondaryDark)),
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      );
    }

    if (_adminId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No se encontró un administrador.\nContacta a soporte.',
            style: TextStyle(
                color: AppColors.textSecondaryDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // One conversation tile pointing to admin
    return ListView(
      padding: const EdgeInsets.all(16),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
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
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrador',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Envía un mensaje a tu empresa',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondaryDark, size: 20),
          ],
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
    // We don't have a ref here, but we can call the repo directly
    // since this is a StatefulWidget (not ConsumerWidget)
    // This is acceptable for read-only display data
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.employee?.displayName ?? 'Empleado';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'E';

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _unread > 9 ? '9+' : '$_unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 14,
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
                          style: TextStyle(
                            color: _unread > 0
                                ? AppColors.primary
                                : AppColors.grey400,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.employee?.email ?? 'Ver conversación →',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey400, size: 18),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 20),
            const Text(
              'Sin conversaciones',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los mensajes con empleados\naparecerán aquí.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
