# WordPress Migration - Quick Start Guide

**Für schnellen Einstieg - Detaillierte Anleitung: [WORDPRESS_BACKUP_MIGRATION.md](./WORDPRESS_BACKUP_MIGRATION.md)**

---

## 🚀 3-Schritte-Migration (30-60 Minuten)

### Schritt 1: Backup erstellen (10 Minuten)

**WordPress Admin → Plugins → Installieren**

1. Suche: **"Duplicator"**
2. Installieren & Aktivieren
3. **Duplicator → Packages → Create New**
4. Name: `asv-backup`
5. **Next → Build → Warten**
6. **Downloade BEIDE Dateien:**
   - `installer.php`
   - `asv-backup_archive.zip`

---

### Schritt 2: Neues Hosting buchen (20 Minuten)

**Empfehlung: ALL-INKL Privat Plus (4,95 €/Monat)**

1. https://all-inkl.com/ → Paket buchen
2. **KAS-Login öffnen** (Zugangsdaten per E-Mail)
3. **Datenbank erstellen:**
   - KAS → Datenbank-Administration → Neue Datenbank
   - Name: `wordpress_db`
   - Passwort: [generiere starkes Passwort]
   - **NOTIERE:** DB-Name, User, Passwort

---

### Schritt 3: WordPress migrieren (20-40 Minuten)

**Per FTP (FileZilla):**

1. FTP-Zugangsdaten aus KAS kopieren
2. FileZilla: Mit neuem Server verbinden
3. **Uploade BEIDE Duplicator-Dateien:**
   - `installer.php`
   - `asv-backup_archive.zip`

**Im Browser:**

1. Öffne: `http://[DEINE-IP]/installer.php`
2. **Archive:** Automatisch erkannt → **Next**
3. **Systemcheck:** → **Next**
4. **Datenbank:**
   - Host: `localhost`
   - Database: `wordpress_db`
   - User: [dein DB-User]
   - Password: [dein DB-Passwort]
   - **Test Database** → ✅ → **Next**
5. **URLs:**
   - Old: `https://asv-petri-heil.de/cms`
   - New: `https://deine-neue-domain.de` (oder gleich lassen)
   - **Next**
6. **Fertig!** ✅

**Aufräumen (wichtig!):**

Per FTP lösche:
- `installer.php`
- `installer-log.txt`
- `installer-data.sql`
- `asv-backup_archive.zip`

---

## ✅ Checkliste nach Migration

- [ ] Startseite lädt
- [ ] Login funktioniert
- [ ] Events werden angezeigt
- [ ] Bilder werden angezeigt
- [ ] SSL-Zertifikat aktiviert (https://)
- [ ] Admin-Passwort geändert
- [ ] Permalinks neu generiert (Einstellungen → Permalinks → Speichern)

---

## 💰 Hosting-Empfehlungen

| Anbieter | Paket | €/Monat | Eignung |
|----------|-------|---------|---------|
| **ALL-INKL** | Privat Plus | 4,95 | ⭐ Einfach, Managed |
| **Hetzner** | CX11 Cloud | 4,15 | ⭐ Flexibel, Cloud |
| **Netcup** | Webhosting 2000 | 2,99 | ⭐ Günstigste Option |

---

## 🆘 Probleme?

**"401 Unauthorized" beim Installer:**
- Prüfe Datenbank-Zugangsdaten
- Prüfe ob Datenbank existiert (phpMyAdmin)

**"White Screen" nach Migration:**
- Lösche Browser-Cache
- Deaktiviere Caching-Plugins temporär
- Prüfe Fehler-Log (cPanel → Error Logs)

**Bilder werden nicht angezeigt:**
- Prüfe `/wp-content/uploads/` Ordner (per FTP)
- Permalinks neu generieren
- Prüfe URLs in Datenbank (wp_options)

---

## 📚 Mehr Infos?

**Vollständige Anleitung:** [WORDPRESS_BACKUP_MIGRATION.md](./WORDPRESS_BACKUP_MIGRATION.md)

Enthält:
- Manuelle Backup-Methoden
- Cloud Server Setup (Hetzner)
- Security Best Practices
- Performance-Optimierung
- Wartungsplan
- Notfall-Plan

---

**Viel Erfolg! 🚀**
