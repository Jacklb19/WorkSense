# WorkSense — Estado del Proyecto

> "No mide cuánto eres, mide si estás trabajando."

Aplicación Flutter de monitoreo de productividad con IA en tiempo real. Detecta el estado de actividad de empleados mediante cámara, pose corporal y análisis facial.

---

## Stack Tecnológico

| Área | Tecnología |
|------|------------|
| Framework | Flutter 3.0+ / Dart 3.0+ |
| State Management | Riverpod (flutter_riverpod 2.5.1) |
| Routing | go_router 14.0.0 |
| Backend remoto | Supabase (auth + sync) |
| Base de datos local | Drift 2.19.1 + SQLite |
| IA / ML | Google ML Kit (Pose Detection, Face Detection) |
| Cámara | camera 0.11.0 |
| Ubicación | geolocator 12.0.0 |
| Notificaciones | flutter_local_notifications 17.2.2 |
| Almacenamiento seguro | flutter_secure_storage 9.2.2 |
| Reportes | pdf 3.11.1 + printing 13.1 |
| Mapas | google_maps_flutter 2.9.0 |

---

## Arquitectura

El proyecto sigue **Clean Architecture** con separación estricta en 3 capas:

```
lib/
├── core/           # Constantes, routing, theme, utils, errors
├── data/           # Repositorios, datasources (Supabase + Drift), modelos
├── domain/         # Entidades, interfaces de repositorios, casos de uso
├── features/       # Módulos de feature (auth, dashboard, camera_monitor, ...)
└── shared/         # Providers globales, widgets reutilizables, servicios
```

---

## Configuración Inicial

### Variables de entorno

Crear archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

### Instalar dependencias y correr

```bash
flutter pub get
flutter run
```

---

## Features Implementados

### ✅ Autenticación (`features/auth/`)
- Login con email/password via Supabase
- Auth guard: redirige a `/login` si no autenticado
- Logout desde Settings

### ✅ Dashboard (`features/dashboard/`)
- Vista en grid de todas las workstations
- Último estado de actividad por workstation
- Acceso rápido a modo kiosk desde cada card
- Historial de eventos de actividad
- Pull-to-refresh con sync manual

### ✅ Monitoreo en Tiempo Real — Kiosk (`features/camera_monitor/`)
- Pantalla full-screen con preview de cámara
- Análisis continuo cada ~800ms
- Guarda evento cada 30 segundos o al cambiar de estado

**Pipeline de IA:**

| Componente | Archivo | Función |
|------------|---------|---------|
| Pose Analyzer | `camera_monitor/ai/pose_analyzer.dart` | Detecta landmarks corporales, movimiento de manos, uso de celular |
| Face Analyzer | `camera_monitor/ai/face_analyzer.dart` | Detecta orientación de cabeza (Yaw/Pitch/Roll) |
| Activity Classifier | `camera_monitor/ai/activity_classifier.dart` | Combina pose + cara → estado final (smoothing de 3 frames) |

**Estados de actividad detectados:**

| Estado | Color | Descripción |
|--------|-------|-------------|
| `TRABAJANDO` | Verde | Empleado activo frente al trabajo |
| `INACTIVO` | Gris | Sin movimiento ni actividad |
| `DISTRAIDO` | Amarillo | Cabeza girada >30° |
| `FATIGA` | Naranja | Cabeza caída o inclinada |
| `AUSENTE` | Rojo | Sin persona detectada |

**Umbrales configurables** (`core/constants/aithresholds.dart`):
- Face yaw: 30°
- Pitch mínimo: -20°
- Roll máximo: 25°
- Confianza mínima de pose: 0.45
- Intervalo de análisis: 30s (rango 10-120s)

### ✅ Gestión de Empleados (`features/employees/`)
- Listado de empleados
- Formulario para agregar/editar empleado
- Eliminar empleado

### ✅ Settings (`features/settings/`)
- Ajustar intervalo de análisis (slider 10-120s)
- Ver umbrales de IA (solo lectura)
- Versión de la app
- Botón de logout

### ✅ Persistencia Offline + Sync

**Base de datos local (Drift/SQLite)** — `data/datasources/local/database.dart`

