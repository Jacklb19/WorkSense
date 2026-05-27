# WorkSense

<p align="center">
  <img src="assets/icon/app_icon.png" alt="WorkSense Logo" width="120"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/AI-MLKit%20%7C%20TFLite-orange" alt="AI"/>
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase"/>
</p>

> **WorkSense** es una plataforma empresarial de monitoreo inteligente de empleados que combina reconocimiento facial biométrico, análisis de actividad en tiempo real mediante IA y gestión de asistencia offline-first, todo construido con Flutter.

---

## 📑 Tabla de Contenidos

1. [Resumen del Proyecto](#-resumen-del-proyecto)
2. [Características Principales](#-características-principales)
3. [Arquitectura](#-arquitectura)
4. [Pipeline de IA](#-pipeline-de-ia)
5. [Reconocimiento de Identidad](#-reconocimiento-de-identidad)
6. [Flujo de Enrolamiento](#-flujo-de-enrolamiento)
7. [Esquema de Base de Datos](#-esquema-de-base-de-datos)
8. [Tecnologías Utilizadas](#-tecnologías-utilizadas)
9. [Estructura de Carpetas](#-estructura-de-carpetas)
10. [Roles y Permisos](#-roles-y-permisos)
11. [Instalación y Configuración](#-instalación-y-configuración)
12. [Ubicación del APK](#-ubicación-del-apk)
13. [Variables de Entorno](#-variables-de-entorno)
14. [Notas de Desarrollo](#-notas-de-desarrollo)

---

## 📋 Resumen del Proyecto

WorkSense es un sistema empresarial completo para la gestión y monitoreo de empleados en entornos de trabajo. El sistema opera a través de tres roles principales: **Administrador**, **Supervisor** y **Empleado**, cada uno con capacidades y vistas diferenciadas.

El corazón del sistema es su **módulo de cámara inteligente**, que utiliza:
- **Reconocimiento facial biométrico** (MobileFaceNet + TFLite) para identificar empleados con alta precisión
- **Análisis de actividad** (Google MLKit Face Detection) para determinar el estado de trabajo en tiempo real
- **Kiosco de entrada** con desafío de parpadeo para control de acceso sin contacto

El sistema es **offline-first**: todas las operaciones críticas se guardan localmente (Drift/SQLite) y se sincronizan con Supabase cuando hay conexión disponible.

---

## ✨ Características Principales

### 🎯 Monitoreo de Empleados
- Detección automática de estados: **Trabajando**, **Inactivo**, **Distraído**, **Fatiga**, **Ausente**, **No Identificado**
- Análisis facial en tiempo real con suavizado EMA y ventana de votación mayoritaria de 4 segundos
- Activación/desactivación remota de cámara vía Supabase Realtime

### 🚪 Kiosco de Entrada
- Control de acceso biométrico sin contacto
- Desafío de parpadeo para detección de vivacidad (anti-spoofing)
- Registro automático de entrada/salida con hora y foto
- Umbral configurable de similitud facial

### 👤 Enrolamiento Biométrico
- Captura de 8 muestras en ángulos distintos (frontal, izquierda, derecha, arriba, abajo, etc.)
- Compuertas de diversidad y calidad (brillo, contraste, nitidez)
- Generación de embeddings de 192 dimensiones con MobileFaceNet

### 📊 Dashboard y Reportes
- Vista en tiempo real del estado de todos los empleados
- Reportes de productividad, tiempo en cada estado, alertas
- Gestión de horarios, turnos y solicitudes de permiso/vacaciones

### 🔄 Sincronización Offline-First
- Cola de sincronización (SyncQueue) para operaciones pendientes
- Resolución de conflictos y reconciliación de tiempos de trabajo
- Indicador visual del estado de sincronización

### 🌐 Localización
- Soporte completo para **Español** e **Inglés** (Flutter AppLocalizations)
- Cambio de idioma en tiempo real

---

## 🏗 Arquitectura

WorkSense sigue **Clean Architecture** con organización por features:

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  Screens  ─────  Providers (Riverpod)  ─────  Widgets       │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  Entities  ─────  Use Cases  ─────  Repository Interfaces   │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  Supabase Repos  ─────  Drift DAOs  ─────  API Services     │
├──────────────────────────┬──────────────────────────────────┤
│   LOCAL (Drift/SQLite)   │   REMOTE (Supabase/PostgreSQL)   │
│   - attendance_records   │   - employees                    │
│   - sync_queue           │   - workstations                 │
│   - face_embeddings      │   - attendance_logs              │
└──────────────────────────┴──────────────────────────────────┘
```

### Patrones Utilizados
- **Riverpod** — Gestión de estado reactiva (StateNotifier, FutureProvider, StreamProvider)
- **GoRouter** — Navegación declarativa con guardas por rol
- **Repository Pattern** — Abstracción de fuente de datos (local vs. remoto)
- **Observer Pattern** — Supabase Realtime para actualizaciones en vivo
- **Strategy Pattern** — Clasificadores de actividad intercambiables

---

## 🤖 Pipeline de IA

```
Imagen de Cámara
       │
       ├──► [MLKit Face Detector] ──► FaceAnalyzer
       │         headEulerAngleX (pitch)    │
       │         headEulerAngleY (yaw)      │
       │         headEulerAngleZ (roll)     │
       │         eyeOpenProbability         │
       │                                    │
       ├──► [MLKit Pose Detector] ──► PoseAnalyzer
       │         nose, shoulders            │
       │         poseConfidence             │
       │                                    ▼
       │                           ActivityClassifier
       │                           ┌────────────────────┐
       │                           │  Tabla de Decisión │
       │                           │  + EMA Smoothing   │
       │                           │  + Window Buffer   │
       │                           │  (4 seg majority)  │
       │                           └────────────────────┘
       │                                    │
       └──► [MobileFaceNet TFLite] ──►  Identity
                 192-dim embedding         Match
                 cosine similarity
```

### Estados de Actividad

| Estado | Condición | Confianza |
|--------|-----------|-----------|
| `ausente` | No se detecta cara ni pose | 85% |
| `noIdentificado` | Persona presente pero cara no reconocida | 50% |
| `fatiga` | Ojos cerrados + cabeza inclinada/girada | 85% |
| `inactivo` | Solo ojos cerrados | 70% |
| `trabajando` | Mirando hacia abajo (leyendo/escribiendo) | 80% |
| `distraido` | Yaw extremo (> umbral + 15°) | 75% |
| `distraido` | Yaw moderado (> umbral) | 65% |
| `trabajando` | Por defecto (cara presente, ojos abiertos) | 90% |

### Umbrales AI (`AiThresholds`)

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `minPitchAngle` | -8.0° | Pitch mínimo para "mirando abajo" |
| `maxYawAngle` | 25.0° | Yaw máximo antes de clasificar como distraído |
| `maxRollAngle` | 20.0° | Roll máximo para fatiga |
| `eyeClosedThreshold` | 0.35 | Probabilidad mínima para considerar ojo cerrado |
| `minPoseConfidence` | 0.6 | Confianza mínima de pose para procesar |
| `entranceMatchThreshold` | 0.75 | Similitud mínima para identificación en kiosco |
| `enrollmentMatchThreshold` | 0.70 | Similitud mínima durante enrolamiento |

---

## 🔍 Reconocimiento de Identidad

```
Frame de Cámara
      │
      ▼
[MLKit Face Detector]
      │
      ▼
¿Face detected?  ──No──► Continuar sin ID
      │
     Sí
      │
      ▼
[MobileFaceNet TFLite]
Genera embedding 192D
      │
      ▼
Búsqueda en caché de embeddings locales
      │
      ▼
Similitud Coseno vs. cada empleado
      │
      ▼
¿sim >= umbral?  ──No──► Estado: noIdentificado
      │
     Sí
      │
      ▼
Empleado Identificado → Registrar actividad
```

**Kiosco de Entrada (anti-spoofing adicional):**
1. Detectar cara presente
2. Solicitar desafío de **parpadeo** (`_hasBlinked`)
3. Solo después del parpadeo → evaluar identidad
4. Si similitud >= umbral → Registrar entrada/salida

---

## 📸 Flujo de Enrolamiento

El enrolamiento captura **8 muestras** en posiciones específicas:

| # | Instrucción | Condición de Detección |
|---|-------------|------------------------|
| 1 | Mira directamente a la cámara | `yaw ≈ 0°, pitch ≈ 0°` |
| 2 | Gira levemente a la izquierda | `yaw < -10°` |
| 3 | Inclina levemente la cabeza hacia abajo | `pitch < -3°` |
| 4 | Levanta levemente la cabeza | `pitch > 3°` |
| 5 | Gira levemente a la derecha | `yaw > 10°` |
| 6 | Gira más a la izquierda | `yaw < -20°` |
| 7 | Gira más a la derecha | `yaw > 20°` |
| 8 | Mira directamente (segunda muestra) | `yaw ≈ 0°, pitch ≈ 0°` |

**Compuertas de Calidad:**
- **Brillo**: `80 ≤ brillo ≤ 200`
- **Contraste**: `contraste ≥ 30`
- **Nitidez**: `nitidez ≥ 50` (varianza Laplaciana)
- **Diversidad**: Los embeddings nuevos deben ser suficientemente distintos de los ya capturados

---

## 🗄 Esquema de Base de Datos

### Tablas Principales (Supabase/PostgreSQL)

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  employees   │     │   workstations    │     │  attendance_logs │
├──────────────┤     ├───────────────────┤     ├──────────────────┤
│ id (uuid)    │◄────│ assigned_employee │     │ id               │
│ name         │     │ id (uuid)         │     │ employee_id ─────┤
│ email        │     │ name              │     │ workstation_id   │
│ role         │     │ location          │     │ timestamp        │
│ department   │     │ status            │     │ type (IN/OUT)    │
│ face_data[]  │     │ camera_active     │     │ method           │
│ is_active    │     │ ip_address        │     │ photo_url        │
└──────────────┘     └───────────────────┘     └──────────────────┘

┌──────────────────────┐     ┌──────────────────────┐
│   activity_logs      │     │   work_sessions      │
├──────────────────────┤     ├──────────────────────┤
│ id                   │     │ id                   │
│ employee_id          │     │ employee_id          │
│ workstation_id       │     │ date                 │
│ state (enum)         │     │ total_work_minutes   │
│ confidence           │     │ total_idle_minutes   │
│ timestamp            │     │ total_distracted_min │
│ duration_seconds     │     │ productivity_score   │
└──────────────────────┘     └──────────────────────┘

┌──────────────────┐     ┌──────────────────────┐
│   schedules      │     │   leave_requests     │
├──────────────────┤     ├──────────────────────┤
│ id               │     │ id                   │
│ employee_id      │     │ employee_id          │
│ day_of_week      │     │ start_date           │
│ start_time       │     │ end_date             │
│ end_time         │     │ type                 │
│ is_active        │     │ status               │
└──────────────────┘     └──────────────────────┘
```

### Tablas Auxiliares (Drift/SQLite Local)

```
┌──────────────────────┐     ┌─────────────────────┐
│  local_attendance    │     │    sync_queue        │
├──────────────────────┤     ├─────────────────────┤
│ id (autoIncrement)   │     │ id                  │
│ employee_id          │     │ operation_type      │
│ timestamp            │     │ table_name          │
│ type                 │     │ payload (JSON)      │
│ synced               │     │ created_at          │
└──────────────────────┘     │ retry_count         │
                             └─────────────────────┘

┌──────────────────────┐     ┌─────────────────────┐
│  cached_embeddings   │     │  local_activity_logs│
├──────────────────────┤     ├─────────────────────┤
│ employee_id          │     │ id                  │
│ embedding (Float64)  │     │ employee_id         │
│ updated_at           │     │ state               │
└──────────────────────┘     │ timestamp           │
                             │ synced              │
                             └─────────────────────┘
```

---

## 🛠 Tecnologías Utilizadas

### Framework y Lenguaje

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.x | Framework multiplataforma |
| Dart | 3.x | Lenguaje de programación |

### Estado y Navegación

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` | Gestión de estado reactiva |
| `riverpod_annotation` | Code generation para providers |
| `go_router` | Navegación declarativa con guardas |

### Inteligencia Artificial

| Paquete | Uso |
|---------|-----|
| `google_mlkit_face_detection` | Detección y análisis facial en tiempo real |
| `google_mlkit_pose_detection` | Detección de pose corporal |
| `tflite_flutter` | Inferencia TFLite para MobileFaceNet |
| `camera` | Acceso a cámara con stream de imágenes |
| `image` | Procesamiento de imágenes (normalización) |

### Backend y Base de Datos

| Paquete | Uso |
|---------|-----|
| `supabase_flutter` | Backend as a Service, Realtime, Auth |
| `drift` | ORM tipado para SQLite (offline-first) |
| `sqlite3_flutter_libs` | Binarios SQLite nativos |
| `path_provider` | Rutas de almacenamiento local |

### UI y UX

| Paquete | Uso |
|---------|-----|
| `flutter_localizations` | Localización ES/EN oficial |
| `intl` | Formateo de fechas, números y mensajes |
| `fl_chart` | Gráficas de productividad y estadísticas |
| `cached_network_image` | Caché de imágenes de red |
| `shimmer` | Efectos de carga skeleton |
| `lottie` | Animaciones vectoriales |

### Utilidades

| Paquete | Uso |
|---------|-----|
| `connectivity_plus` | Detección de estado de red |
| `permission_handler` | Gestión de permisos en runtime |
| `shared_preferences` | Preferencias persistentes ligeras |
| `uuid` | Generación de UUIDs |

---

## 📁 Estructura de Carpetas

```
WorkSense/
├── lib/
│   ├── main.dart                          # Entry point, providers globales
│   ├── app/
│   │   ├── app_router.dart               # GoRouter con guardas por rol
│   │   ├── app_theme.dart                # ThemeData y AppThemeColors
│   │   └── app_role.dart                 # Enum de roles: admin/supervisor/employee
│   ├── core/
│   │   ├── constants/                    # AiThresholds, AppConstants
│   │   ├── database/                     # Drift database, DAOs, migrations
│   │   ├── services/                     # SyncService, PermissionService
│   │   ├── providers/                    # Providers globales (auth, db, theme)
│   │   └── widgets/                      # Widgets reutilizables globales
│   └── features/
│       ├── auth/                         # Login, sesión, guards
│       ├── camera_monitor/              # Módulo central de IA
│       │   ├── ai/
│       │   │   ├── activity_classifier.dart    # Tabla de decisión facial
│       │   │   ├── face_analyzer.dart          # MLKit face → FaceAnalysisResult
│       │   │   ├── pose_analyzer.dart          # MLKit pose → PoseAnalysisResult
│       │   │   ├── ai_result.dart              # Data classes de resultados AI
│       │   │   ├── employee_profiler.dart      # Lógica de enrolamiento biométrico
│       │   │   ├── face_embedding_service.dart # TFLite MobileFaceNet embeddings
│       │   │   └── activity_window_buffer.dart # Ventana de votación 4 segundos
│       │   ├── data/
│       │   │   └── face_repository.dart        # Acceso a embeddings (local + remoto)
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── kiosk_provider.dart          # Estado del monitor de empleados
│       │       │   └── entrance_kiosk_provider.dart # Estado del kiosco de entrada
│       │       └── screens/
│       │           ├── camera_monitor_screen.dart   # Pantalla de monitoreo activo
│       │           ├── entrance_kiosk_screen.dart   # Kiosco de control de acceso
│       │           └── employee_scan_screen.dart    # Pantalla de enrolamiento
│       ├── dashboard/                    # Vistas de dashboard por rol
│       ├── employees/                    # CRUD de empleados
│       ├── attendance/                   # Registro de asistencia y reportes
│       ├── schedules/                    # Gestión de horarios y turnos
│       ├── workstations/                 # Gestión de estaciones de trabajo
│       ├── reports/                      # Reportes de productividad
│       └── settings/                    # Configuración de la app
├── assets/
│   ├── models/
│   │   └── mobilefacenet.tflite         # Modelo de reconocimiento facial
│   ├── icon/
│   │   └── app_icon.png
│   └── lottie/                          # Animaciones
├── android/                             # Configuración Android nativa
│   └── app/
│       └── build.gradle                 # minSdk 23, targetSdk 34
├── build/
│   └── app/outputs/flutter-apk/         # APK generado
└── pubspec.yaml                         # Dependencias y assets
```

---

## 👥 Roles y Permisos

| Funcionalidad | Admin | Supervisor | Empleado |
|---------------|:-----:|:----------:|:--------:|
| Dashboard global | ✅ | ✅ | ❌ |
| Ver todos los empleados | ✅ | ✅ | ❌ |
| Gestionar empleados (CRUD) | ✅ | ❌ | ❌ |
| Monitoreo en tiempo real | ✅ | ✅ | ❌ |
| Ver su propio perfil | ✅ | ✅ | ✅ |
| Kiosco de entrada | ✅ | ✅ | ✅ |
| Enrolamiento biométrico | ✅ | ✅ | ✅ |
| Gestionar estaciones de trabajo | ✅ | ❌ | ❌ |
| Gestionar horarios | ✅ | ✅ | ❌ |
| Aprobar permisos/vacaciones | ✅ | ✅ | ❌ |
| Solicitar permisos | ✅ | ✅ | ✅ |
| Ver reportes globales | ✅ | ✅ | ❌ |
| Ver sus propios reportes | ✅ | ✅ | ✅ |

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- **Flutter SDK** 3.x o superior — [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Dart SDK** 3.x (incluido con Flutter)
- **Android Studio** o **VS Code** con extensiones Flutter/Dart
- **Android SDK** con API Level 23+ (minSdk 23)
- Cuenta en **Supabase** — [supabase.com](https://supabase.com)
- **Git**

### Pasos de Instalación

#### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-org/worksense.git
cd worksense/WorkSense
```

#### 2. Instalar Dependencias

```bash
flutter pub get
```

#### 3. Generar Código (Riverpod + Drift)

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 4. Configurar Variables de Entorno

Crea el archivo `lib/core/constants/supabase_constants.dart` con tus credenciales:

```dart
class SupabaseConstants {
  static const String url = 'https://TU_PROYECTO.supabase.co';
  static const String anonKey = 'TU_ANON_KEY';
}
```

> ⚠️ **Nunca** subas este archivo a un repositorio público. Agrega `supabase_constants.dart` a tu `.gitignore`.

#### 5. Configurar Supabase

En tu proyecto Supabase, ejecuta las migraciones SQL ubicadas en `supabase/migrations/` para crear todas las tablas necesarias. Habilita también:

- **Authentication** → Email/Password
- **Storage** → Bucket `employee-photos` (público) y `face-embeddings` (privado)
- **Realtime** → En las tablas `workstations` y `activity_logs`
- **Row Level Security (RLS)** → Configurar políticas según rol

#### 6. Colocar el Modelo TFLite

Asegúrate de que el archivo `mobilefacenet.tflite` esté en:

```
assets/models/mobilefacenet.tflite
```

Verifica que esté declarado en `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/mobilefacenet.tflite
```

#### 7. Compilar y Ejecutar

**Debug (emulador o dispositivo físico):**
```bash
flutter run
```

**Build APK de Release:**
```bash
flutter build apk --release
```

**Build APK de Debug:**
```bash
flutter build apk --debug
```

---

## 📦 Ubicación del APK

Después de ejecutar `flutter build apk`, los archivos APK se generan en:

| Tipo | Ruta |
|------|------|
| **Debug** | `build/app/outputs/flutter-apk/app-debug.apk` |
| **Release** | `build/app/outputs/flutter-apk/app-release.apk` |
| **Debug (alternativo)** | `build/app/outputs/apk/debug/app-debug.apk` |

Para instalar directamente en un dispositivo conectado:

```bash
flutter install
```

O copia el APK al dispositivo y habilita **"Instalar aplicaciones de fuentes desconocidas"** en Ajustes → Seguridad.

---

## 🔑 Variables de Entorno

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `SUPABASE_URL` | URL del proyecto Supabase | `https://abc123.supabase.co` |
| `SUPABASE_ANON_KEY` | Clave pública anónima | `eyJhbGciOiJIUzI1NiIsInR5...` |

> En Flutter no se usan variables de entorno del sistema operativo directamente. Las credenciales se configuran como constantes Dart en el archivo descrito en el paso 4, o usando `--dart-define` al compilar:
> ```bash
> flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=eyJ...
> ```

---

## 📝 Notas de Desarrollo

### Convención de Pitch en MLKit (Cámara Frontal)

> **IMPORTANTE:** En la cámara frontal con Google MLKit, la convención de pitch es **invertida** respecto a lo que se podría esperar intuitivamente:
> - `pitch < 0` → La persona está mirando **hacia abajo** (leyendo, escribiendo)
> - `pitch > 0` → La persona está mirando **hacia arriba**

Esta convención afecta directamente la clasificación de actividad y las instrucciones de enrolamiento.

### Suavizado de Señales AI

El `ActivityClassifier` aplica dos capas de suavizado para evitar cambios de estado erráticos:

1. **EMA (Exponential Moving Average)** con `α = 0.3` — suaviza la confianza frame a frame
2. **ActivityWindowBuffer** — ventana deslizante de 4 segundos que aplica votación mayoritaria antes de emitir un cambio de estado

### Consideraciones de Rendimiento

- MLKit Face y Pose Detection corren en modo **stream** (no single-image), optimizados para latencia baja
- La inferencia TFLite se ejecuta en un **Isolate** separado para no bloquear el hilo de UI
- Los embeddings faciales se **cachean localmente** (Drift) para evitar consultas repetidas a Supabase

### Permisos Android Requeridos

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Liveness Detection

El kiosco de entrada implementa un desafío de **parpadeo** (`_hasBlinked`) como medida anti-spoofing básica. El sistema solo evalúa la identidad de una persona una vez que ha parpadeado, reduciendo la efectividad de ataques con fotos estáticas.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un Issue describiendo el cambio propuesto antes de crear un Pull Request.

---

## 📄 Licencia

Este proyecto es propietario. Todos los derechos reservados © 2024 WorkSense.

---

<p align="center">
  Construido con ❤️ usando Flutter
</p>
