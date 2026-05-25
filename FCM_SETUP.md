# Guía de configuración FCM (Firebase Cloud Messaging)

## Paso 1 — Crear proyecto en Firebase Console

1. Ve a https://console.firebase.google.com
2. Crea un nuevo proyecto (ej: `worksense-app`)
3. Desactiva Google Analytics si no lo necesitas → **Crear proyecto**

---

## Paso 2 — Registrar la app Android

1. En la consola de Firebase → **Agregar app** → Android
2. Nombre del paquete: `com.co.work_sense`
3. Apodo: `WorkSense Android`
4. Descarga el archivo **`google-services.json`**
5. Colócalo en: `android/app/google-services.json`

---

## Paso 3 — Desplegar la Supabase Edge Function

### 3a. Instalar Supabase CLI (si no lo tienes)
```bash
npm install -g supabase
```

### 3b. Login y link al proyecto
```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
```

### 3c. Desplegar la función
```bash
supabase functions deploy send-push --no-verify-jwt
```

> `--no-verify-jwt` permite que la función sea llamada desde el SDK de Supabase
> con el anon key del usuario autenticado.

---

## Paso 4 — Configurar variables de entorno en la Edge Function

Ve a tu proyecto en https://supabase.com → **Edge Functions** → **send-push** → **Secrets**

Agrega estos dos secrets:

### `FIREBASE_SERVICE_ACCOUNT`

1. Firebase Console → **Configuración del proyecto** → **Cuentas de servicio**
2. **Generar nueva clave privada** → descarga el JSON
3. Copia el contenido COMPLETO del JSON (incluyendo las llaves `{}`)
4. Pégalo como valor del secret `FIREBASE_SERVICE_ACCOUNT`

### `SUPABASE_SERVICE_ROLE_KEY`

1. Supabase Dashboard → **Configuración** → **API**
2. Copia el **service_role** key (NO el anon key)
3. Pégalo como valor del secret `SUPABASE_SERVICE_ROLE_KEY`

> `SUPABASE_URL` ya está disponible automáticamente en Edge Functions.

---

## Paso 5 — Ejecutar la migración SQL

En Supabase Dashboard → **SQL Editor**, ejecuta:

```
supabase/migrations/20260524070000_add_fcm_tokens.sql
```

---

## Paso 6 — Compilar y probar

```bash
flutter pub get
flutter run
```

Al iniciar sesión, la app registrará automáticamente el token FCM del dispositivo.

---

## Verificar que funciona

1. Asigna una tarea a un empleado desde la cuenta del admin
2. El empleado (con app cerrada o en background) debe recibir la notificación push
3. Al tocarla, la app debe abrir y navegar a `/tasks`

---

## Troubleshooting

| Problema | Solución |
|---|---|
| Build error: `google-services.json not found` | Asegúrate de poner el archivo en `android/app/` |
| Push no llega | Verifica el secret `FIREBASE_SERVICE_ACCOUNT` en Supabase |
| `FIREBASE_SERVICE_ACCOUNT no configurado` en logs | El secret no fue guardado correctamente |
| Token no se guarda | El usuario debe estar autenticado antes de que el token se registre |
