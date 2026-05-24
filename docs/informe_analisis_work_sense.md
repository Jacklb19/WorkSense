# Informe de Analisis Tecnico - WorkSense

## 1. Alcance y criterio del analisis

Este informe cubre el proyecto completo con foco en:

- `lib/` y la logica real de negocio.
- `supabase/` como backend operativo.
- `android/` solo en lo que afecta permisos, build y despliegue.
- `test/` y `tmp/` para medir calidad y ruido del workspace.

Se omitieron deliberadamente:

- Archivos generados como `*.g.dart`.
- Artefactos de build (`build/`, `.dart_tool/`).
- Detalles puramente visuales o cosmeticos que no cambian la logica del producto.

## 2. Que hace la app

`WorkSense` es una app Flutter orientada al control de asistencia y monitoreo de actividad laboral con IA.

Su flujo funcional real es este:

1. Un administrador crea empleados, puestos de trabajo y turnos.
2. Cada workstation se asigna a un empleado.
3. En esa workstation se hace un enrolamiento biometrico:
   - 8 muestras faciales.
   - firma corporal basada en pose.
   - ROI o zona de deteccion del puesto.
4. Un kiosco de entrada reconoce al empleado con rostro + prueba de parpadeo.
5. Ese kiosco hace `clock in` o `clock out` y enciende o apaga la workstation remota.
6. La workstation, cuando queda activa, abre el monitoreo continuo por camara.
7. El monitor clasifica estados como:
   - `trabajando`
   - `inactivo`
   - `distraido`
   - `fatiga`
   - `ausente`
   - `fueraDelArea`
   - `noIdentificado`
8. Los eventos se guardan localmente en SQLite/Drift y luego se sincronizan a Supabase.
9. A partir de asistencia + actividad se construyen:
   - resumenes diarios de trabajo
   - rollups de actividad
   - analiticas por empleado

En resumen: no es solo una app de asistencia. Es una plataforma hibrida de asistencia, control de puesto y analitica de productividad basada en vision artificial.

## 3. Arquitectura general

La arquitectura es una mezcla de capas limpias con decisiones pragmaticas:

- `domain/`: entidades y contratos.
- `data/`: datasource local Drift, datasource remoto Supabase y repositorios.
- `features/`: UI, providers y casos de uso especificos por modulo.
- `shared/`: sincronizacion, conectividad y widgets reutilizables.
- `core/`: routing, tema, constantes y navegacion.

Patrones visibles:

- Estado con Riverpod.
- Navegacion con GoRouter.
- Persistencia offline-first con Drift.
- Sincronizacion eventual con una cola local (`sync_queue_entries`).
- IA on-device con:
  - ML Kit para rostro y pose.
  - TFLite MobileFaceNet para embeddings faciales.

Fortalezas:

- La app si tiene separacion razonable entre UI, datos y dominio.
- El flujo offline/sync esta pensado, no es improvisado.
- La parte de IA esta encapsulada de forma relativamente coherente dentro de `camera_monitor`.

Debilidades:

- La arquitectura no es consistente en todos los modulos.
- Hay providers duplicados, flujos incompletos y varias piezas a medio camino entre PoC y producto.
- La seguridad de secretos y biometria esta mal resuelta.

## 4. Roles y que puede hacer cada uno

### 4.1 `admin`

Segun el router y las pantallas actuales, un admin puede:

- iniciar sesion.
- ver dashboard administrativo.
- ver empleados.
- crear empleados.
- editar parcialmente empleados.
- eliminar empleados.
- ver workstations.
- crear workstations.
- eliminar workstations.
- ver lista de turnos.
- crear turnos.
- ver analiticas por empleado.
- abrir el kiosco de entrada.

Limitaciones actuales del admin:

- no hay flujo completo de edicion de turnos.
- no hay flujo de edicion de workstations.
- no puede crear desde UI usuarios `cameraMonitor` ni `superAdmin`.
- el flujo de edicion de empleado es incompleto.

### 4.2 `superAdmin`

En la practica hoy funciona igual que `admin`.

No existe una experiencia diferenciada ni permisos especiales visibles en frontend.

### 4.3 `employee`

Lo que deberia poder hacer por las pantallas construidas:

- ver dashboard personal.
- ver actividad reciente.
- ver resumen de horas.
- ver historico personal.
- ver ajustes.

