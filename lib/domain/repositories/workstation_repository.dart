import 'package:worksense_app/domain/entities/workstation.dart';

abstract class WorkstationRepository {
  Future<void> saveWorkstation(Workstation workstation);
  Stream<List<Workstation>> watchWorkstations();
  Future<void> deleteWorkstation(String id);
}
