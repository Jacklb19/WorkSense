import 'package:worksense_app/domain/entities/workstation.dart';

abstract class WorkstationRepository {
  Future<void> saveWorkstation(Workstation workstation);
  Stream<List<Workstation>> watchWorkstations();
  Stream<List<Workstation>> watchWorkstationsByCompany(String companyId);
  Future<List<Workstation>> getWorkstationsByCompany(String companyId);
  Future<void> deleteWorkstation(String id);
}
