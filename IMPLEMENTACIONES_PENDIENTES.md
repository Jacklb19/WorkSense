# 📋 WorkSense — Implementaciones pendientes

Este archivo documenta los pasos manuales requeridos para activar funcionalidades
que ya están codificadas en el proyecto pero necesitan configuración externa.

---

## ✅ Estado general del proyecto

| Módulo | Estado | Notas |
|---|---|---|
| Autenticación | ✅ Completo | Supabase Auth |
| Dashboard admin + empleado | ✅ Completo | |
| Gestión de empleados | ✅ Completo | |
| Estaciones de trabajo | ✅ Completo | |
| Monitoreo con IA (cámara) | ✅ Completo | ML Kit + TFLite |
| Tareas | ✅ Completo | Drift + Supabase sync |
| Solicitudes de permiso | ✅ Completo | |
| Turnos | ✅ Completo | |
| Reportes PDF | ✅ Completo | |
| Anuncios | ✅ Completo | |
| Notificaciones in-app | ✅ Completo | Panel con campanita |
| Chat admin ↔ empleado | ✅ Completo | Mensajes en tiempo real |
| Notificaciones push (FCM) | ⚠️ Código listo | **Ver Sección 1** |
| Llamadas de voz/video | ❌ No implementado | **Ver Sección 2** |
| Nómina básica | ❌ No implementado | **Ver Sección 3** |
| Geolocalización check-in | ❌ No implementado | **Ver Sección 4** |
| Evaluaciones de desempeño | ❌ No implementado | **Ver Sección 5** |

---

## Sección 1 — Notificaciones push reales (FCM)

> **Estado:** El código Flutter y la Edge Function de Supabase ya están escritos.
> Solo falta la configuración externa.

### Qué hace
Cuando el admin asigna una tarea, aprueba/rechaza un permiso o envía un mensaje,
el empleado recibe una notificación push **aunque la app esté cerrada**. Y viceversa.

### Paso 1 — Crear proyecto en Firebase

