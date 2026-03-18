#!/bin/bash
# ============================================================
# WorkSense - Script de estructura de carpetas
# Ejecutar desde la raiz del proyecto Flutter:
#   bash create_structure.sh
# ============================================================

echo "🚀 Creando estructura de WorkSense..."

# Funcion para crear carpeta con .gitkeep
mkd() {
  mkdir -p "$1"
  touch "$1/.gitkeep"
}

# ── CORE ────────────────────────────────────────────────────
mkd lib/core/constants
mkd lib/core/errors
mkd lib/core/extensions
mkd lib/core/theme
mkd lib/core/utils
mkd lib/core/network

# ── DOMAIN (capa de negocio pura) ───────────────────────────
mkd lib/domain/entities
mkd lib/domain/repositories
mkd lib/domain/usecases

# ── DATA (implementaciones) ─────────────────────────────────
mkd lib/data/datasources/local
mkd lib/data/datasources/remote
mkd lib/data/models/local
mkd lib/data/models/remote
mkd lib/data/mappers
mkd lib/data/repositories

# ── FEATURES ────────────────────────────────────────────────

# Auth
mkd lib/features/auth/presentation/screens
mkd lib/features/auth/presentation/widgets
mkd lib/features/auth/presentation/providers
mkd lib/features/auth/domain/entities
mkd lib/features/auth/domain/usecases
mkd lib/features/auth/data/datasources
mkd lib/features/auth/data/models
mkd lib/features/auth/data/repositories

# Dashboard
mkd lib/features/dashboard/presentation/screens
mkd lib/features/dashboard/presentation/widgets
mkd lib/features/dashboard/presentation/providers
mkd lib/features/dashboard/domain/entities
mkd lib/features/dashboard/domain/usecases
mkd lib/features/dashboard/data/datasources
mkd lib/features/dashboard/data/models
mkd lib/features/dashboard/data/repositories

# Camera Monitor (Kiosk Mode)
mkd lib/features/camera_monitor/presentation/screens
mkd lib/features/camera_monitor/presentation/widgets
mkd lib/features/camera_monitor/presentation/providers
mkd lib/features/camera_monitor/domain/entities
mkd lib/features/camera_monitor/domain/usecases
mkd lib/features/camera_monitor/data/datasources
mkd lib/features/camera_monitor/data/models
mkd lib/features/camera_monitor/data/repositories

# AI Pipeline
mkd lib/features/ai_pipeline/pose_analyzer
mkd lib/features/ai_pipeline/face_analyzer
mkd lib/features/ai_pipeline/activity_classifier
mkd lib/features/ai_pipeline/embedding_engine

# Employees
mkd lib/features/employees/presentation/screens
mkd lib/features/employees/presentation/widgets
mkd lib/features/employees/presentation/providers
mkd lib/features/employees/domain/entities
mkd lib/features/employees/domain/usecases
mkd lib/features/employees/data/datasources
mkd lib/features/employees/data/models
mkd lib/features/employees/data/repositories

# Workstations
mkd lib/features/workstations/presentation/screens
mkd lib/features/workstations/presentation/widgets
mkd lib/features/workstations/presentation/providers
mkd lib/features/workstations/domain/entities
mkd lib/features/workstations/domain/usecases
mkd lib/features/workstations/data/datasources
mkd lib/features/workstations/data/models
mkd lib/features/workstations/data/repositories

# Analytics
mkd lib/features/analytics/presentation/screens
mkd lib/features/analytics/presentation/widgets
mkd lib/features/analytics/presentation/providers
mkd lib/features/analytics/domain/usecases
mkd lib/features/analytics/data/datasources
mkd lib/features/analytics/data/models
mkd lib/features/analytics/data/repositories

# Reports
mkd lib/features/reports/presentation/screens
mkd lib/features/reports/presentation/widgets
mkd lib/features/reports/presentation/providers
mkd lib/features/reports/domain/usecases
mkd lib/features/reports/data/datasources
mkd lib/features/reports/data/repositories

# Alerts
mkd lib/features/alerts/presentation/screens
mkd lib/features/alerts/presentation/widgets
mkd lib/features/alerts/presentation/providers
mkd lib/features/alerts/domain/usecases
mkd lib/features/alerts/data/datasources
mkd lib/features/alerts/data/models
mkd lib/features/alerts/data/repositories

# Settings
mkd lib/features/settings/presentation/screens
mkd lib/features/settings/presentation/widgets
mkd lib/features/settings/presentation/providers

# Setup Wizard (SUPER_ADMIN)
mkd lib/features/setup_wizard/presentation/screens
mkd lib/features/setup_wizard/presentation/widgets
mkd lib/features/setup_wizard/presentation/providers
mkd lib/features/setup_wizard/domain/usecases

# Employee Panel (rol EMPLOYEE)
mkd lib/features/employee_panel/presentation/screens
mkd lib/features/employee_panel/presentation/widgets
mkd lib/features/employee_panel/presentation/providers

# ── SHARED (componentes reutilizables) ──────────────────────
mkd lib/shared/widgets
mkd lib/shared/providers
mkd lib/shared/services
mkd lib/shared/extensions

# ── ASSETS ──────────────────────────────────────────────────
mkd assets/images
mkd assets/icons
mkd assets/fonts

# ── SUPABASE MIGRATIONS ─────────────────────────────────────
mkd supabase/migrations
mkd supabase/seed

# ── TESTS ───────────────────────────────────────────────────
mkd test/unit/features/ai_pipeline
mkd test/unit/features/auth
mkd test/unit/features/employees
mkd test/unit/core
mkd test/widget/features/dashboard
mkd test/widget/features/camera_monitor
mkd test/integration

echo ""
echo "✅ Estructura creada exitosamente."
echo ""
echo "📋 Proximos pasos:"
echo "   1. Copia pubspec.yaml al proyecto"
echo "   2. Ejecuta: flutter pub get"
echo "   3. Copia analysis_options.yaml"
echo "   4. Configura .env y .env.example"
echo "   5. Commit: 'chore: estructura base del proyecto'"
