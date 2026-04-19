import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/entrance_kiosk_provider.dart';

class EntranceKioskScreen extends ConsumerStatefulWidget {
  const EntranceKioskScreen({super.key});

  @override
  ConsumerState<EntranceKioskScreen> createState() => _EntranceKioskScreenState();
}

class _EntranceKioskScreenState extends ConsumerState<EntranceKioskScreen> {
  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) return;

    final cameras = await availableCameras();
    if (mounted) {
      await ref.read(entranceKioskProvider.notifier).initialize(cameras);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entranceKioskProvider);
    final controller = ref.read(entranceKioskProvider.notifier).cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (controller != null && controller.value.isInitialized)
            Transform.scale(
              scale: 1.1,
              child: Center(
                child: CameraPreview(controller),
              ),
            ),
            
          // Dark Overlay
          Container(
             color: Colors.black.withOpacity(0.4),
          ),

          // HUD
          SafeArea(
            child: Column(
              children: [
                 _TopBar(),
                 const Spacer(),
                 
                 // Scanner target
                 Container(
                   width: 250,
                   height: 350,
                   decoration: BoxDecoration(
                     border: Border.all(color: state.lastMatchedEmployeeId != null ? AppColors.success : AppColors.primary, width: 4),
                     borderRadius: BorderRadius.circular(20),
                   ),
                 ),
                 
                 const Spacer(),
                 
                 // Status Message
                 Container(
                   margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                   decoration: BoxDecoration(
                     color: state.lastMatchedEmployeeId != null ? AppColors.success.withOpacity(0.9) : AppColors.cardDark,
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.2), 
                         blurRadius: 10,
                         offset: const Offset(0, 5),
                       )
                     ]
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       if (state.lastMatchedEmployeeId != null)
                          const Icon(Icons.check_circle, color: Colors.white, size: 32)
                       else
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                          
                       const SizedBox(width: 16),
                       Expanded(
                         child: Text(
                           state.statusMessage,
                           style: const TextStyle(
                             color: Colors.white, 
                             fontSize: 18, 
                             fontWeight: FontWeight.bold
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WORKSENSE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('Kiosco de Acceso Frontal', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}