Lo que realmente puede hacer por routing:

- `/dashboard`
- `/history`
- `/settings`

Hallazgo importante:

- Las pantallas `my-hours`, `my-activity` y `home-employee` existen, pero el redirect del router las bloquea para el rol `employee`.
- El historial accesible por `employee` usa un provider global, no uno personal.

### 4.4 `cameraMonitor`

Es el rol operativo del dispositivo.

Puede:

- entrar a `kiosk_waiting`.
- elegir si el dispositivo sera:
  - kiosco de entrada
  - monitor de workstation
- operar el kiosco de monitoreo.

Es el rol mas cercano a un dispositivo o terminal fisica, no a un usuario humano normal.

## 5. Estructura del proyecto, carpeta por carpeta

## 5.1 Raiz del proyecto

- `pubspec.yaml`: define una app Flutter con Riverpod, Supabase, Drift, ML Kit, TFLite y varias dependencias que hoy no parecen usarse.
- `.env`: contiene configuracion sensible. Este archivo es critico y hoy esta mal manejado.
- `README.md`: muy pobre; no documenta flujos reales, setup, roles ni seguridad.
- `analysis_options.yaml`: lints basicos.
- `tmp/`: contiene pruebas/manuales y ruido de analisis. Tambien rompe `flutter analyze` completo.

## 5.2 `lib/core`

### `main.dart`

