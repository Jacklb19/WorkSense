/// Cadenas de texto centralizadas de WorkSense.
/// Agrupa todas las cadenas de UI por feature/screen.
abstract final class AppStrings {
  AppStrings._();

  // ── NAVIGATION ────────────────────────────────────────────────────────────
  static const String navDashboard = 'Dashboard';
  static const String navEmployees = 'Empleados';
  static const String navWorkstations = 'Puestos';
  static const String navSettings = 'Ajustes';
  static const String navHome = 'Inicio';
  static const String navActivity = 'Actividad';

  // ─────────────────────────────────────────────────────────
  // GENERAL
  // ─────────────────────────────────────────────────────────
  static const String error = 'Error';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String retry = 'Reintentar';
  static const String loading = 'Cargando...';
  static const String errorPrefix = 'Error: ';
  static const String somethingWentWrong = 'Algo salió mal';

  // ─────────────────────────────────────────────────────────
  // AUTH / LOGIN
  // ─────────────────────────────────────────────────────────
  static const String emailLabel = 'Correo electrónico';
  static const String emailHint = 'admin@empresa.com';
  static const String passwordLabel = 'Contraseña';
  static const String loginButton = 'Iniciar sesión';
  static const String copyright = 'WorkSense © 2026';
  static const String subtitle = 'Monitoreo inteligente de actividad';
  static const String emailRequired = 'Ingresa tu correo electrónico.';
  static const String emailInvalid = 'Correo electrónico inválido.';
  static const String passwordRequired = 'Ingresa tu contraseña.';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 6 caracteres.';

  // ─────────────────────────────────────────────────────────
  // ADMIN DASHBOARD
  // ─────────────────────────────────────────────────────────
  static const String adminTitle = 'WorkSense (Admin)';
  static const String controlPanel = 'Panel de Control';
  static const String historyTooltip = 'Historial de actividad';
  static const String analyticsTooltip = 'Analíticas';
  static const String employeesTooltip = 'Empleados';
  static const String workstationsTooltip = 'Puestos de Trabajo';
  static const String settingsTooltip = 'Configuración';
  static const String startKiosk = 'Iniciar Kiosco';
  static const String noWorkstations = 'Sin puestos registrados';
  static const String noWorkstationsDescription =
      'Configura los puestos de trabajo desde\nla consola de administración.';
  static const String startKioskMode = 'Iniciar modo kiosco';
  static const String errorLoadingData = 'Error al cargar datos';

  // ─────────────────────────────────────────────────────────
  // KIOSK WAITING
  // ─────────────────────────────────────────────────────────
  static const String configureDevice = 'CONFIGURAR DISPOSITIVO';
  static const String selectDeviceFunction =
      'Selecciona la función que este dispositivo cumplirá en la oficina.';
  static const String setAsEntryKiosk = 'ESTABLECER COMO KIOSCO DE ENTRADA';
  static const String assignMonitor = 'O asigna este dispositivo a un monitor personal:';
  static const String selectCamera = 'Selecciona una cámara / puesto...';
  static const String logoutDevice = 'CERRAR SESIÓN DEL DISPOSITIVO';

  // ─────────────────────────────────────────────────────────
  // ENTRANCE KIOSK
  // ─────────────────────────────────────────────────────────
  static const String kioskAccessFrontal = 'Kiosco de Acceso Frontal';
  static const String welcome = '¡BIENVENIDO!';
  static const String confirmClockOut = 'Confirmar cierre de jornada';
  static const String confirmExitQuestion =
      '¿Estás seguro que deseas cerrar sesión?';
  static const String signIn = 'INICIAR SESIÓN';
  static const String finishQuestion = '¿FINALIZAR?';
  static const String clockOut = 'CERRAR SESIÓN';
  static const String success = '¡ÉXITO!';
  static const String workstation = 'ESTACIÓN DE TRABAJO';
  static const String pauseLabel = 'EN PAUSA';
  static const String waitingLabel = 'EN ESPERA';
  static const String facialCapture = 'EMPEZAR CAPTURA';
  static const String pauseByBreak = 'El monitoreo está pausado por descanso.';
  static const String waitingForScan = 'Esperando escaneo...';
  static const String scanningRequired =
      'Se requiere una captura facial inicial para habilitar el reconocimiento en tiempo real.';
  static const String noEmployeeAssignedKiosk =
      'No hay un empleado asignado a este puesto de trabajo.';
  static const String closeMonitor = 'Cerrar monitor';
  static const String workstationId = 'Puesto de trabajo: ';

