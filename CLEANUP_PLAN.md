# Projekt-Cleanup Plan

## 🗑️ Zu löschende Dateien/Verzeichnisse

### 1. Splash Screen (nicht verwendet)
- ❌ `features/splash/splash_screen.dart`
- ❌ `features/splash/` Verzeichnis komplett
- Grund: Im Router deaktiviert, nicht verwendet

### 2. Veraltete Root-Level Dokumentation
- ❌ `SETUP_NOTIFICATIONS.md` - Ersetzt durch docs/PUSH_NOTIFICATIONS_SETUP.md und docs/SCHEDULED_NOTIFICATIONS_SETUP.md

## 📦 Zu archivierende Dateien

### 1. Legacy Tools
- 📦 `tools/annual-export/` → `archive/tools/annual-export/`
- 📦 `tools/migration/` → `archive/tools/migration/`
- Grund: Möglicherweise alte/unbenutzte Migration-Scripts

### 2. Legacy Supabase Functions
- 📦 `supabase/functions/export_catches/` → `archive/supabase/functions/export_catches/`
- Grund: Möglicherweise veraltet, wird durch ExportPanel ersetzt

## 📝 Dokumentation zu konsolidieren

### In docs/ verschieben:
- `JUGEND_FEATURES.md` → `docs/JUGEND_FEATURES.md`
- `MEMBER_GROUPS_FEATURE.md` → `docs/MEMBER_GROUPS_FEATURE.md`
- `NOTIFICATION_SYSTEM.md` → `docs/NOTIFICATION_SYSTEM.md`

### README aktualisieren:
- Verweise auf neue Dokumentationsstruktur hinzufügen
- Index aller Features-Dokumentation

## ✨ Ergebnis

Nach dem Cleanup:
```
/
├── README.md (aktualisiert mit Links)
├── docs/
│   ├── JUGEND_FEATURES.md
│   ├── MEMBER_GROUPS_FEATURE.md
│   ├── NOTIFICATION_SYSTEM.md
│   ├── PUSH_NOTIFICATIONS_SETUP.md
│   └── SCHEDULED_NOTIFICATIONS_SETUP.md
├── archive/
│   ├── tools/
│   │   ├── annual-export/
│   │   └── migration/
│   └── supabase/
│       └── functions/
│           └── export_catches/
└── features/
    ├── (splash gelöscht)
    └── ...
```
