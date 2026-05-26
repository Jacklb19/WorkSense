import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/features/chat/domain/entities/chat_message.dart';
import 'package:worksense_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.otherId,
    this.otherName = 'Chat',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (animate) {
        _scrollCtrl.animateTo(max,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut);
      } else {
        _scrollCtrl.jumpTo(max);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msgsAsync = ref.watch(conversationProvider(widget.otherId));
    final myId =
        ref.watch(currentUserProvider).valueOrNull?.user?.id ?? '';

    ref.listen(conversationProvider(widget.otherId), (prev, next) {
      final prevLen = prev?.valueOrNull?.length ?? 0;
      final nextLen = next.valueOrNull?.length ?? 0;
      if (nextLen > prevLen) _scrollToBottom(animate: true);
    });

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              child: Text(
                widget.otherName.isNotEmpty
                    ? widget.otherName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.fontSubtitle,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontSize: AppDimensions.fontSubtitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Text(
                      'En línea',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: AppContentConstrainer(
        width: AppContentWidth.full,
        padding: EdgeInsets.zero,
        child: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Error cargando mensajes',
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
                ),
              ),
              data: (msgs) {
                if (msgs.isEmpty) return const _EmptyChat();
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXl, AppDimensions.spacingXxl, AppDimensions.spacingMd),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderId == myId;
                    final showDate = i == 0 ||
                        !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _ChatInputBar(
            controller: _ctrl,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    final cu = ref.read(currentUserProvider).valueOrNull;
    if (cu == null) return;

    setState(() => _sending = true);
    _ctrl.clear();
    FocusScope.of(context).unfocus();

    await ref.read(conversationProvider(widget.otherId).notifier).send(
          content: text,
          companyId: cu.companyId ?? '',
          senderId: cu.user?.id ?? '',
          senderName: cu.user?.email ?? 'Usuario',
        );

    if (mounted) setState(() => _sending = false);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    final label = isToday
        ? 'Hoy'
        : isYesterday
            ? 'Ayer'
            : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXl),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.appGlassBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary),
            ),
          ),
          Expanded(child: Divider(color: context.appGlassBorder)),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingXl),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : context.appSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusCardLg),
            topRight: const Radius.circular(AppDimensions.radiusCardLg),
            bottomLeft: Radius.circular(isMe ? AppDimensions.radiusCardLg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppDimensions.radiusCardLg),
          ),
          border: isMe
              ? null
              : Border.all(color: context.appGlassBorder),
          boxShadow: [
            BoxShadow(
              color: (isMe ? AppColors.primary : context.appOnSurface)
                  .withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isMe ? AppColors.white : context.appOnSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmtTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMe
                        ? AppColors.white70
                        : context.appOnSurfaceSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: AppDimensions.spacingXs),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 13,
                    color: message.isRead
                        ? AppColors.white
                        : AppColors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ── Chat input bar ─────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.fromLTRB(AppDimensions.spacingLg, AppDimensions.spacingXl, AppDimensions.spacingLg, bottom > 0 ? bottom + AppDimensions.spacingXl : AppDimensions.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.appGlassBorder),
              ),
              child: TextField(
                controller: controller,
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurface),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingLg),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Semantics(
            button: true,
            label: 'Enviar mensaje',
            child: InkWell(
              onTap: sending ? null : onSend,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: sending
                      ? null
                      : const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: sending ? context.appGlassBorder : null,
                  shape: BoxShape.circle,
                  boxShadow: sending
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: sending
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'Sin mensajes aún',
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Empieza la conversación',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appOnSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}