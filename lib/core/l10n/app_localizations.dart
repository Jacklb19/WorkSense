import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ── Extension de acceso rápido ────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ── Delegates para MaterialApp ────────────────────────────────────────────────

const localizationsDelegates = [
  AppLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

// ── Clase principal ───────────────────────────────────────────────────────────

class AppLocalizations {
  final String _lang;
  const AppLocalizations(this._lang);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations('es');
  }

  bool get _en => _lang == 'en';

  String _t(String es, String en) => _en ? en : es;

  // ── NAVIGATION ─────────────────────────────────────────────────────────────
  String get navDashboard     => 'Dashboard';
  String get navEmployees     => _t('Empleados',   'Employees');
  String get navWorkstations  => _t('Puestos',     'Workstations');
  String get navSettings      => _t('Ajustes',     'Settings');
  String get navHome          => _t('Inicio',      'Home');
  String get navActivity      => _t('Actividad',   'Activity');
  String get navTasks         => _t('Tareas',      'Tasks');
  String get navLeaves        => _t('Permisos',    'Leaves');
  String get navShifts        => _t('Horarios',    'Shifts');

  // ── GENERAL ────────────────────────────────────────────────────────────────
  String get error            => 'Error';
  String get cancel           => _t('Cancelar',   'Cancel');
  String get save             => _t('Guardar',    'Save');
  String get delete           => _t('Eliminar',   'Delete');
  String get retry            => _t('Reintentar', 'Retry');
  String get loading          => _t('Cargando…',  'Loading…');
  String get somethingWentWrong => _t('Algo salió mal',   'Something went wrong');
  String get errorLoadingData   => _t('Error al cargar datos', 'Error loading data');
  String get saveChanges        => _t('Guardar cambios',   'Save changes');
  String get confirm            => _t('Confirmar',         'Confirm');
  String get fieldRequired      => _t('Campo requerido',   'Required field');
  String get sectionIdentity    => _t('IDENTIDAD',         'IDENTITY');
  String get sectionCredentials => _t('CREDENCIALES',      'CREDENTIALS');
  String get errorSaving        => _t('Error al guardar',  'Error saving');
  String get errorDeleting      => _t('Error al eliminar', 'Error deleting');
  String get notFound           => _t('No encontrado',     'Not found');
  String get deleteShift        => _t('Eliminar turno',    'Delete shift');
  String get workShifts         => _t('Horarios Laborales','Work Schedules');
  String get newShift           => _t('NUEVO TURNO',       'NEW SHIFT');
  String get noShiftsRegistered => _t('No hay turnos registrados', 'No shifts registered');
  String get noShiftsHint       => _t('Crea tu primer horario laboral\npara asignarlo a tus empleados.',
                                      'Create your first work schedule\nto assign it to your employees.');
  String get employeeNotFound   => _t('Empleado no encontrado', 'Employee not found');

  // ── AUTH ───────────────────────────────────────────────────────────────────
  String get emailLabel       => _t('Correo electrónico',     'Email');
  String get emailHint        => 'admin@empresa.com';
  String get passwordLabel    => _t('Contraseña',             'Password');
  String get loginButton      => _t('Iniciar sesión',         'Sign in');
  String get copyright        => 'WorkSense © 2026';
  String get subtitle         => _t('Monitoreo inteligente de actividad',
                                    'Smart activity monitoring');
  String get emailRequired    => _t('Ingresa tu correo electrónico.',
                                    'Enter your email address.');
  String get emailInvalid     => _t('Correo electrónico inválido.',
                                    'Invalid email address.');
  String get passwordRequired => _t('Ingresa tu contraseña.',
                                    'Enter your password.');
  String get passwordTooShort => _t('La contraseña debe tener al menos 6 caracteres.',
                                    'Password must be at least 6 characters.');

  // ── ADMIN DASHBOARD ────────────────────────────────────────────────────────
  String get controlPanel     => _t('Comando Central',        'Command Center');
  String get startKiosk       => _t('Iniciar Kiosco',         'Start Kiosk');
  String get kiosk            => _t('Kiosco',                 'Kiosk');
  String get stations         => _t('Estaciones',             'Stations');
  String get alerts           => _t('Alertas',                'Alerts');
  String get noWorkstations   => _t('Sin puestos registrados','No workstations registered');
  String get errorLoadingWorkstation =>
      _t('Error al cargar la información del puesto.',
         'Error loading workstation information.');
  String get loadingCollaborators    => _t('Cargando colaboradores…', 'Loading collaborators…');
  String get noCollaboratorsYet      => _t('Sin colaboradores aún',   'No collaborators yet');
  String get noCollaboratorsSubtitle => _t(
      'Registra empleados para comenzar a\ngestionar asistencia y productividad.',
      'Register employees to start\nmanaging attendance and productivity.');
  String get registerEmployee        => _t('Registrar empleado',      'Register employee');

  // ── EMPLOYEE DASHBOARD ─────────────────────────────────────────────────────
  String get mySpace          => _t('Mi Espacio',             'My Space');
  String get employee         => _t('Empleado',               'Employee');
  String get todaySummary     => _t('Resumen de tu actividad de hoy',
                                    'Today\'s activity summary');
  String get assignedWorkstation  => _t('PUESTO ASIGNADO',    'ASSIGNED WORKSTATION');
  String get myProductivityToday  => _t('MI PRODUCTIVIDAD HOY','MY PRODUCTIVITY TODAY');
  String get recentActivityLive   => _t('ACTIVIDAD RECIENTE (EN VIVO)',
                                        'RECENT ACTIVITY (LIVE)');
  String get noAssignedWorkstation      => _t('Sin puesto asignado', 'No assigned workstation');
  String get noAssignedWorkstationDesc  =>
      _t('Espera a que un administrador te asigne a un puesto de trabajo.',
         'Wait for an administrator to assign you to a workstation.');
  String get monitoringAssigned => _t('Monitoreo asignado',   'Monitoring assigned');
  String get verifyingWorkstation => _t('Verificando puesto…','Verifying workstation…');
  String get noActivityToday  =>
      _t('Aún no hay actividad registrada para ti hoy.',
         'No activity recorded for you today.');
  String get noShiftAssigned  => _t('Sin turno asignado',      'No shift assigned');
  String get noRecentEvents   => _t('No hay eventos recientes.','No recent events.');
  String get calculatingTime  => _t('Calculando tiempo…',     'Calculating time…');
  String get working          => _t('Trabajando',             'Working');
  String get distracted       => _t('Distraído',              'Distracted');
  String get fatigue          => _t('Fatiga',                 'Fatigue');
  String get myGlobalHistory  => _t('Mi historial global',    'My global history');
  String get quickAccess      => _t('ACCESOS RÁPIDOS',        'QUICK ACCESS');
  String get myTasksLabel     => _t('MIS TAREAS',             'MY TASKS');

  // ── SETTINGS ───────────────────────────────────────────────────────────────
  String get settings         => _t('Configuración',          'Settings');
  String get accountSection   => _t('Cuenta',                 'Account');
  String get user             => _t('Usuario',                'User');
  String get notAvailable     => _t('No disponible',          'Not available');
  String get activityAnalysis => _t('Análisis de Actividad',  'Activity Analysis');
  String get analysisInterval => _t('Intervalo de análisis',  'Analysis interval');
  String get analysisIntervalDesc =>
      _t('Frecuencia con la que se analiza la actividad. '
         'Valores menores son más precisos pero consumen más batería.',
         'How often activity is analyzed. '
         'Lower values are more precise but consume more battery.');
  String get detectionThresholds =>
      _t('Umbrales de Detección (solo lectura)',
         'Detection Thresholds (read-only)');
  String get about            => _t('Acerca de',              'About');
  String get version          => _t('Versión',                'Version');
  String get application      => _t('Aplicación',             'Application');
  String get logout           => _t('Cerrar sesión',          'Sign out');
  String get logoutConfirmation => _t('¿Deseas cerrar sesión?','Do you want to sign out?');

  // ── Settings — nuevo: Apariencia e idioma ──────────────────────────────────
  String get appearance       => _t('Apariencia',             'Appearance');
  String get themeMode        => _t('Tema',                   'Theme');
  String get themeDark        => _t('Oscuro',                 'Dark');
  String get themeLight       => _t('Claro',                  'Light');
  String get themeSystem      => _t('Sistema',                'System');
  String get language         => _t('Idioma',                 'Language');
  String get langSpanish      => _t('Español',                'Spanish');
  String get langEnglish      => _t('Inglés',                 'English');

  // ── EMPLOYEES ──────────────────────────────────────────────────────────────
  String get employees        => _t('Empleados',              'Employees');
  String get newEmployee      => _t('Nuevo Empleado',         'New Employee');
  String get editEmployee     => _t('Editar Empleado',        'Edit Employee');
  String get addEmployee      => _t('Agregar empleado',       'Add employee');
  String get deleteEmployee   => _t('Eliminar empleado',      'Delete employee');
  String get confirmDeleteEmployeeBody => _t(
      '¿Estás seguro de que deseas eliminar permanentemente este colaborador? '
      'Esta acción eliminará su acceso y todos sus datos de asistencia.',
      'Are you sure you want to permanently delete this employee? '
      'This will remove their access and all attendance data.');
  String get employeeDeleted  => _t('Colaborador eliminado',   'Employee deleted');
  String get employeeUpdated  => _t('Empleado actualizado correctamente.',
                                    'Employee updated successfully.');
  String get employeeAdded    => _t('Empleado agregado correctamente.',
                                    'Employee added successfully.');
  String get nameLabel        => _t('Nombre completo',        'Full name');
  String get lastNameLabel    => _t('Apellidos',              'Last name');
  String get roleLabel        => _t('Rol',                    'Role');
  String get roleEmployee     => _t('Empleado (Kiosk)',       'Employee (Kiosk)');
  String get roleAdmin        => _t('Administrador',          'Administrator');
  String get cameraMonitorRole => _t('Monitor de cámara',    'Camera Monitor');
  String get noEmployees      => _t('Sin empleados registrados','No employees registered');
  String get addEmployeeHint  => _t('Agrega empleados con el botón +',
                                    'Add employees with the + button');
  String get passwordTempLabel => _t('Contraseña (temporal)', 'Password (temporary)');
  String get passwordTempHint  => _t('Mínimo 6 caracteres',  'Minimum 6 characters');

  // ── WORKSTATIONS ───────────────────────────────────────────────────────────
  String get workstations       => _t('Estaciones de Trabajo','Workstations');
  String get newWorkstation     => _t('Nueva Estación',       'New Workstation');
  String get workstationSaved   => _t('Estación guardada exitosamente',
                                      'Workstation saved successfully');
  String get deleteWorkstation  => _t('Eliminar Estación',   'Delete Workstation');
  String get noWorkstationsReg  =>
      _t('No hay estaciones de trabajo registradas.',
         'No workstations registered.');
  String get saveWorkstation    => _t('Guardar Estación',     'Save Workstation');
  String get geolocation        => _t('Geolocalización',      'Geolocation');
  String get useCurrentLocation => _t('Usar mi ubicación actual',
                                      'Use my current location');
  String get locationSuccess    => _t('Ubicación obtenida con éxito.',
                                      'Location retrieved successfully.');
  String get assignEmployeeOpt  => _t('Asignar Empleado (Opcional)',
                                      'Assign Employee (Optional)');
  String get none               => _t('Ninguno',              'None');
  String get workstationNameLabel => _t('Nombre del puesto',  'Workstation name');
  String get deviceIdLabel      => _t('ID del dispositivo',   'Device ID');

  // ── TASKS ──────────────────────────────────────────────────────────────────
  String get tasks            => _t('Tareas',                 'Tasks');
  String get newTask          => _t('Nueva tarea',            'New task');
  String get taskTitle        => _t('Título',                 'Title');
  String get taskDescription  => _t('Descripción',            'Description');
  String get taskPriority     => _t('Prioridad',              'Priority');
  String get taskDueDate      => _t('Fecha límite',           'Due date');
  String get taskAssignTo     => _t('Asignar a',              'Assign to');
  String get taskPending      => _t('Pendientes',             'Pending');
  String get taskInProgress   => _t('En curso',               'In progress');
  String get taskOverdue      => _t('Vencidas',               'Overdue');
  String get taskCompleted    => _t('Completadas',            'Completed');
  String get noTasks          => _t('Sin tareas',             'No tasks');

  // ── LEAVES ─────────────────────────────────────────────────────────────────
  String get leaves           => _t('Permisos',               'Leave Requests');
  String get newLeave         => _t('Nueva solicitud',        'New request');
  String get leaveApproved    => _t('Aprobado',               'Approved');
  String get leaveRejected    => _t('Rechazado',              'Rejected');
  String get leavePending     => _t('Pendiente',              'Pending');
  String get approve          => _t('Aprobar',                'Approve');
  String get reject           => _t('Rechazar',               'Reject');
  String get noLeaves         => _t('Sin solicitudes',        'No leave requests');
  String get leaveRequestLabel => _t('Solicitar permiso',     'Request leave');

  // ── ANNOUNCEMENTS ──────────────────────────────────────────────────────────
  String get announcements    => _t('Comunicados',            'Announcements');
  String get newAnnouncement  => _t('Nuevo comunicado',       'New announcement');

  // ── SYNC ───────────────────────────────────────────────────────────────────
  String get offlineMode      => _t('Modo Offline',           'Offline Mode');
  String get onlineAndSynced  => _t('Online y Sincronizado',  'Online & Synced');
  String get syncing          => _t('Sincronizando…',         'Syncing…');

  // ── HISTORY ────────────────────────────────────────────────────────────────
  String get activityHistory  => _t('Historial de Actividad', 'Activity History');
  String get filterByState    => _t('Filtrar por estado',     'Filter by state');
  String get allStates        => _t('Todos los estados',      'All states');
  String get noResults        => _t('Sin resultados',         'No results');
  String get noEventsRegistered => _t('Sin eventos registrados','No events registered');

  // ── ANALYTICS ──────────────────────────────────────────────────────────────
  String get analytics        => _t('Analíticas',             'Analytics');
  String get today            => _t('Hoy',                    'Today');
  String get thisWeek         => _t('Esta semana',            'This week');
  String get productivity     => _t('Productividad',          'Productivity');

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────────
  String get notifications    => _t('Notificaciones',         'Notifications');
  String get markAllRead      => _t('Leer todo',              'Mark all read');
  String get noNotifications  => _t('Sin notificaciones',     'No notifications');

  // ── CHAT ───────────────────────────────────────────────────────────────────
  String get messages         => _t('Mensajes',               'Messages');
  String get conversations    => _t('Conversaciones',         'Conversations');
  String get typeMessage      => _t('Escribe un mensaje…',    'Type a message…');
  String get noMessages       => _t('Sin mensajes aún',       'No messages yet');

  // ── KIOSK ──────────────────────────────────────────────────────────────────
  String get exitKioskTitle   => _t('Salir del modo kiosco',  'Exit kiosk mode');
  String get exitKioskMessage => _t('¿Deseas cerrar sesión y salir del monitoreo?',
                                    'Do you want to sign out and exit monitoring?');
  String get exitButton       => _t('Salir',                  'Exit');
  String get backToDashboard  => _t('Volver al dashboard',    'Back to dashboard');
  String get scanEmployee     => _t('Escanear empleado',      'Scan employee');

  // ── PROFILE ────────────────────────────────────────────────────────────────
  String get myProfile        => _t('Mi perfil',              'My profile');
  String get myProfileSubtitle => _t('Estadísticas, turno y datos personales',
                                     'Statistics, shift and personal data');

  // ── REPORTS ────────────────────────────────────────────────────────────────
  String get reports          => _t('Reportes',               'Reports');

  // ── GREETINGS ───────────────────────────────────────────────────────────────
  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return _en ? 'Good morning 👋'   : 'Buenos días 👋';
    if (h < 18) return _en ? 'Good afternoon 👋' : 'Buenas tardes 👋';
    return          _en ? 'Good evening 👋'   : 'Buenas noches 👋';
  }

  // ── QUICK ACCESS subtitles ───────────────────────────────────────────────────
  String get myActivitySubtitle   => _t('Ver historial personal detallado',
                                        'View detailed personal history');
  String get myHoursSubtitle      => _t('Consultar horas, sesiones y resumen diario',
                                        'Check hours, sessions and daily summary');
  String get myEvaluationsSubtitle => _t('Consultar tus evaluaciones de desempeño',
                                         'View your performance evaluations');

  // ── GENERAL (new) ──────────────────────────────────────────────────────────
  String get edit                  => _t('Editar',               'Edit');
  String get all                   => _t('Todos',                'All');
  String get total                 => _t('Total',                'Total');
  String get syncNow               => _t('Sincronizar ahora',    'Sync now');
  String get searchByNameEmail     => _t('Buscar por nombre o email…',
                                         'Search by name or email…');
  String get noResultsPrefix       => _t('Sin resultados para',  'No results for');
  String get pendingSyncLabel      => _t('pendientes de sincronización',
                                         'pending sync');
  String get removeFilter          => _t('Quitar filtro',        'Remove filter');
  String get registeredOn          => _t('Registrado el',        'Registered on');

  // ── HOME EMPLOYEE (new) ─────────────────────────────────────────────────
  String get myEmployeePanel       => _t('Mi Panel de Empleado', 'My Employee Panel');
  String get welcome               => _t('Bienvenido',           'Welcome');
  String get scheduleAndActivityHint => _t(
      'Aquí verás tu horario y estado de actividad.',
      'Here you\'ll see your schedule and activity status.');

  // ── WORKSTATIONS (new) ──────────────────────────────────────────────────
  String get workstationDeleted    => _t(
      'Estación eliminada (Sincronización pendiente)',
      'Workstation deleted (Sync pending)');
  String get workstationNameRequired => _t('Ingresa un nombre', 'Enter a name');
  String get deviceIdRequired      => _t('El ID no puede estar vacío',
                                         'ID cannot be empty');
  String get editWorkstation       => _t('Editar estación',     'Edit workstation');
  String get updateWorkstation     => _t('Actualizar estación', 'Update workstation');
  String get confirmDeleteWs       => _t(
      '¿Seguro que deseas eliminar la estación',
      'Are you sure you want to delete workstation');
  String get newWorkstationShort   => _t('Nueva estación',      'New workstation');

  // ── SETTINGS — thresholds (new) ─────────────────────────────────────────
  String get maxYawLabel           => _t('Ángulo máximo de giro (yaw)',
                                         'Max rotation angle (yaw)');
  String get minPitchLabel         => _t('Ángulo mínimo de inclinación (pitch)',
                                         'Min tilt angle (pitch)');
  String get maxRollLabel          => _t('Ángulo máximo de volteo (roll)',
                                         'Max roll angle (roll)');
  String get minPoseConfidenceLabel => _t('Confianza mínima de pose',
                                          'Min pose confidence');
  String get inactivityThresholdLabel => _t('Umbral de inactividad',
                                             'Inactivity threshold');

  // ── LEAVES (new) ────────────────────────────────────────────────────────
  String get leaveApprovedMsg      => _t('Permiso aprobado',    'Leave approved');
  String get leaveRejectedMsg      => _t('Permiso rechazado',   'Leave rejected');
  String get rejectLeaveTitle      => _t('Rechazar permiso',    'Reject leave request');
  String get rejectReason          => _t('Motivo del rechazo (opcional)',
                                         'Reason for rejection (optional)');
  String get writeNote             => _t('Escribe una nota…',   'Write a note…');
  String get cancelRequest         => _t('Cancelar solicitud',  'Cancel request');
  String get requestCancelledOk    => _t('Solicitud cancelada',  'Request cancelled');
  String get confirmCancelRequest  => _t(
      '¿Seguro que quieres cancelar esta solicitud?',
      'Are you sure you want to cancel this request?');
  String get noLeaveRequests       => _t('No hay solicitudes de permiso',
                                         'No leave requests');
  String get noLeaveRequestsEmployee => _t(
      'No has enviado solicitudes de permiso',
      'You haven\'t submitted any leave requests');
  String get noLeavesFiltered      => _t('No hay permisos', 'No leaves');
  String get selectAbsencePeriod   => _t('Selecciona el período de ausencia',
                                         'Select the absence period');
  String get leavePendingPlural    => _t('Pendientes',       'Pending');
  String get leaveApprovedPlural   => _t('Aprobados',        'Approved');
  String get leaveRejectedPlural   => _t('Rechazados',       'Rejected');

  // ── NOTIFICATIONS (new) ─────────────────────────────────────────────────
  String get errorLoadingNotifications => _t('Error cargando notificaciones',
                                             'Error loading notifications');
  String get timeAgoNow            => _t('Ahora mismo',      'Just now');
  String timeAgoMinutes(int m)     => _en ? '${m}m ago'      : 'hace $m min';
  String timeAgoHours(int h)       => _en ? '${h}h ago'      : 'hace $h h';
  String timeAgoDays(int d)        => _en ? '${d}d ago'      : 'hace $d días';

  // ── CHAT (new) ──────────────────────────────────────────────────────────
  String get online                => _t('En línea',         'Online');
  String get startConversation     => _t('Empieza la conversación 👋',
                                         'Start the conversation 👋');
  String get errorLoadingMessages  => _t('Error cargando mensajes',
                                         'Error loading messages');
  String get errorSendingMessage   => _t('Error enviando mensaje',
                                         'Error sending message');
  String get noConversations       => _t('Sin conversaciones','No conversations');
  String get noConversationsDesc   => _t(
      'Los mensajes con empleados\naparecerán aquí.',
      'Messages with employees\nwill appear here.');
  String get administrator         => _t('Administrador',    'Administrator');
  String get sendMessageToCompany  => _t('Envía un mensaje a tu empresa',
                                         'Send a message to your company');
  String get viewConversation      => _t('Ver conversación →','View conversation →');
  String get adminNotFound         => _t(
      'No se encontró un administrador.\nContacta a soporte.',
      'No administrator found.\nContact support.');
  String get errorLoadingConversations => _t('Error cargando conversaciones',
                                             'Error loading conversations');

  // ── NAV BAR ────────────────────────────────────────────────────────────────
  String get navMenu          => _t('Menú',                   'Menu');
  String get navSections      => _t('SECCIONES',              'SECTIONS');

  // ── ROUTER / MISC ──────────────────────────────────────────────────────────
  String get goToDashboard    => _t('Ir al dashboard',        'Go to dashboard');
  String get pageNotFound     => _t('Página no encontrada',   'Page not found');
  String get myActivity       => _t('Mi Actividad',           'My Activity');
  String get myHours          => _t('Mis Horas',              'My Hours');

  // ── PAYROLL (Nómina) ───────────────────────────────────────────────────────
  String get payroll            => _t('Nómina',               'Payroll');
  String get payrollPeriod      => _t('Período de nómina',    'Payroll period');
  String get newPeriod          => _t('Nuevo período',        'New period');
  String get periodName         => _t('Nombre del período',   'Period name');
  String get startDate          => _t('Fecha inicio',         'Start date');
  String get endDate            => _t('Fecha fin',            'End date');
  String get totalGross         => _t('Nómina bruta',         'Total gross');
  String get netPay             => _t('Pago neto',            'Net pay');
  String get deductions         => _t('Deducciones',          'Deductions');
  String get hoursWorked        => _t('Horas trabajadas',     'Hours worked');
  String get hourlyRate         => _t('Tarifa por hora',      'Hourly rate');
  String get payrollDraft       => _t('Borrador',             'Draft');
  String get payrollApproved    => _t('Aprobado',             'Approved');
  String get payrollPaid        => _t('Pagado',               'Paid');
  String get noPayrollPeriods   =>
      _t('Sin períodos de nómina aún.', 'No payroll periods yet.');
  String get ratesConfig        => _t('Configurar tarifas',   'Configure rates');
  String get employeeRate       => _t('Tarifa del empleado',  'Employee rate');

  // ── EVALUATIONS (Evaluaciones) ─────────────────────────────────────────────
  String get evaluations        => _t('Evaluaciones',         'Evaluations');
  String get newEvaluation      => _t('Nueva evaluación',     'New evaluation');
  String get myEvaluations      => _t('Mis evaluaciones',     'My evaluations');
  String get evaluationPeriod   => _t('Período evaluado',     'Evaluation period');
  String get criteria           => _t('Criterios',            'Criteria');
  String get score              => _t('Puntaje',              'Score');
  String get grade              => _t('Calificación',         'Grade');
  String get notes              => _t('Notas',                'Notes');
  String get excellent          => _t('Excelente',            'Excellent');
  String get good               => _t('Bueno',                'Good');
  String get acceptable         => _t('Aceptable',            'Acceptable');
  String get regular            => _t('Regular',              'Regular');
  String get deficient          => _t('Deficiente',           'Deficient');
  String get noEvaluations      =>
      _t('Sin evaluaciones.', 'No evaluations yet.');

  // ── ACTIVITY LOG ───────────────────────────────────────────────────────────
  String get activityLog        => _t('REGISTRO DE ACTIVIDAD', 'ACTIVITY LOG');
  String get loadingActivity    => _t('Cargando actividad...', 'Loading activity...');
  String get errorLoadingActivityMsg => _t(
      'No se pudo cargar tu historial de actividad.\nVerifica tu conexión e intenta de nuevo.',
      'Could not load your activity history.\nCheck your connection and try again.');
  String get noRecordsTitle     => _t('SIN REGISTROS',         'NO RECORDS');
  String get noRecordsSubtitle  => _t(
      'La actividad reciente aparecera en este log.',
      'Recent activity will appear in this log.');

  // ── MY HOURS ───────────────────────────────────────────────────────────────
  String get activityTodaySection  => _t('ACTIVIDAD DE HOY',    'TODAY\'S ACTIVITY');
  String get recentSessionsSection => _t('JORNADAS RECIENTES',  'RECENT SESSIONS');
  String get calculatingHours   => _t('Calculando tus horas...','Calculating your hours...');
  String get errorLoadingHoursMsg  => _t(
      'No se pudieron cargar tus horas de trabajo.\nVerifica tu conexión e intenta de nuevo.',
      'Could not load your work hours.\nCheck your connection and try again.');
  String get noHoursYet         => _t('AÚN NO HAY HORAS CONSOLIDADAS', 'NO HOURS CONSOLIDATED YET');
  String get noHoursDesc        => _t(
      'Tu resumen aparecerá automáticamente cuando\nse registren sesiones durante la jornada.',
      'Your summary will appear automatically when\nsessions are recorded during the day.');
  String get refresh            => _t('Actualizar',             'Refresh');
  String get dailySummary       => _t('RESUMEN DE LA JORNADA',  'DAILY SUMMARY');
  String workedLabel(String h)  => _en ? '$h worked'            : '$h trabajados';
  String dailyGoalLabel(String h) => _en ? 'Daily goal: $h'    : 'Meta del día: $h';
  String get noShiftGoal        => _t('Aún no hay una meta de turno configurada',
                                      'No shift goal configured yet');
  String get completion         => _t('Cumplimiento',           'Completion');
  String get workStatus         => _t('Estado',                 'Status');
  String get review             => _t('Revisar',                'Review');
  String get expected           => _t('Esperado',               'Expected');
  String get breakTime          => _t('Descanso',               'Break');
  String get lateness           => _t('Tardanza',               'Lateness');
  String get extra              => _t('Extra',                  'Extra');
  String get absence            => _t('Ausencia',               'Absence');
  String get kpiSessions        => _t('Sesiones',               'Sessions');
  String get aspectsToReview    => _t('Aspectos para revisar',  'Aspects to review');
  String get active             => _t('Activo',                 'Active');
  String get kpiEvents          => _t('Eventos',                'Events');
  String get productive         => _t('Productivo',             'Productive');
  String workedOfExpected(String w, String e) =>
      _en ? '$w worked of $e expected' : '$w trabajados de $e esperados';

  // ── ACTIVITY HISTORY ───────────────────────────────────────────────────────
  String get loadingHistory     => _t('Cargando historial...',  'Loading history...');
  String get errorLoadingHistoryMsg => _t(
      'No se pudo cargar el historial de actividad.\nVerifica tu conexión e intenta de nuevo.',
      'Could not load the activity history.\nCheck your connection and try again.');
  String eventsCount(int n)     => _en ? '$n events' : '$n eventos';
  String get filterByStatus     => _t('Filtrar por estado',     'Filter by status');
  String get allStatuses        => _t('Todos los estados',      'All statuses');

  // ── EMPLOYEE DASHBOARD (error messages) ────────────────────────────────────
  String get errorLoadingWorkstationMsg => _t(
      'No se pudo cargar la información del puesto de trabajo. Desliza hacia abajo para reintentar.',
      'Could not load workstation information. Pull down to retry.');
  String get errorLoadingProductivityMsg => _t(
      'No se pudieron cargar tus métricas de productividad. Desliza hacia abajo para reintentar.',
      'Could not load your productivity metrics. Pull down to retry.');
  String get errorLoadingRecentActivityMsg => _t(
      'No se pudo cargar la actividad reciente. Desliza hacia abajo para reintentar.',
      'Could not load recent activity. Pull down to retry.');
  String totalTimeLabel(String t) => _en ? 'Total time: $t' : 'Tiempo total: $t';

  // ── PROFILE ────────────────────────────────────────────────────────────────
  String get profileName        => _t('Nombre',                 'Name');
  String get profileEmail       => 'Email';
  String get profileShift       => _t('Turno',                  'Shift');
  String get profileCompany     => _t('Empresa',                'Company');
  String get myStats            => _t('Mis estadísticas',       'My statistics');
  String get totalTasksLabel    => _t('Tareas totales',         'Total tasks');
  String get roleSuperAdmin     => 'Super Admin';
  String get roleCameraMonitor  => _t('Monitor de Cámara',      'Camera Monitor');
  String get roleEmployeeDisplay => _t('Empleado',              'Employee');

  // ── TASKS (extra) ──────────────────────────────────────────────────────────
  String taskMarkedAs(String s) => _en ? 'Task marked as "$s"'  : 'Tarea marcada como "$s"';
  String noTasksFiltered(String s) => _en ? 'No $s tasks'       : 'No hay tareas $s';
  String get noTasksAssignedAdmin    => _t('No has asignado tareas aún', 'No tasks assigned yet');
  String get noTasksAssignedEmployee => _t('No tienes tareas asignadas', 'No tasks assigned to you');
  String get createFirstTask    => _t('Crear primera tarea',    'Create first task');
  String get taskOverdueTag     => _t('¡Vencida!',              'Overdue!');
  String get taskStart          => _t('Iniciar',                'Start');
  String get taskComplete       => _t('Completar',              'Complete');
  String get taskAll            => _t('Todas',                  'All');
  String get taskDone           => _t('Completadas',            'Completed');

  // ── EVALUATIONS (extra) ────────────────────────────────────────────────────
  String get noEvalsAdmin       => _t(
      'Sin evaluaciones aún.\nCrea la primera evaluación con el botón +',
      'No evaluations yet.\nCreate the first one with the + button');
  String get confirmDeleteEvalTitle => _t('¿Eliminar evaluación?', 'Delete evaluation?');
  String get cannotUndo         => _t('Esta acción no se puede deshacer.',
                                      'This action cannot be undone.');
  String get noEvalsEmployee    => _t(
      'Aún no tienes evaluaciones de desempeño.\nComunícate con tu supervisor.',
      'You don\'t have any performance evaluations yet.\nContact your supervisor.');
  String get deleteEvaluation   => _t('Eliminar evaluación',    'Delete evaluation');

  // ── ANNOUNCEMENTS (extra) ──────────────────────────────────────────────────
  String get noAnnouncementsTitle    => _t('Sin comunicados activos',  'No active announcements');
  String get noAnnouncementsSubtitle => _t('Los nuevos comunicados aparecerán aquí',
                                           'New announcements will appear here');
  String get deleteAnnouncement      => _t('Eliminar comunicado',      'Delete announcement');
  String confirmDeleteAnnouncement(String t) =>
      _en ? 'Delete "$t"?' : '¿Eliminar "$t"?';
  String get announcementExpires     => _t('Vence:',                   'Expires:');

  // ── WORKSTATION CARD ───────────────────────────────────────────────────────
  String get noRecentActivity   => _t('SIN ACTIVIDAD RECIENTE', 'NO RECENT ACTIVITY');
  String get justNow            => _t('Hace un momento',         'Just now');
  String minutesAgo(int m)      => _en ? '$m min ago' : 'Hace $m min';

  // ── ACTIVITY EVENT TILE ────────────────────────────────────────────────────
  String confidenceLabel(int p) => _en ? 'CONFIDENCE: $p%'      : 'CONFIANZA: $p%';
  String workstationShort(String id) => _en ? 'STATION $id'     : 'PUESTO $id';
  String get nowLabel           => _t('AHORA',                   'NOW');

  // ── CHAT ──────────────────────────────────────────────────────────────────
  String get yesterday          => _t('Ayer',                    'Yesterday');

  // ── LEAVE REQUEST ─────────────────────────────────────────────────────────
  String durationDays(int n)    => _en
      ? '$n day${n == 1 ? '' : 's'}'
      : '$n día${n == 1 ? '' : 's'}';

  // ── ANALYTICS ─────────────────────────────────────────────────────────────
  String get statusLegend       => _t('Leyenda de estados',      'Status legend');
  String get noAnalyticsData    => _t('Sin datos de analiticas', 'No analytics data');
  String get noDataRegistered   => _t('Sin datos registrados',   'No data recorded');
  String get noAnalyticsDataDesc => _t(
      'Los datos apareceran cuando el sistema registre actividad de empleados.',
      'Data will appear when the system records employee activity.');
  String get stateDistribution  => _t('Distribución por estado', 'State distribution');
  String get dailyAttendance    => _t('Asistencia Diaria (Horas Reales)', 'Daily Attendance (Actual Hours)');
  String get noAttendanceRecords => _t(
      'No hay registros de asistencia en el scanner.',
      'No attendance records in scanner.');
  String get totalTime          => _t('Tiempo total',             'Total time');
  String get unknownEmployee    => _t('Empleado',                 'Employee');
  String get details            => _t('Detalle',                  'Details');
  String noDataForEmployee(String name) => _en ? 'No data for $name' : 'Sin datos para $name';
  String get noEventsInPeriod   => _t(
      'No se han registrado eventos\nen el periodo seleccionado.',
      'No events recorded\nin the selected period.');
  String totalHoursInOffice(String t) => _en ? 'Total office hours: $t' : 'Total horas en oficina: $t';
  String lastActivity(String time)    => _en ? 'Last activity: $time' : 'Última actividad: $time';
  String clockInOut(String i, String o) => _en ? 'In: $i - Out: $o' : 'Entrada: $i - Salida: $o';

  // ── ANOMALY LABELS ─────────────────────────────────────────────────────────
  String get anomalyOpenSession => _t(
      'Hay una sesion sin cierre confirmado.',
      'There is an open session without a confirmed close.');
  String get anomalyTooManySegments => _t(
      'Se detectaron demasiadas entradas o salidas en el dia.',
      'Too many entries or exits were detected in the day.');
  String get anomalyRepeatedAbsences => _t(
      'Se registraron varias ausencias durante la jornada.',
      'Several absences were recorded during the shift.');
  String formatAnomalyLabel(String value) {
    switch (value) {
      case 'open_session':             return anomalyOpenSession;
      case 'too_many_segments':        return anomalyTooManySegments;
      case 'repeated_absence_events':  return anomalyRepeatedAbsences;
      default: return value.replaceAll('_', ' ');
    }
  }
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
