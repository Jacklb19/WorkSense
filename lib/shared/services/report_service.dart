import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:worksense_app/domain/entities/alert_log.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/entities/task_item.dart';

/// Servicio de generación de reportes PDF para WorkSense.
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  // ── Palette (PDF colors) ────────────────────────────────────────────────────

  static const _bg = PdfColor.fromInt(0xFF0F0F1A);
  static const _card = PdfColor.fromInt(0xFF1A1A2E);
  static const _primary = PdfColor.fromInt(0xFF6C63FF);
  static const _white = PdfColors.white;
  static const _grey = PdfColor.fromInt(0xFF9CA3AF);
  static const _success = PdfColor.fromInt(0xFF10B981);
  static const _warning = PdfColor.fromInt(0xFFF59E0B);
  static const _error = PdfColor.fromInt(0xFFEF4444);

  // ── Alpha helper ────────────────────────────────────────────────────────────

  /// Creates a copy of [color] with the given [opacity] (0.0–1.0).
  static PdfColor _alpha(PdfColor color, double opacity) =>
      PdfColor(color.red, color.green, color.blue, opacity);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Preview + share PDF for tasks report.
  ///
  /// [employeeNames] optional map of `{employeeId: displayName}` — used to
  /// show real names instead of truncated UUIDs in the "Asignado a" column.
  Future<void> previewTasksReport({
    required List<TaskItem> tasks,
    required String companyName,
    Map<String, String>? employeeNames,
  }) async {
    final doc = await _buildTasksDocument(
      tasks: tasks,
      companyName: companyName,
      employeeNames: employeeNames,
    );
    await Printing.layoutPdf(onLayout: (_) async => doc);
  }

  /// Preview + share PDF for leave requests report.
  ///
  /// [employeeNames] optional map of `{employeeId: displayName}` — used to
  /// show real names instead of truncated UUIDs in the "Empleado" column.
  Future<void> previewLeavesReport({
    required List<LeaveRequest> leaves,
    required String companyName,
    Map<String, String>? employeeNames,
  }) async {
    final doc = await _buildLeavesDocument(
      leaves: leaves,
      companyName: companyName,
      employeeNames: employeeNames,
    );
    await Printing.layoutPdf(onLayout: (_) async => doc);
  }

  /// Preview + share PDF for alerts report.
  Future<void> previewAlertsReport({
    required List<AlertLog> alerts,
    required String companyName,
  }) async {
    final doc = await _buildAlertsDocument(alerts: alerts, companyName: companyName);
    await Printing.layoutPdf(onLayout: (_) async => doc);
  }

  /// Preview + share PDF for announcements report.
  Future<void> previewAnnouncementsReport({
    required List<Announcement> announcements,
    required String companyName,
  }) async {
    final doc = await _buildAnnouncementsDocument(
      announcements: announcements,
      companyName: companyName,
    );
    await Printing.layoutPdf(onLayout: (_) async => doc);
  }

  // ── Document builders ───────────────────────────────────────────────────────

  Future<Uint8List> _buildTasksDocument({
    required List<TaskItem> tasks,
    required String companyName,
    Map<String, String>? employeeNames,
  }) async {
    final pdf = pw.Document();

    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        build: (context) => [
          _header(
            title: 'Reporte de Tareas',
            companyName: companyName,
            generatedAt: DateTime.now(),
          ),
          pw.SizedBox(height: 16),
          _summaryRow([
            _SummaryItem('Total', tasks.length.toString(), _primary),
            _SummaryItem('Completadas', done.toString(), _success),
            _SummaryItem('En progreso', inProgress.toString(), _warning),
            _SummaryItem('Pendientes', pending.toString(), _grey),
            _SummaryItem('Vencidas', overdue.toString(), _error),
          ]),
          pw.SizedBox(height: 20),
          if (tasks.isNotEmpty) ...[
            _sectionTitle('Detalle de tareas'),
            pw.SizedBox(height: 8),
            _tasksTable(tasks, employeeNames),
          ] else
            _emptyState('No hay tareas registradas.'),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildLeavesDocument({
    required List<LeaveRequest> leaves,
    required String companyName,
    Map<String, String>? employeeNames,
  }) async {
    final pdf = pw.Document();

    final approved = leaves.where((l) => l.status == LeaveStatus.approved).length;
    final rejected = leaves.where((l) => l.status == LeaveStatus.rejected).length;
    final pending = leaves.where((l) => l.status == LeaveStatus.pending).length;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        build: (context) => [
          _header(
            title: 'Reporte de Permisos',
            companyName: companyName,
            generatedAt: DateTime.now(),
          ),
          pw.SizedBox(height: 16),
          _summaryRow([
            _SummaryItem('Total', leaves.length.toString(), _primary),
            _SummaryItem('Aprobados', approved.toString(), _success),
            _SummaryItem('Rechazados', rejected.toString(), _error),
            _SummaryItem('Pendientes', pending.toString(), _warning),
          ]),
          pw.SizedBox(height: 20),
          if (leaves.isNotEmpty) ...[
            _sectionTitle('Detalle de solicitudes'),
            pw.SizedBox(height: 8),
            _leavesTable(leaves, employeeNames),
          ] else
            _emptyState('No hay solicitudes de permiso registradas.'),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildAlertsDocument({
    required List<AlertLog> alerts,
    required String companyName,
  }) async {
    final pdf = pw.Document();

    final absence = alerts.where((a) => a.alertType == AlertType.absence).length;
    final distraction = alerts.where((a) => a.alertType == AlertType.distraction).length;
    final fatigue = alerts.where((a) => a.alertType == AlertType.fatigue).length;
    final unack = alerts.where((a) => !a.acknowledged).length;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        build: (context) => [
          _header(
            title: 'Reporte de Alertas',
            companyName: companyName,
            generatedAt: DateTime.now(),
          ),
          pw.SizedBox(height: 16),
          _summaryRow([
            _SummaryItem('Total', alerts.length.toString(), _primary),
            _SummaryItem('Ausencia', absence.toString(), _error),
            _SummaryItem('Distracción', distraction.toString(), _warning),
            _SummaryItem('Fatiga', fatigue.toString(), _grey),
            _SummaryItem('Sin revisar', unack.toString(), _error),
          ]),
          pw.SizedBox(height: 20),
          if (alerts.isNotEmpty) ...[
            _sectionTitle('Historial de alertas'),
            pw.SizedBox(height: 8),
            _alertsTable(alerts),
          ] else
            _emptyState('No hay alertas registradas.'),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildAnnouncementsDocument({
    required List<Announcement> announcements,
    required String companyName,
  }) async {
    final pdf = pw.Document();

    final urgent = announcements.where((a) => a.priority == AnnouncementPriority.urgent).length;
    final high = announcements.where((a) => a.priority == AnnouncementPriority.high).length;
    final normal = announcements.where((a) => a.priority == AnnouncementPriority.normal).length;
    final low = announcements.where((a) => a.priority == AnnouncementPriority.low).length;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        build: (context) => [
          _header(
            title: 'Reporte de Comunicados',
            companyName: companyName,
            generatedAt: DateTime.now(),
          ),
          pw.SizedBox(height: 16),
          _summaryRow([
            _SummaryItem('Total', announcements.length.toString(), _primary),
            _SummaryItem('Urgentes', urgent.toString(), _error),
            _SummaryItem('Importantes', high.toString(), _warning),
            _SummaryItem('Generales', normal.toString(), _success),
            _SummaryItem('Informativos', low.toString(), _grey),
          ]),
          pw.SizedBox(height: 20),
          if (announcements.isNotEmpty) ...[
            _sectionTitle('Detalle de comunicados'),
            pw.SizedBox(height: 8),
            _announcementsTable(announcements),
          ] else
            _emptyState('No hay comunicados registrados.'),
        ],
      ),
    );

    return pdf.save();
  }

  // ── PDF building blocks ─────────────────────────────────────────────────────

  pw.PageTheme _pageTheme() => pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: _bg),
        ),
      );

  pw.Widget _header({
    required String title,
    required String companyName,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _primary, width: 1.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WorkSense',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  color: _primary,
                  fontSize: 22,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                companyName,
                style: const pw.TextStyle(color: _grey, fontSize: 11),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generado: ${_fmtDateTime(generatedAt)}',
                style: const pw.TextStyle(color: _grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(List<_SummaryItem> items) {
    return pw.Row(
      children: items
          .map((item) => pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 4),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _card,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                        color: _alpha(item.color, 0.5), width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        item.value,
                        style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          color: item.color,
                          fontSize: 20,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        item.label,
                        style: const pw.TextStyle(color: _grey, fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        color: _white,
        fontSize: 14,
      ),
    );
  }

  pw.Widget _emptyState(String message) {
    return pw.Center(
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: _grey, fontSize: 12),
      ),
    );
  }

  // ── Tables ──────────────────────────────────────────────────────────────────

  pw.Widget _tasksTable(List<TaskItem> tasks, Map<String, String>? names) {
    return pw.TableHelper.fromTextArray(
      headers: ['Título', 'Asignado a', 'Estado', 'Prioridad', 'Vence'],
      data: tasks.map((t) => [
        t.title.length > 40 ? '${t.title.substring(0, 40)}…' : t.title,
        _resolveName(t.assignedToId, names),
        t.status.label,
        t.priority.label,
        t.dueDate != null ? _fmtDate(t.dueDate!) : '—',
      ]).toList(),
      headerStyle: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        color: _primary,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(color: _white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _card),
      rowDecoration: const pw.BoxDecoration(color: _bg),
      oddRowDecoration: pw.BoxDecoration(
        color: _alpha(_card, 0.5),
      ),
      border: pw.TableBorder.all(color: _alpha(_grey, 0.2), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  pw.Widget _leavesTable(List<LeaveRequest> leaves, Map<String, String>? names) {
    return pw.TableHelper.fromTextArray(
      headers: ['Empleado', 'Tipo', 'Estado', 'Desde', 'Hasta', 'Días'],
      data: leaves.map((l) => [
        _resolveName(l.employeeId, names),
        l.type.label,
        l.status.label,
        _fmtDate(l.startDate),
        _fmtDate(l.endDate),
        l.durationDays.toString(),
      ]).toList(),
      headerStyle: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        color: _primary,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(color: _white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _card),
      rowDecoration: const pw.BoxDecoration(color: _bg),
      oddRowDecoration: pw.BoxDecoration(
        color: _alpha(_card, 0.5),
      ),
      border: pw.TableBorder.all(color: _alpha(_grey, 0.2), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  pw.Widget _alertsTable(List<AlertLog> alerts) {
    return pw.TableHelper.fromTextArray(
      headers: ['Tipo', 'Duración', 'Fecha/Hora', 'Estado'],
      data: alerts.map((a) => [
        a.alertType.label,
        a.durationLabel,
        _fmtDateTime(a.triggeredAt),
        a.acknowledged ? 'Revisado' : 'Pendiente',
      ]).toList(),
      headerStyle: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        color: _primary,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(color: _white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _card),
      rowDecoration: const pw.BoxDecoration(color: _bg),
      oddRowDecoration: pw.BoxDecoration(
        color: _alpha(_card, 0.5),
      ),
      border: pw.TableBorder.all(color: _alpha(_grey, 0.2), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  pw.Widget _announcementsTable(List<Announcement> announcements) {
    return pw.TableHelper.fromTextArray(
      headers: ['Título', 'Prioridad', 'Fecha', 'Expira'],
      data: announcements.map((a) => [
        a.title.length > 40 ? '${a.title.substring(0, 40)}…' : a.title,
        a.priority.label,
        _fmtDate(a.createdAt),
        a.expiresAt != null ? _fmtDate(a.expiresAt!) : 'Sin vencimiento',
      ]).toList(),
      headerStyle: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        color: _primary,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(color: _white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _card),
      rowDecoration: const pw.BoxDecoration(color: _bg),
      oddRowDecoration: pw.BoxDecoration(color: _alpha(_card, 0.5)),
      border: pw.TableBorder.all(color: _alpha(_grey, 0.2), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the display name for [id] if present in [names], otherwise
  /// falls back to the first 8 characters of the UUID.
  String _resolveName(String id, Map<String, String>? names) {
    if (names != null) {
      final name = names[id];
      if (name != null && name.trim().isNotEmpty) return name;
    }
    return id.length >= 8 ? id.substring(0, 8) : id;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Internal model ────────────────────────────────────────────────────────────

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.color);
  final String label;
  final String value;
  final PdfColor color;
}