  // ─────────────────────────────────────────────────────────
  // EMPLOYEE SCAN
  // ─────────────────────────────────────────────────────────
  static const String biometricEnrollment = 'ENROLAMIENTO BIOMÉTRICO';
  static const String captureSample = 'Capturar muestra biométrica';
  static const String captureUnavailable = 'No disponible para captura';
  static const String keepFrontCamera = 'Mantente frente a la cámara un momento';
  static const String lookStraight = 'Mira directo a la cámara';
  static const String turnLeft = 'Gira levemente la cabeza hacia tu izquierda';
  static const String turnRight = 'Gira levemente la cabeza hacia tu derecha';
  static const String lookUp = 'Levanta levemente la cabeza';
  static const String lookDown = 'Inclina levemente la cabeza hacia abajo';
  static const String lookFrontAgain = 'De frente otra vez para confirmar';
  static const String turnLeftAgain = 'Gira de nuevo levemente a la izquierda';
  static const String turnRightAgain = 'Gira de nuevo levemente a la derecha';
  static const String adjustPosition = 'Ajusta tu posición';

  // ─────────────────────────────────────────────────────────
  // FORMS
  // ─────────────────────────────────────────────────────────
  static const String shiftDetails = 'DETALLES DEL TURNO';
  static const String workSchedule = 'JORNADA LABORAL';
  static const String breakLabel = 'RECESO / ALMUERZO';
  static const String activateBreak = 'Activar si aplica hora de almuerzo';
  static const String saveShift = 'GUARDAR TURNO';
  static const String identity = 'IDENTIDAD';
  static const String credentials = 'CREDENCIALES';
  static const String registerEmployee = 'REGISTRAR EMPLEADO';
  static const String saveChanges = 'Guardar cambios';
  static const String deleteEmployeeConfirm =
      '¿Estás seguro de que deseas eliminar permanentemente este colaborador? '
      'Esta acción eliminará su acceso y todos sus datos de asistencia.';
  static const String deleteEmployeeTitle = 'Eliminar colaborador';
  static const String employeeDeleted = 'Colaborador eliminado';

  // ─────────────────────────────────────────────────────────
  // EMPLOYEE DASHBOARD
  // ─────────────────────────────────────────────────────────
  static const String mySpace = 'Mi Espacio';
  static const String employee = 'Empleado';
  static const String todaySummary = 'Resumen de tu actividad de hoy';
  static const String assignedWorkstation = 'PUESTO ASIGNADO';
  static const String myProductivityToday = 'MI PRODUCTIVIDAD HOY';
  static const String recentActivityLive = 'ACTIVIDAD RECIENTE (EN VIVO)';
  static const String noAssignedWorkstation = 'Sin puesto asignado';
  static const String noAssignedWorkstationDescription =
      'Espera a que un administrador te asigne a un puesto de trabajo para comenzar el monitoreo.';
  static const String monitoringAssigned = 'Monitoreo asignado';
  static const String verifyingWorkstation = 'Verificando puesto...';
  static const String errorLoadingWorkstation =
      'Error al cargar la información del puesto.';
  static const String noActivityToday =
      'Aún no hay actividad registrada para ti el día de hoy.';
  static const String noRecentEvents = 'No hay eventos recientes.';
  static const String calculatingTime = 'Calculando tiempo...';
  static const String couldNotLoadMetrics =
      'No se pudieron obtener las métricas.';
  static const String errorLoadingHistory = 'Error cargando historial';
  static const String totalTime = 'Tiempo total: ';
  static const String working = 'Trabajando';
  static const String distracted = 'Distraído';
  static const String fatigue = 'Fatiga';
  static const String myGlobalHistory = 'Mi historial global';