- arranca Flutter.
- carga `.env`.
- valida `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- inicializa Supabase.
- levanta `ProviderScope`.

Observaciones:

- lee `session` pero no la usa.
- el bootstrap ignora por completo que `.env` tambien trae secretos que no deberian viajar en cliente.

### `core/routing/app_router.dart`

Es el cerebro de acceso por rol.

Define rutas para:

- login
- dashboard
- empleados
- workstations
- shifts
- kioscos
- analytics
- settings

Problemas importantes:

- `employee` queda limitado a solo 3 rutas y deja pantallas construidas inaccesibles.
- el router importa `features/auth/presentation/providers/auth_provider.dart` sin usarlo.

### `core/navigation/*`

- `ScaffoldWithBottomNav`: arma tabs segun rol.
- `nav_destinations.dart`: define tabs de admin y empleado.
- `app_bottom_nav_bar.dart`: UI inferior.

Observacion:

- la navegacion real del empleado no refleja todo lo que el modulo de dashboard ofrece.

### `core/constants/*`

- `app_routes.dart`: rutas centralizadas.
- `app_constants.dart`: ids default, nombres de tablas, geofence, sync.
- `ai_thresholds.dart`: todos los umbrales del pipeline IA.
- `app_strings.dart`: centraliza muchos textos.

Lo bueno:

- los thresholds de IA estan bien concentrados en un solo punto.

Lo malo:

- hay mezcla de constantes de negocio, infraestructura y UX en el mismo bloque.
- `defaultCompanyId` funciona como muleta de multitenancy.

### `core/theme/*`

Tema, colores y tipografias. Util para UI, poco impacto de negocio.

## 5.3 `lib/domain`

### Entidades

- `Employee`: modelo base del colaborador.
- `Workstation`: puesto de trabajo, dispositivo, geofence, propietario, ROI y estado.
- `Shift`: turno laboral.
- `AttendanceLog`: entrada/salida diaria.
- `ActivityEvent`: evento atomico de actividad.
- `ActivityState`: estados de clasificacion.
- `Company`: entidad basica de empresa.

Observaciones:

- `Employee` es demasiado pobre para el dominio real.
- no modela email, apellido ni rol, aunque backend si los maneja.
- el dominio esta desalineado con la tabla `employees`.

### Repositorios

Hay contratos para:

- auth
- employee
- workstation
- shift
- attendance
- activity

Problema:

- algunos contratos ya mezclan conceptos del feature de IA.
- por ejemplo `EmployeeRepository` conoce `BodySignature` y `EmployeeProfile`, lo que rompe pureza de dominio.

## 5.4 `lib/data`

### `datasources/local/database.dart`

Es una de las piezas mas importantes del proyecto.

Gestiona:

- `CompanyRecords`
- `EmployeeRecords`
- `ShiftRecords`
- `AttendanceLogs`
- `WorkstationRecords`
- `ActivityEntries`
- `SyncQueueEntries`

Tambien crea tablas auxiliares:

- `workstation_roi_cache`
- `workstation_profile_snapshots`
- `daily_work_summaries`
- `activity_rollups`

Lo que hace bien:

- soporta offline-first.
- guarda actividad, asistencia y cola de sync.
- soporta snapshots biométricos y ROI.

Riesgos:

- guarda biometria sensible en texto plano.
- tambien guarda payloads agregados y snapshots en texto plano.

### `datasources/remote/supabase_datasource.dart`

Encapsula:

- `upsert`, `patch`, `delete`
- fetch de empleados, workstations, shifts
- fetch de activity y attendance
- auth
- invocacion de Edge Function `create-employee`

Problemas:

- varios queries usan `companyId` opcional, pero el resto del sistema no siempre garantiza ese dato.
- mezcla sync generico, auth y fetches especificos en la misma clase.

### Repositorios

#### `EmployeeRepositoryImpl`

Hace:

- guardar empleado local + cola sync
- obtener empleados
- borrar empleado
- guardar embeddings
- enrolar empleado en workstation

Problemas:

- al editar empleado se usa el mismo `saveEmployee`, pero la entidad no contiene apellido/email/rol.
- se actualiza `createdAt` de forma poco confiable en algunos flujos.

#### `WorkstationRepositoryImpl`

Hace:

- guardar workstation local + cola sync
- ver listado
- borrar workstation

Problemas:

- no hay edicion.
- el listado no filtra por compania.

#### `ShiftRepositoryImpl`

Hace:

- crear/actualizar turnos
- consultarlos
- asignarlos a empleados

Problema importante:

- el dominio soporta turnos nocturnos.
- la UI los bloquea.

#### `AttendanceRepositoryImpl`

Hace:

- `clockIn`
- `clockOut`
- obtener sesion abierta
- obtener sesiones del dia
- obtener logs por rango

Problemas:

- el `status` siempre entra como `ON_TIME`.
- aun no cruza con turno real para tardanza o salida temprana.
- no contempla bien overnight shifts.

#### `ActivityRepositoryImpl`

Hace:

- guardar eventos
- observar feed reciente
- consultar por empleado o por rango

Es correcto para el objetivo, aunque su uso en UI no siempre respeta privacidad o tenancy.

#### `SyncRepositoryImpl`

Es una cola outbox simple:

- encola operaciones
- lista pendientes
- marca sincronizado
- elimina de cola

## 5.5 `lib/shared`

### `shared/domain/usecases/process_sync_queue_use_case.dart`

Es otra pieza central.

Hace:

- push de cola local a Supabase.
- batch de `activity_events`.
- push de resúmenes calculados.
- limpieza TTL de eventos crudos.
- pull de empleados, workstations y shifts remotos a local.

Fortalezas:

- hay una idea clara de sync bidireccional.
- el flujo intenta ser resiliente.

Problemas:

- el pull destructivo depende de `companyId` correcto.
- la logica de sync esta muy grande y concentra demasiadas responsabilidades.
- el pull local no filtra luego por company en muchos providers de consumo.

### `shared/domain/usecases/worktime_reconciler.dart`

Construye:

- `daily_work_summaries`
- `activity_rollups`

Problemas:

- usa reglas bastante heuristicas.
- depende solo de data local.
- algunas anomalias son muy simplificadas.

### Providers compartidos

- `current_user_provider.dart`: resuelve usuario y rol desde metadata de Supabase.
- `connectivity_provider.dart`: detecta red.
- `sync_state_provider.dart`: dispara sync automatico por login, conectividad y cola pendiente.
- `shared/providers/auth_provider.dart`: provider de auth duplicado respecto al modulo de auth.

Problema:

- hay duplicacion real entre auth compartido y auth del feature.

## 5.6 `lib/features/auth`

### `features/auth/presentation/providers/auth_provider.dart`

Implementa:

- datasource provider
- auth repository provider
- sign in/out use cases
- `LoginNotifier`

### `login_screen.dart`

Pantalla de login personalizada.

Hace:

- captura correo y password
- escucha autenticacion
- redirige a dashboard

Problemas:

- el branding es fijo y duro.
- hay strings directas en la pantalla en lugar de usar siempre `AppStrings`.

## 5.7 `lib/features/employees`

### `employees_provider.dart`

Es el provider principal del modulo.

Hace:

- levantar repo local
- exponer stream/future local
- construir `adminEmployeesProvider` mezclando local y remoto
- manejar guardado y borrado de empleados

Problemas:

- `adminEmployeesProvider` mezcla empleados locales sin filtrar por company.
- al crear usa edge function.
- al editar usa solo persistencia local/cola, no un flujo claro remoto.

### `employee_form_screen.dart`

Hace:

- crear empleado
- editar parcialmente empleado
- asignar turno

Problemas:

- al editar no precarga apellido, correo ni rol.
- el flujo de edicion no es consistente con el modelo real.

### `employees_list_screen.dart`

Hace:

- lista empleados.
- permite editar y eliminar.
- fuerza sync tras borrar.

Riesgo:

- el origen de datos mezclado puede mostrar empleados fuera de compania si viven en DB local.

## 5.8 `lib/features/workstations`

### `workstations_provider.dart`

Expone repo y casos de uso.

### `workstation_form_screen.dart`

Hace:

- crear workstation
- capturar geolocalizacion
- asignar propietario
- definir ROI preset

Problemas:

- solo crea, no edita.
- exige empleado asignado aunque algunos textos lo presentan como opcional.
- genera `deviceId` random, no un identificador de hardware real.

### `workstations_list_screen.dart`

Hace:

- listar
- borrar

Problemas:

- no edita.
- no filtra por compania.

## 5.9 `lib/features/dashboard`

### Providers

#### `dashboard_provider.dart`

Expone:

- workstations
- eventos recientes globales
- ultimo evento por workstation

Problema:

- el feed es global.

#### `employee_dashboard_provider.dart`

Expone:

- workstation asignada
- eventos recientes del empleado
- analitica personal
- summaries diarios

Problema:

- depende del provider admin para parte de la logica.

#### `admin_analytics_provider.dart`

Es el modulo analitico real.

Hace:

- definir rango `today` / `thisWeek`
- fusionar eventos locales + remotos
- construir analitica por empleado
- fusionar asistencia local + remota

Problemas:

- mezcla datos de diferentes fuentes sin una capa clara de reconciliacion.
- el filtrado por company solo se aplica al remoto, no necesariamente al local.

#### `shifts_provider.dart`

Gestiona lista y form de turnos.

### Pantallas

#### `dashboard_screen.dart`

Switch entre dashboard admin y dashboard empleado.

#### `admin_dashboard_screen.dart`

Vista principal del admin:

- grilla de empleados
- entrada a workstations
- entrada a kiosco de recepcion

#### `employee_dashboard_screen.dart`

Vista principal del empleado:

- puesto asignado
- productividad del dia
- feed reciente

#### `admin_analytics_screen.dart`

Lista comparativa de analiticas por empleado.

#### `employee_detail_analytics_screen.dart`

Detalle individual:

- distribucion por estado
- asistencia
- tiempo total
- productividad

#### `activity_history_screen.dart`

Problema grave:

- para `employee` usa `recentEventsStreamProvider`, que es global.
- esto expone eventos recientes de otros empleados.

#### `my_hours_screen.dart`

Pantalla muy valiosa de resumen diario:

- worked vs expected
- tardanza
- extras
- ausencias
- historial reciente

Problema:

- esta construida pero hoy el router la deja inaccesible al rol empleado.

#### `my_activity_screen.dart`

Feed personal correcto, pero tambien esta bloqueada por routing para el rol empleado.

#### `home_employee_screen.dart`

Pantalla residual/simple. Parece una version anterior del dashboard personal.

#### `shift_form_screen.dart`

Problema importante:

- bloquea turnos donde salida <= entrada.
- eso impide turnos nocturnos aunque el dominio si los contempla.

#### `shifts_list_screen.dart`

- lista turnos
- deja un `TODO` explicito para editar

## 5.10 `lib/features/camera_monitor`

Este es el modulo diferenciador del producto.

### IA

#### `face_embedding_service.dart`

- carga `mobile_face_net.tflite`
- genera embeddings de 192 dimensiones
- normaliza L2

#### `face_analyzer.dart`

- analiza angulos y ojos cerrados
- recorta el rostro desde `CameraImage`
- evalua calidad del crop
- convierte NV21/YUV420 a imagen

#### `pose_analyzer.dart`

- detecta movimiento de manos
- cercania mano-rostro
- inclinacion de hombros

#### `activity_classifier.dart`

- aplica una tabla de decision heuristica
- suaviza salida con EMA

#### `body_signature.dart`

- construye firma corporal con proporciones del esqueleto

#### `employee_profile.dart`

- define perfil biometrico completo de un empleado
- guarda embeddings, firma corporal, versionado y metadata

#### `employee_profiler.dart`

- orquesta enrolamiento de 8 muestras
- valida pose, calidad, diversidad de angulos y embeddings

#### `employee_finder.dart`

- busca al empleado correcto en tiempo real
- usa:
  - trackingId
  - embeddings faciales
  - body signature
  - matching combinado
- mueve parte del calculo a isolate con `compute`

Problema semantico:

- cuando hay persona presente pero no da match, suele devolver `outsideArea`, lo que mezcla "intruso/no identificado" con "fuera del area".

### Providers operativos

#### `kiosk_provider.dart`

Es el motor del monitoreo de workstation.

Hace:

- carga perfil desde DB local.
- escucha estado remoto de workstation por realtime.
- prende/apaga camara segun `status`.
- procesa frames.
- reidentifica al empleado.
- clasifica actividad.
- suaviza actividad por ventana temporal.
- maneja sesion:
  - `idle`
  - `entryPending`
  - `active`
  - `exitPending`
- persiste eventos.

Es una clase muy importante pero muy grande.

Riesgos:

- demasiadas responsabilidades en una sola clase.
- varios campos no usados.
- alta complejidad ciclomática.

#### `entrance_kiosk_provider.dart`

Es el motor del acceso frontal.

Hace:

- carga perfiles biométricos a memoria
- abre camara
- exige parpadeo
- evalua identidad por ventana de evidencia
- decide `clock in` o `clock out`
- prende o apaga la workstation remota

Problemas:

- si la DB local esta vacia, descarga workstations completas desde Supabase.
- no filtra por company.
- eso puede llevar biometria de multiples companias a un dispositivo.

### Pantallas

#### `kiosk_waiting_screen.dart`

- permite elegir modo del dispositivo:
  - kiosco de entrada
  - monitor de puesto

#### `kiosk_screen.dart`

- muestra preview de camara
- overlays
- flujo de entrada/salida
- enrolamiento si falta perfil
- standby si la estacion no esta `ACTIVE`

#### `entrance_kiosk_screen.dart`

- experiencia fullscreen para escaneo de acceso
- overlay de bienvenida

#### `employee_scan_screen.dart`

- flujo de enrolamiento biometrico del empleado
- captura por rafagas
- blink challenge inicial
- progreso por muestra

Observacion general del modulo:

- es el modulo mas trabajado del proyecto.
- tambien es el que mas deuda y riesgo concentra.

## 5.11 `supabase`

### `functions/create-employee/index.ts`

Hace:

- valida auth del llamador
- crea usuario en Supabase Auth
- inserta fila en `employees`

Problemas graves:

- valida rol usando `user.user_metadata?.role === 'admin'`.
- el frontend consume rol desde `appMetadata` o `userMetadata`, y lo normaliza en mayusculas.
- si el admin real vive en `app_metadata` o como `ADMIN`, esta funcion puede rechazarlo.
- recibe `shiftId` desde frontend pero no lo persiste.
- no escribe `company_id` ni `role` en `app_metadata`, aunque frontend depende mucho de esas claims.

### `functions/clock-in-kiosk/index.ts`

Replica logica de acceso:

- abre/cierra asistencia
- activa/desactiva workstation

Observacion:

- hoy la app principal no depende claramente de esta function.
- parece logica duplicada o alternativa al flujo cliente+repositorio.

### `migrations/20260325130438_add_role_to_employees.sql`

Agrega:

- `last_name`
- `role`
- `email`

Problema:

- el dominio Flutter no se alinea bien con esos campos.

## 5.12 `android`

### `AndroidManifest.xml`

Solicita:

- internet
- camara
- ubicacion fina y gruesa

Es coherente con el producto.

### `build.gradle.kts`

Observaciones:

- release firma con `debug`.
- eso no es aceptable para produccion real.

## 5.13 `test`

Hay muy poca cobertura.

- `test/core/routing/app_router_test.dart`: solo valida que el provider cree un `GoRouter`.
- `test/widget_test.dart`: placeholder vacio.

Estado real:

- `flutter test` pasa.
- pasar no significa cobertura real.

## 6. Hallazgos importantes

## 6.1 Criticos

### C1. El secreto `SUPABASE_SERVICE_ROLE_KEY` viaja dentro de la app

Evidencia:

- `.env` contiene `SUPABASE_SERVICE_ROLE_KEY`.
- `pubspec.yaml` incluye `.env` como asset.
- `main.dart` carga `.env` desde cliente.

Impacto:

- cualquier usuario puede extraer el APK y recuperar el service role key.
- eso compromete completamente el backend de Supabase.

Conclusión:

- es el problema mas grave del proyecto.

### C2. La biometria se guarda en texto plano localmente

Evidencia:

- `EmployeeRecords.face_embedding`
- `WorkstationRecords.face_embedding`
- `WorkstationRecords.body_signature`
- `workstation_profile_snapshots`
- payloads de sync y snapshots en `database.dart`

Impacto:

- fuga de datos biométricos si el dispositivo se compromete.
- incumplimiento serio de seguridad y privacidad.

### C3. Un empleado puede ver historial global, no solo el suyo

Evidencia:

- `ActivityHistoryScreen` usa `recentEventsStreamProvider`.
- `recentEventsStreamProvider` se alimenta de `watchRecentActivityEntries()` global.
- el router permite `/history` al rol `employee`.

Impacto:

- fuga de informacion operativa entre empleados.

### C4. La Edge Function `create-employee` esta desalineada con el modelo de autenticacion

Problemas combinados:

- valida rol en `user_metadata`, no en `app_metadata`.
- compara contra `'admin'`, no contra esquema consistente del sistema.
- ignora `shiftId`.
- no inyecta `company_id` ni rol en metadata consumida por app.

Impacto:

- empleados nuevos pueden quedar mal configurados.
- admins reales pueden fallar al crear usuarios.

## 6.2 Altos

### A1. Riesgo de fuga multitenant por datos locales sin filtrar

Evidencia:

- `adminEmployeesProvider` fusiona local+remoto sin filtrar siempre local por company.
- workstations locales tampoco se filtran sistematicamente por company.
- `entrance_kiosk_provider` puede descargar workstations completas si la DB local esta vacia.

Impacto:

- un dispositivo reutilizado podria mostrar empleados o workstations de otra empresa.

### A2. El flujo de edicion de empleado esta incompleto y puede degradar datos

Evidencia:

- `employee_form_screen.dart` solo precarga nombre y turno.
- no precarga apellido, correo ni rol.
- al editar se usa `Employee` simplificado.
- `createdAt` se rehace con `DateTime.now()`.

### A3. Pantallas importantes existen pero estan bloqueadas por routing

Evidencia:

- `my-hours`, `my-activity`, `home-employee` existen.
- el redirect de `employee` solo permite `dashboard`, `history`, `settings`.

Impacto:

- funcionalidad construida pero no entregada.

### A4. El sistema de asistencia aun no calcula estado real de puntualidad

Evidencia:

- `AttendanceRepositoryImpl.clockIn()` fija `status: ON_TIME`.

Impacto:

- los reportes de asistencia y la semantica del dominio no coinciden.

### A5. UI bloquea turnos nocturnos aunque el dominio los soporta

Evidencia:

- `Shift.isTimeWithinShift()` soporta overnight.
- `shift_form_screen.dart` prohíbe `end <= start`.

## 6.3 Medios

### M1. Demasiadas responsabilidades en `KioskNotifier` y `EntranceKioskNotifier`

Impacto:

- dificulta pruebas.
- dificulta mantenimiento.
- sube riesgo de regresiones.

### M2. Hay providers/auth flows duplicados

Evidencia:

- `shared/providers/auth_provider.dart`
- `features/auth/presentation/providers/auth_provider.dart`

Impacto:

- deriva arquitectonica.
- mas complejidad mental de la necesaria.

### M3. Hay mucho logging de depuracion en codigo productivo

Evidencia:

- `print` y `debugPrint` en IA, scan, entrada, sync.

Impacto:

- ruido.
- potencial fuga de informacion sensible en logs.

### M4. Dependencias declaradas pero no referenciadas en el codigo actual

Segun el escaneo de imports, no aparecen usadas en `lib/`:

- `google_maps_flutter`
- `flutter_local_notifications`
- `flutter_secure_storage`
- `cached_network_image`
- `image_picker`
- `hooks_riverpod`
- `riverpod_annotation`
- `pdf`
- `printing`
- `logger`
- `rxdart`

Impacto:

- peso innecesario.
- ruido en mantenimiento.
- expectativas falsas sobre features existentes.

### M5. La semantica de estados no siempre coincide con la realidad del frame

Ejemplo:

- `EmployeeFinder` puede devolver `outsideArea` cuando realmente el problema es no-match o intruso.

## 6.4 Bajos

### B1. README insuficiente

No documenta:

- setup real
- roles
- flujo de enrolamiento
- sync
- seguridad

### B2. Cobertura de tests minima

- solo 1 test real muy superficial.
- placeholder vacio en widget test.

### B3. Deuda general de analyzer y APIs deprecated

Estado verificado:

- `flutter analyze lib test` reporta 164 issues.
- `flutter analyze` completo reporta 180 issues porque `tmp/` agrega errores extra.
- `flutter test` pasa.

Patrones repetidos:

- `withOpacity` deprecated
- imports sin usar
- campos/metodos muertos
- uso de `value` deprecated en form fields
- `BuildContext` cruzando async gaps

## 7. Datos quemados y malas practicas detectadas

### Secretos y configuracion

- `.env` dentro del repo.
- `.env` empacado como asset.
- service role key presente en cliente.
- ids default de compania como fallback duro.

### Negocio y dominio

- strings de estado remotos como `'ACTIVE'`, `'IDLE'`, `'BREAK'`, `'ON_TIME'` quemados en varias capas.
- rol tratado a veces en minuscula y a veces en mayuscula.
- el dominio `Employee` no refleja el modelo real del backend.

### Programacion

- clases muy grandes.
- mezcla de UI, orquestacion, ML, acceso a datos y realtime en el mismo provider.
- muchos `debugPrint`/`print`.
- duplicacion de providers.
- TODO funcional sin cerrar en turnos.

## 8. Resumen de clases y archivos mas importantes

Si necesitas una lectura rapida, estas son las clases mas clave del sistema:

- `WorkSenseApp` en `main.dart`: bootstrap general.
- `GoRouter` en `app_router.dart`: acceso por rol.
- `AppDatabase`: almacenamiento local total.
- `SupabaseDataSource`: acceso remoto y auth.
- `ProcessSyncQueueUseCase`: sincronizacion offline/online.
- `WorktimeReconciler`: resumenes y rollups.
- `EmployeeRepositoryImpl`, `WorkstationRepositoryImpl`, `AttendanceRepositoryImpl`, `ActivityRepositoryImpl`, `ShiftRepositoryImpl`: nucleo de persistencia.
- `EmployeeProfiler`, `EmployeeFinder`, `FaceAnalyzer`, `PoseAnalyzer`, `ActivityClassifier`, `FaceEmbeddingService`: pipeline de IA.
- `KioskNotifier`: monitoreo continuo de workstation.
- `EntranceKioskNotifier`: acceso frontal y control de entrada/salida.
- `EmployeeScanNotifier`: enrolamiento biometrico.
- `AdminAnalyticsProvider`: analitica agregada.

## 9. Veredicto general

El proyecto tiene una idea de producto clara y bastante interesante:

- control de acceso
- monitoreo continuo por puesto
- analitica de actividad
- sincronizacion offline-first

No es un prototipo trivial. Hay trabajo serio en IA, sincronizacion y UX operativa.

Pero hoy esta en un punto intermedio entre PoC avanzado y producto empresarial:

- funcionalmente demuestra mucho valor.
- tecnicamente tiene huecos importantes.
- en seguridad y multitenancy tiene problemas que deben corregirse antes de pensar en produccion real.

## 10. Prioridad recomendada de correccion

Orden sugerido:

1. sacar `SUPABASE_SERVICE_ROLE_KEY` del cliente y del bundle.
2. proteger o rediseñar el almacenamiento local de biometria.
3. corregir fuga de historial global para empleados.
4. alinear `create-employee` con `app_metadata`, `company_id`, `shift_id` y roles.
5. filtrar por company toda lectura local fusionada.
6. arreglar routing para habilitar o eliminar pantallas muertas.
7. rehacer el flujo de edicion de empleados.
8. completar turnos, asistencia real y tests.

