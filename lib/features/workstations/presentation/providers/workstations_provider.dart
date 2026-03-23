import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/workstation_repository_impl.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/domain/repositories/workstation_repository.dart';
import 'package:worksense_app/features/workstations/domain/usecases/delete_workstation_use_case.dart';
import 'package:worksense_app/features/workstations/domain/usecases/get_workstations_use_case.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/workstations/domain/usecases/save_workstation_use_case.dart';

final workstationRepositoryProvider = Provider<WorkstationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkstationRepositoryImpl(db);
});

final getWorkstationsUseCaseProvider = Provider<GetWorkstationsUseCase>((ref) {
  final repository = ref.watch(workstationRepositoryProvider);
  return GetWorkstationsUseCase(repository);
});

final saveWorkstationUseCaseProvider = Provider<SaveWorkstationUseCase>((ref) {
  final repository = ref.watch(workstationRepositoryProvider);
  return SaveWorkstationUseCase(repository);
});

final deleteWorkstationUseCaseProvider = Provider<DeleteWorkstationUseCase>((ref) {
  final repository = ref.watch(workstationRepositoryProvider);
  return DeleteWorkstationUseCase(repository);
});

final workstationsProvider = StreamProvider<List<Workstation>>((ref) {
  final getWorkstationsUseCase = ref.watch(getWorkstationsUseCaseProvider);
  return getWorkstationsUseCase();
});