  // ─────────────────────────────────────────────────────────
  // KIOSK
  // ─────────────────────────────────────────────────────────
  static const String cameraPermissionDenied =
      'Permiso de cámara denegado. Actívalo en configuración.';
  static const String startingMonitoring = 'Iniciando monitoreo...';
  static const String exitKioskTitle = 'Salir del modo kiosco';
  static const String exitKioskMessage =
      '¿Deseas cerrar sesión y salir del monitoreo?';
  static const String exitButton = 'Salir';
  static const String backToDashboard = 'Volver al dashboard';
  static const String noBiometricProfile = 'Empleado sin perfil biométrico';
  static const String noEmployeeAssigned = 'Estación sin empleado asignado';
  static const String scanEmployeeDescription =
      'Escanea al empleado para que la cámara pueda reconocerlo y seguirlo.';
  static const String assignEmployeeDescription =
      'Asigna un empleado a esta estación desde el panel de administración.';
  static const String scanEmployee = 'Escanear empleado';

  // ─────────────────────────────────────────────────────────
  // EMPLOYEE SCAN
  // ─────────────────────────────────────────────────────────
  static const String positionInFrontOfCamera =
      'Posiciónate frente a la cámara';
  static const String comeCloser = 'Acércate a la cámara';
  static const String onlyOnePersonAllowed =
      'Solo debe estar el empleado en cámara';
  static const String scanComplete = 'Escaneo completado';
  static const String frameProcessingError = 'Error al procesar el frame';
  static const String noFaceDetected = 'No se detectó rostro. Acércate más.';
  static const String multiplePeopleDetected =
      'Solo debe estar el empleado en cámara.';
  static const String lowConfidence =
      'Poca iluminación o distancia incorrecta.';
  static const String noPoseDetected =
      'Cuerpo no detectado. Asegúrate de ser visible.';
  static const String invalidSignature = 'Postura no válida. Quédate quieto.';
  static const String scanCompleteStarting =
      'Escaneo completado. Iniciando monitoreo...';
  static const String repeatScan = 'Repetir escaneo';
  static const String tryAgain = 'Intentar de nuevo';
  static const String saveProfileError = 'Error al guardar el perfil: ';
  static const String errorCameraInit = 'Error al iniciar cámara';
  static const String onlyOnePerson =
      'Solo debe estar el empleado en cámara';
  static const String bodyMustBeVisible =
      'Asegúrate de que tu cuerpo sea visible';
  static const String improveLighting =
      'Mejora la iluminación o tu posición';
  static const String correctPosition = 'Posición correcta';
  static const String sampleCaptured = 'Buena captura ✓';
  static const String outsideArea = 'EMPLEADO FUERA DE CÁMARA';

  // ─────────────────────────────────────────────────────────
  // CAMERA / OVERLAY
  // ─────────────────────────────────────────────────────────
  static const String startingCamera = 'Iniciando cámara...';
  static const String employeeOutsideArea = 'El empleado no está en el área';

  // ─────────────────────────────────────────────────────────
  // EMPLOYEES
  // ─────────────────────────────────────────────────────────
  static const String employees = 'Empleados';
  static const String editEmployee = 'Editar Empleado';
  static const String newEmployee = 'Nuevo Empleado';
  static const String addEmployee = 'Agregar empleado';
  static const String deleteEmployee = 'Eliminar empleado';
  static const String employeeUpdated = 'Empleado actualizado correctamente.';
  static const String employeeAdded = 'Empleado agregado correctamente.';
  static const String nameLabel = 'Nombre completo';
  static const String nameHint = 'Ej. Juan Pérez';
  static const String lastNameLabel = 'Apellidos';
  static const String lastNameHint = 'Ej. Pérez';
  static const String emailEmployeeHint = 'ejemplo@empresa.com';
  static const String passwordTempLabel = 'Contraseña (temporal)';
  static const String passwordTempHint = 'Mínimo 6 caracteres';
  static const String roleLabel = 'Rol';
  static const String roleEmployee = 'Empleado (Kiosk)';
  static const String roleAdmin = 'Administrador';
  static const String nameRequired = 'El nombre es obligatorio.';
  static const String nameMinLength =
      'El nombre debe tener al menos 2 caracteres.';
  static const String nameMaxLength =
      'El nombre no puede exceder 100 caracteres.';
  static const String lastNameRequired = 'Los apellidos son obligatorios.';
  static const String emailRequired2 = 'El correo es obligatorio.';
  static const String emailInvalid2 = 'Correo inválido.';
  static const String passwordRequiredNew =
      'La contraseña es obligatoria para nuevos usuarios.';
  static const String passwordMinLength =
      'Debe tener al menos 6 caracteres.';
  static const String noEmployees = 'Sin empleados registrados';
  static const String addEmployeeHint = 'Agrega empleados con el botón +';
  static const String confirmDeleteEmployee =
      '¿Eliminar a "\$name"? Esta acción no se puede deshacer.';