1. Ve a [console.firebase.google.com](https://console.firebase.google.com)
2. Clic en **Agregar proyecto** → nombre: `worksense-app`
3. Desactiva Google Analytics si no lo necesitas → **Crear proyecto**

### Paso 2 — Registrar la app Android

1. Dentro del proyecto → **Agregar app** → ícono Android
2. Nombre del paquete: `com.co.work_sense`
3. Apodo: `WorkSense Android`
4. SHA-1: déjalo vacío por ahora
5. **Descargar `google-services.json`**
6. Colocar el archivo en: `android/app/google-services.json`

### Paso 3 — Desplegar la Edge Function

Instala Supabase CLI si no lo tienes:
```bash
npm install -g supabase
```

Autentícate y enlaza tu proyecto:
```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
```
> Tu `PROJECT_REF` está en Supabase Dashboard → Configuración → General.

Despliega la función:
```bash
supabase functions deploy send-push --no-verify-jwt
```

### Paso 4 — Configurar los secrets de la Edge Function

En [supabase.com](https://supabase.com) → tu proyecto → **Edge Functions** →
**send-push** → pestaña **Secrets** → agregar:

#### `FIREBASE_SERVICE_ACCOUNT`
1. Firebase Console → **Configuración del proyecto** (ícono ⚙️) → **Cuentas de servicio**
2. Clic en **Generar nueva clave privada** → descarga el `.json`
3. Abre el archivo, copia **todo el contenido** (incluyendo las llaves `{}`)
4. Pégalo como valor del secret `FIREBASE_SERVICE_ACCOUNT`

#### `SUPABASE_SERVICE_ROLE_KEY`
1. Supabase Dashboard → **Configuración** → **API**
2. Copia el **service_role** key (el largo, NO el anon key)
3. Pégalo como valor del secret `SUPABASE_SERVICE_ROLE_KEY`

> `SUPABASE_URL` ya está disponible automáticamente, no necesitas agregarlo.

### Paso 5 — Ejecutar la migración SQL

En Supabase Dashboard → **SQL Editor**, ejecuta el contenido del archivo:
```
supabase/migrations/20260524070000_add_fcm_tokens.sql
```

### Paso 6 — Compilar

```bash
flutter pub get
flutter run
```

Al iniciar sesión, la app registra automáticamente el token FCM del dispositivo.

### Verificar que funciona
1. Asigna una tarea a un empleado desde el admin
2. Pon la app del empleado en background (minimizada) o ciérrala
3. El empleado debe recibir la notificación push del sistema
4. Al tocarla, la app debe abrir y navegar a `/tasks`

### Troubleshooting

| Problema | Solución |
|---|---|
| Build falla: `google-services.json not found` | Asegúrate de poner el archivo en `android/app/`, no en `android/` |
| Push no llega | Verifica el secret `FIREBASE_SERVICE_ACCOUNT` en Supabase |
| Error `FIREBASE_SERVICE_ACCOUNT no configurado` | El secret no fue guardado; revisa en Edge Functions → Secrets |
| Token no se guarda en Supabase | El usuario debe iniciar sesión para que el token se registre |
| Notificación llega pero no navega | Verifica que el campo `route` se esté guardando en la tabla `notifications` |

---

## Sección 2 — Llamadas de voz (Agora)

> **Estado:** No implementado. Requiere cuenta en Agora.io.

### Qué haría
Botón en el chat que inicia una llamada de voz entre el empleado y el admin,
útil para situaciones urgentes sin salir de la app.

### Pasos cuando se implemente

1. Crear cuenta en [agora.io](https://www.agora.io) (plan gratuito: 10,000 min/mes)
2. Crear un proyecto en Agora Console → copiar el **App ID**
3. Agregar el paquete:
   ```yaml
   agora_rtc_engine: ^6.x.x
   ```
4. Android: agregar permiso de micrófono en `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```
5. Agregar `AGORA_APP_ID` al archivo `.env`
6. Crear un Agora Token Server (o usar tokens temporales en desarrollo)

### Complejidad estimada
**Media** — 2 a 3 días de desarrollo

---

## Sección 3 — Nómina básica

> **Estado:** No implementado.

### Qué haría
- Calcular salario del período basado en horas trabajadas registradas
- Configurar tarifa por hora, deducciones fijas y variables por empleado
- Generar recibo de pago en PDF con desglose
- Historial de nómina por empleado

### Pasos cuando se implemente

1. Crear tabla `payroll_config` en Supabase:
   - `employee_id`, `hourly_rate`, `currency`, `deductions`
2. Crear tabla `payroll_periods`:
   - `id`, `company_id`, `start_date`, `end_date`, `status`
3. Crear tabla `payroll_entries`:
   - `employee_id`, `period_id`, `hours_worked`, `gross_pay`, `deductions`, `net_pay`
4. Ejecutar migración SQL
5. Crear pantalla de nómina en admin (listar períodos, calcular, aprobar)
6. El cálculo usa los datos de `activity_logs` que ya existen en Drift/Supabase

### Complejidad estimada
**Media-alta** — 1 semana de desarrollo

---

## Sección 4 — Geolocalización en check-in

> **Estado:** No implementado. El paquete `geolocator` ya está en `pubspec.yaml`.

### Qué haría
- El empleado solo puede registrar entrada/salida si está dentro de un radio
  configurable (ej: 100m) de la ubicación de la empresa
- El admin configura la ubicación de la empresa en un mapa

### Pasos cuando se implemente

1. Agregar `google_maps_flutter` para el selector de ubicación
   (ya está en `pubspec.yaml`)
2. Crear tabla `company_location` en Supabase:
   - `company_id`, `latitude`, `longitude`, `radius_meters`
3. Al registrar check-in, comparar coordenadas del usuario con la empresa
4. Mostrar error si está fuera del radio
5. Requiere **Google Maps API Key** para Android:
   - Google Cloud Console → habilitar Maps SDK for Android
   - Agregar la key en `AndroidManifest.xml`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="TU_API_KEY"/>
     ```

### Complejidad estimada
**Media** — 3 a 4 días de desarrollo

---

## Sección 5 — Evaluaciones de desempeño

> **Estado:** No implementado.

### Qué haría
- El admin crea evaluaciones periódicas (trimestral/anual) con criterios
  configurables (puntualidad, productividad, actitud, etc.)
- El empleado puede ver su historial de evaluaciones y puntajes
- Dashboard con comparativa entre empleados

### Pasos cuando se implemente

1. Crear tabla `evaluation_templates`:
   - `id`, `company_id`, `name`, `criteria` (JSON array)
2. Crear tabla `evaluations`:
   - `id`, `employee_id`, `reviewer_id`, `period`, `scores` (JSON), `total_score`, `notes`
3. Ejecutar migración SQL
4. Crear formulario de evaluación para admin
5. Crear vista de historial para empleado

### Complejidad estimada
**Media** — 4 a 5 días de desarrollo

---

## Notas generales

- Todas las migraciones SQL deben ejecutarse en **Supabase Dashboard → SQL Editor**
  en el orden indicado por la fecha del nombre del archivo.
- Nunca subir `google-services.json`, claves privadas de Firebase ni el `.env`
  al repositorio. Están en `.gitignore`.
- El archivo `.env` debe tener siempre: `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
