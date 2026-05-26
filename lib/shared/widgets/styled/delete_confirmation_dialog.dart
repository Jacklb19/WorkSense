import 'package:flutter/material.dart';

/// A reusable confirmation dialog used for destructive actions.
///
/// Usage:
/// ```dart
/// final confirmed = await DeleteConfirmationDialog.show(
///   context,
///   title: 'Eliminar empleado',
///   message: '¿Está seguro? Esta acción no se puede deshacer.',
/// );
/// if (confirmed) { /* proceed */ }
/// ```
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Eliminar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Shows the dialog and returns `true` if the user confirmed, `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