  // ─────────────────────────────────────────────────────────
  // WORKSTATIONS
  // ─────────────────────────────────────────────────────────
  static const String workstations = 'Estaciones de Trabajo';
  static const String newWorkstation = 'Nueva Estación';
  static const String workstationNameLabel = 'Nombre del puesto';
  static const String deviceIdLabel = 'ID del dispositivo';
  static const String deviceIdRequired = 'El ID no puede estar vacío';
  static const String workstationNameRequired = 'Ingresa un nombre';
  static const String assignEmployeeOptional = 'Asignar Empleado (Opcional)';
  static const String none = 'Ninguno';
  static const String geolocation = 'Geolocalización';
  static const String useCurrentLocation = 'Usar mi ubicación actual';
  static const String locationSuccess = 'Ubicación obtenida con éxito.';
  static const String saveWorkstation = 'Guardar Estación';
  static const String workstationSaved = 'Estación guardada exitosamente';
  static const String deleteWorkstation = 'Eliminar Estación';
  static const String noWorkstationsRegistered =
      'No hay estaciones de trabajo registradas.';
  static const String workstationDeleted =
      'Estación eliminada (Sincronización pendiente)';
  static const String noEmployeesRegistered = 'No hay empleados registrados';
  static const String errorLoadingEmployees = 'Error al cargar empleados: ';
  static const String locationServicesDisabled =
      'Los servicios de ubicación están deshabilitados.';
  static const String locationPermissionDenied =
      'Los permisos de ubicación fueron denegados.';
  static const String locationPermissionPermanentlyDenied =
      'Los permisos de ubicación están denegados permanentemente.';

  // ─────────────────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────────────────
  static const String settings = 'Configuración';
  static const String accountSection = 'Cuenta';
  static const String user = 'Usuario';
  static const String notAvailable = 'No disponible';
  static const String activityAnalysis = 'Análisis de Actividad';
  static const String analysisInterval = 'Intervalo de análisis';
  static const String analysisIntervalDescription =
      'Frecuencia con la que se analiza la actividad del trabajador. '
      'Valores menores son más precisos pero consumen más batería.';
  static const String detectionThresholds =
      'Umbrales de Detección (solo lectura)';
  static const String maxYawLabel = 'Ángulo máximo de giro (yaw)';
  static const String minPitchLabel = 'Ángulo mínimo de inclinación (pitch)';
  static const String maxRollLabel = 'Ángulo máximo de volteo (roll)';
  static const String minPoseConfidenceLabel = 'Confianza mínima de pose';
  static const String inactivityThresholdLabel = 'Umbral de inactividad';
  static const String about = 'Acerca de';
  static const String version = 'Versión';
  static const String application = 'Aplicación';
  static const String logout = 'Cerrar sesión';
  static const String logoutConfirmation = '¿Deseas cerrar sesión?';

  // ─────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────
  static const String analytics = 'Analíticas';
  static const String refresh = 'Actualizar';
  static const String today = 'Hoy';
  static const String thisWeek = 'Esta semana';
  static const String statesLegend = 'Leyenda de estados';
  static const String statesLegendTooltip = 'Leyenda de estados';
  static const String noAnalyticsData = 'Sin datos de analíticas';
  static const String analyticsDescription =
      'Los datos aparecerán cuando el sistema\nregistre actividad de empleados.';
  static const String noDataFor = 'Sin datos para';
  static const String noEventsPeriod =
      'No se han registrado eventos\nen el período seleccionado.';
  static const String noAttendanceRecords =
      'No hay registros de asistencia en el escáner.';
  static const String noDataRegistered = 'Sin datos registrados';
  static const String detail = 'Detalle';
  static const String employeeNotFound = 'Empleado no encontrado';
  static const String distributionByState = 'Distribución por estado';
  static const String totalTimeLabel = 'Tiempo total';
  static const String eventsLabel = 'Eventos';
  static const String productivity = 'Productividad';
  static const String lastActivity = 'Última actividad: ';