Tablas:
- `companies`
- `employees`
- `workstations`
- `activity_entries`
- `sync_queue_entries` — cola de eventos pendientes de subir

**Sync con Supabase** — `shared/providers/sync_state_provider.dart`
- Detecta conectividad via `isOnlineProvider`
- Auto-sync al recuperar conexión
- Guarda eventos localmente cuando está offline

---

## Navegación (GoRouter)

| Ruta | Pantalla |
|------|----------|
| `/login` | Login |
| `/dashboard` | Dashboard principal |
| `/kiosk/:workstationId` | Kiosk de monitoreo |
| `/history` | Historial de actividad |
| `/employees` | Lista de empleados |
| `/employees/new` | Formulario nuevo empleado |
| `/settings` | Configuración |

---

## Diseño (Material 3)

**Paleta de colores** (`core/theme/app_colors.dart`):
- Primary: `#1A73E8` (Google Blue)
- Working: `#34A853` | Inactive: `#9E9E9E` | Distracted: `#FBBC04` | Fatigue: `#FF6D00` | Absent: `#EA4335`

Soporta tema claro y oscuro.

---

## Pendiente / Proximos Pasos

> Lo que falta por implementar o completar:

- [ ] **Reportes PDF** — El módulo `features/reports/` existe como placeholder, la generación de PDF con `pdf` + `printing` aún no está conectada a datos reales
- [ ] **Analytics** — El módulo `features/analytics/` existe como placeholder
- [ ] **Alerts** — El módulo `features/alerts/` existe como placeholder; las notificaciones locales están instaladas pero no configuradas
- [ ] **Workstations CRUD** — Existe el módulo pero el formulario de creación/edición no está completo
- [ ] **Google Maps** — La dependencia está instalada pero no hay pantalla que la use
- [ ] **Gestión de empresas (multi-tenant)** — La entidad `Company` existe en dominio/DB pero no hay UI para seleccionar/cambiar empresa
- [ ] **Tests** — No hay tests unitarios ni de integración escritos
- [ ] **Selección de cámara** — Existe `availableCamerasProvider` pero no hay UI para seleccionar entre cámaras
- [ ] **Permisos de roles** — No hay diferenciación de roles (admin vs viewer) en la UI

---

## Estructura de Archivos Clave

```
lib/
├── main.dart                                              # Entry point, init Supabase + Riverpod
├── core/
│   ├── constants/aithresholds.dart                        # Umbrales IA
│   ├── routing/app_router.dart                            # GoRouter config
│   └── theme/app_colors.dart                              # Colores del sistema
├── domain/entities/
│   ├── activity_state.dart                                # Enum de 5 estados
│   ├── employee.dart
│   ├── company.dart
│   └── workstation.dart
├── data/datasources/
│   ├── local/database.dart                                # Schema Drift + DAOs
│   └── remote/supabase_datasource.dart                   # Llamadas Supabase
├── features/
│   ├── auth/presentation/screens/login_screen.dart
│   ├── camera_monitor/
│   │   ├── ai/activity_classifier.dart                    # Logica central de IA
│   │   ├── ai/face_analyzer.dart
│   │   ├── ai/pose_analyzer.dart
│   │   └── presentation/screens/kiosk_screen.dart
│   ├── dashboard/presentation/screens/dashboard_screen.dart
│   ├── employees/presentation/screens/
│   │   ├── employees_list_screen.dart
│   │   └── employee_form_screen.dart
│   └── settings/presentation/screens/settings_screen.dart
└── shared/providers/
    └── sync_state_provider.dart                           # Motor de sync offline
```

---

## Branch Actual

- Branch activo: `steven.dev`
- Branch principal: `main`

---

## Notas para el Equipo

1. **No subir el `.env`** — está en `.gitignore`. Cada dev necesita sus propias credenciales de Supabase.
2. El código tiene reglas estrictas de linting — correr `dart analyze` antes de hacer PR.
3. Los modelos usan **Freezed** — si agregas campos a entidades, correr `flutter pub run build_runner build`.
4. El intervalo de análisis de IA se puede bajar a 10s para testing rápido desde Settings.
5. El pipeline de IA **solo funciona en dispositivo físico** — el emulador no tiene acceso a cámara real con ML Kit.
