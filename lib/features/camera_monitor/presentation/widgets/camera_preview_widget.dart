import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// A defensive wrapper around [CameraPreview] that survives controller disposal.
///
/// [CameraController.dispose()] calls [notifyListeners()] before it finishes
/// tearing down the platform camera. This triggers [CameraPreview]'s internal
/// [ValueListenableBuilder] to rebuild and call [CameraController.buildPreview()]
/// on a now-disposed controller, throwing:
///   CameraException(Disposed CameraController, buildPreview() was called …)
///
/// This widget guards against that by:
///   1. Listening to the controller and removing the [CameraPreview] subtree as
///      soon as [isInitialized] becomes false (the first sign the controller is
///      going away).
///   2. Removing its own listener in [dispose()] before Flutter unwinds the
///      parent state, so the final notification from [CameraController.dispose()]
///      finds no active [ValueListenableBuilder].
class CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  late bool _show;

  @override
  void initState() {
    super.initState();
    _show = widget.controller.value.isInitialized;
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      _show = widget.controller.value.isInitialized;
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    // Remove the listener BEFORE super.dispose() / widget unmount so
    // CameraController.dispose()'s final notifyListeners() doesn't reach
    // an already-unmounted state and attempt a rebuild.
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final nowInitialized = widget.controller.value.isInitialized;
    if (!nowInitialized && _show) {
      setState(() => _show = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show || !widget.controller.value.isInitialized) {
      return const _CameraPlaceholder();
    }

    // previewSize in Flutter camera is landscape (width > height).
    // For portrait mode swap width ↔ height.
    final previewSize = widget.controller.value.previewSize!;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;

    final displayW = isPortrait ? previewSize.height : previewSize.width;
    final displayH = isPortrait ? previewSize.width : previewSize.height;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: displayW,
            height: displayH,
            child: CameraPreview(widget.controller),
          ),
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: AppColors.grey600,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Iniciando cámara...',
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view when camera fails to initialize
class CameraErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CameraErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.textOnCamera38),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