  // ─────────────────────────────────────────────────────────
  // HISTORY
  // ─────────────────────────────────────────────────────────
  static const String activityHistory = 'Historial de Actividad';
  static const String filterByState = 'Filtrar por estado';
  static const String allStates = 'Todos los estados';
  static const String noResults = 'Sin resultados';
  static const String noEventsRegistered = 'Sin eventos registrados';
  static const String removeFilter = 'Quitar filtro';

  // ─────────────────────────────────────────────────────────
  // HOME EMPLOYEE
  // ─────────────────────────────────────────────────────────
  static const String myEmployeePanel = 'Mi Panel de Empleado';
  static const String welcomeGreeting = 'Bienvenido';
  static const String scheduleAndActivityHint =
      'Aquí verás tu horario y estado de actividad.';

  // ─────────────────────────────────────────────────────────
  // SYNC
  // ─────────────────────────────────────────────────────────
  static const String offlineMode = 'Modo Offline';
  static const String onlineAndSynced = 'Online y Sincronizado';
  static const String pendingSync = 'pendientes de sincronización';

  // ─────────────────────────────────────────────────────────
  // ALERTS
  // ─────────────────────────────────────────────────────────
  static const String alertAbsent = '⚠️ Empleado ausente del puesto';
  static const String alertDistracted = '⚠️ Empleado distraído';

  // ─────────────────────────────────────────────────────────
  // ROUTER
  // ─────────────────────────────────────────────────────────
  static const String configuration = 'Configuración';
  static const String deviceNotConfigured = 'Dispositivo no configurado';
  static const String myActivity = 'Mi Actividad';
  static const String employeePanelComingSoon =
      'Panel de empleado — Próximamente';
  static const String myHours = 'Mis Horas';
  static const String myHoursComingSoon = 'Mis horas — Próximamente';
  static const String pageNotFound = 'Página no encontrada';
  static const String routeNotFound = 'Ruta no encontrada';
  static const String goToDashboard = 'Ir al dashboard';

  // ─────────────────────────────────────────────────────────
  // ERROR WIDGET
  // ─────────────────────────────────────────────────────────
  static const String retryButton = 'Reintentar';

  // ─────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────
static const String myProfile = 'Mi Perfil';
  static const String nameLabelProfile = 'Nombre';
  static const String emailLabelProfile = 'Email';
  static const String roleLabelProfile = 'Rol';
  static const String shiftLabel = 'Turno';
  static const String noShiftAssigned = 'Sin turno asignado';
  static const String companyLabel = 'Empresa';
  static const String myStatistics = 'Mis estadísticas';
  static const String totalTasks = 'Tareas totales';
  static const String completedTasks = 'Completadas';
  static const String pendingTasksLabel = 'Pendientes';
  static const String requestedLeaves = 'Permisos solicitados';
  static const String approvedLeaves = 'Aprobados';
  static const String pendingLeaves = 'Permisos pendientes';
  static const String roleAdminDisplay = 'Administrador';
  static const String roleSuperAdminDisplay = 'Super Admin';
  static const String roleCameraMonitorDisplay = 'Monitor de Cámara';
  static const String roleEmployeeDisplay = 'Empleado';

  // ─────────────────────────────────────────────────────────
  // WORKSTATION CARD / DASHBOARD TILES
  // ─────────────────────────────────────────────────────────
  static const String noRecentActivity = 'SIN ACTIVIDAD RECIENTE';
  static const String justNow = 'Hace un momento';
  static const String minutesAgo = 'Hace \$min min';
  static const String confidence = 'CONFIANZA';
  static const String now = 'AHORA';
  static const String minutesAbbrev = '\$minM';
  static const String workstationPrefix = 'PUESTO';
  static const String noRegisteredToday = 'Sin actividad registrada hoy';
  static const String computing = 'Calculando...';

  // ─────────────────────────────────────────────────────────
  // KIOSK
  // ─────────────────────────────────────────────────────────
  static const String facialRecognitionSuccess = 'Rostro reconocido con éxito';
  static const String scannerActive = 'SCANNER ACTIVO';
  static const String worksenseBrand = 'WORKSENSE';
}
