/// Cadenas de texto centralizadas de WorkSense.
/// Agrupa todas las cadenas de UI por feature/screen.
abstract final class AppStrings {
  AppStrings._();

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
  static const String bodyMustBeVisible =
      'Asegúrate de que tu cuerpo sea visible';
  static const String correctPosition = 'Posicion correcta';
  static const String scanComplete = 'Escaneo completado';
  static const String frameProcessingError = 'Error al procesar el frame';
  static const String sampleCaptured = 'Muestra capturada';
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
  static const String saveChanges = 'Guardar cambios';
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
  static const String welcome = 'Bienvenido';
  static const String scheduleAndActivityHint =
      'Aquí verás tu horario y estado de actividad.';

  // ─────────────────────────────────────────────────────────
  // SYNC
  // ─────────────────────────────────────────────────────────
  static const String offlineMode = 'Modo Offline';
  static const String onlineAndSynced = 'Online y Sincronizado';

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
}
