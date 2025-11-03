# WordPress Backup & Migration Guide

**Ziel:** Die bestehende WordPress-Seite von `https://asv-petri-heil.de/cms` auf einen eigenen Server migrieren, um Hosting-Kosten zu sparen.

**Zeitaufwand:**
- Backup erstellen: 30-60 Minuten
- Server einrichten: 2-4 Stunden (erstmalig)
- Migration: 1-2 Stunden
- **Gesamt: 4-7 Stunden**

**Kostenersparnis:**
- Aktuelles Hosting: ??? €/Monat (prüfen!)
- Self-Hosting: **3-10 €/Monat**
- **Ersparnis: ~50-200 €/Jahr**

---

## 📋 Inhaltsverzeichnis

1. [Vorbereitung & Checkliste](#vorbereitung)
2. [Methode 1: Backup mit Plugin (Empfohlen)](#methode-1-backup-mit-plugin)
3. [Methode 2: Manuelles Backup](#methode-2-manuelles-backup)
4. [Methode 3: Hoster-Backup](#methode-3-hoster-backup)
5. [Neuen Server einrichten](#neuen-server-einrichten)
6. [WordPress migrieren](#wordpress-migrieren)
7. [Nach-Migration Checkliste](#nach-migration-checkliste)
8. [Hosting-Kostenvergleich](#hosting-kostenvergleich)
9. [Wartung & Best Practices](#wartung--best-practices)

---

## 1. Vorbereitung & Checkliste {#vorbereitung}

### Was du benötigst:

- ✅ WordPress Admin-Zugang (hast du: `Bosse der Jugend`)
- ✅ FTP/SFTP Zugangsdaten (vom aktuellen Hoster)
- ✅ Datenbank-Zugang (phpMyAdmin oder MySQL-Credentials)
- ✅ Mindestens **5 GB freien Speicherplatz** auf deinem Computer
- ⏱️ **2-3 Stunden Zeit** (nicht unterbrechen!)

### Wichtige Informationen sammeln:

**Schreibe diese Infos auf, BEVOR du startest:**

```
Aktuelle WordPress-URL: https://asv-petri-heil.de/cms
WordPress-Version: ??? (prüfen unter: Dashboard > Aktualisierungen)
PHP-Version: ??? (prüfen unter: Werkzeuge > Website-Zustand)
MySQL-Version: ??? (prüfen unter: Werkzeuge > Website-Zustand)

Installierte Plugins (wichtig):
- The Events Calendar (✓)
- WP Armour (Spam-Schutz)
- Duplicator (?)
- [Weitere notieren...]

Aktive Themes:
- Name: ???
- Version: ???

Dateigröße (geschätzt):
- Uploads-Ordner: ??? MB
- Gesamte WordPress-Installation: ??? MB
- Datenbank: ??? MB
```

**Wie bekommst du diese Infos?**

1. WordPress Admin → **Dashboard → Aktualisierungen** (WordPress-Version)
2. WordPress Admin → **Werkzeuge → Website-Zustand → Info** (PHP, MySQL)
3. WordPress Admin → **Plugins** (Liste aller Plugins)
4. WordPress Admin → **Design → Themes** (Aktives Theme)

---

## 2. Methode 1: Backup mit Plugin (⭐ EMPFOHLEN) {#methode-1-backup-mit-plugin}

### Warum Plugin-Backup?
✅ Einfach & sicher
✅ Automatische Komprimierung
✅ Wiederherstellung inklusive
✅ Keine technischen Kenntnisse nötig

### 2.1 Plugin installieren: **Duplicator**

**Duplicator** ist kostenlos und spezialisiert auf Migration.

**Schritt 1: Plugin installieren**

1. WordPress Admin → **Plugins → Installieren**
2. Suche nach **"Duplicator"**
3. Klicke auf **"Jetzt installieren"**
4. Klicke auf **"Aktivieren"**

**Schritt 2: Backup erstellen**

1. WordPress Admin → **Duplicator → Packages**
2. Klicke auf **"Create New"**

**Schritt 3: Package konfigurieren**

```
Name: asv-petri-heil-backup
Storage: Default
Archive:
  ☑ Include all files
  ☑ Include database

Advanced Options (optional):
  Exclude:
    ☑ Cache folders
    ☑ Backup folders (alte Backups)
```

3. Klicke auf **"Next"**

**Schritt 4: Scan durchführen**

Duplicator scannt jetzt deine WordPress-Installation:

- ✅ **Grün**: Alles OK
- ⚠️ **Gelb**: Warnung (meist unkritisch)
- ❌ **Rot**: Problem (muss behoben werden)

**Häufige Warnungen:**

| Warnung | Lösung |
|---------|--------|
| "Large Files" | OK, ignorieren |
| "PHP Version" | OK, falls > 7.4 |
| "Safe Mode" | Mit Hoster klären |

4. Klicke auf **"Build"**

**Schritt 5: Backup herunterladen**

⏱️ **Dauer: 5-30 Minuten** (abhängig von Größe)

Nach Fertigstellung:

1. Klicke auf **"Installer"** → Datei wird heruntergeladen: `installer.php`
2. Klicke auf **"Archive"** → Datei wird heruntergeladen: `[name]_archive.zip`

**Du benötigst BEIDE Dateien!**

**Typische Dateigrößen:**
- Kleine Seite: 50-200 MB
- Mittelgroße Seite: 200-1000 MB
- Große Seite: 1-5 GB

---

### 2.2 Alternative: UpdraftPlus (für regelmäßige Backups)

**Schritt 1: Plugin installieren**

1. WordPress Admin → **Plugins → Installieren**
2. Suche nach **"UpdraftPlus"**
3. Installieren & Aktivieren

**Schritt 2: Backup erstellen**

1. WordPress Admin → **Einstellungen → UpdraftPlus Backups**
2. Tab: **"Sichern / Wiederherstellen"**
3. Klicke auf **"Jetzt sichern"**

```
☑ Dateien sichern
☑ Datenbank sichern
☐ An entfernten Speicher senden (für jetzt: NEIN)
```

4. Klicke auf **"Jetzt sichern"**

**Schritt 3: Backup herunterladen**

Nach Fertigstellung siehst du das Backup in der Liste:

1. Klicke auf das Datum des Backups
2. Downloade alle Teile:
   - **Datenbank** (db.gz)
   - **Plugins** (plugins.zip)
   - **Themes** (themes.zip)
   - **Uploads** (uploads.zip)
   - **Others** (others.zip)

**Du benötigst ALLE Dateien!**

---

## 3. Methode 2: Manuelles Backup {#methode-2-manuelles-backup}

**Nur wenn Plugin-Backup nicht funktioniert!**

### 3.1 Dateien herunterladen (via FTP)

**Benötigt: FTP-Client (z.B. FileZilla)**

**Schritt 1: FTP-Zugangsdaten vom Hoster holen**

Kontaktiere deinen Hoster oder prüfe:
- Hoster Control Panel (cPanel, Plesk)
- Willkommens-E-Mail

**FTP-Zugangsdaten:**
```
Server: ftp.asv-petri-heil.de (oder IP-Adresse)
Benutzername: ???
Passwort: ???
Port: 21 (FTP) oder 22 (SFTP)
```

**Schritt 2: FileZilla installieren**

Download: https://filezilla-project.org/download.php?type=client

**Schritt 3: Mit FTP verbinden**

1. FileZilla öffnen
2. **Host:** `ftp.asv-petri-heil.de`
3. **Benutzername:** [dein FTP-User]
4. **Passwort:** [dein FTP-Passwort]
5. **Port:** `21`
6. Klicke auf **"Verbinden"**

**Schritt 4: WordPress-Ordner finden**

Navigiere zu: `/cms/` (da deine WordPress-Installation unter `/cms` liegt)

**Schritt 5: Alle Dateien herunterladen**

1. Rechtsklick auf `/cms/`
2. **"Herunterladen"**
3. Speicherort wählen (z.B. Desktop/wordpress-backup)

⏱️ **Dauer: 10-60 Minuten** (abhängig von Größe & Internet)

---

### 3.2 Datenbank exportieren (via phpMyAdmin)

**Schritt 1: phpMyAdmin öffnen**

Zugang über:
- Hoster Control Panel → **Datenbanken → phpMyAdmin**
- Direkt-URL (vom Hoster erfragen)

**Schritt 2: Datenbank auswählen**

Linke Sidebar: Klicke auf deine Datenbank (z.B. `asv_wp_database`)

**Schritt 3: Exportieren**

1. Tab: **"Exportieren"**
2. Methode: **"Schnell"**
3. Format: **"SQL"**
4. Klicke auf **"OK"**

Datei wird heruntergeladen: `datenbank.sql` (z.B. 5-50 MB)

**Schritt 4: Backup sichern**

Erstelle einen Ordner:
```
wordpress-backup-manuell/
├── cms/ (WordPress-Dateien von FTP)
└── database.sql (Datenbank-Export)
```

**Schritt 5: Komprimieren (optional)**

Rechtsklick auf `wordpress-backup-manuell/` → **"Komprimieren"** → ZIP

---

## 4. Methode 3: Hoster-Backup {#methode-3-hoster-backup}

**Prüfe ob dein Hoster automatische Backups anbietet!**

Viele Hoster haben:
- **Tägliche Backups** (letzten 7 Tage)
- **Wöchentliche Backups** (letzten 4 Wochen)
- **Ein-Klick-Wiederherstellung**

**Wo finden?**
- cPanel → **"Backups"**
- Plesk → **"Backup Manager"**
- Hoster-Support kontaktieren

**Vorteil:** Sehr schnell, kein Plugin nötig
**Nachteil:** Evtl. kostenpflichtig, nicht immer vollständig

---

## 5. Neuen Server einrichten {#neuen-server-einrichten}

### 5.1 Hosting-Anbieter wählen

Siehe [Hosting-Kostenvergleich](#hosting-kostenvergleich) unten.

**Empfehlung für Vereine:**

| Anbieter | Paket | Kosten | Eignung |
|----------|-------|--------|---------|
| **Hetzner** | CX11 Cloud Server | 4,15 €/Monat | ⭐ Beste Balance |
| **Netcup** | Webhosting 2000 | 2,99 €/Monat | ⭐ Günstigste Option |
| **ALL-INKL** | Privat Plus | 4,95 €/Monat | ⭐ Managed, einfach |

---

### 5.2 Server-Setup: Variante A - Managed Hosting (Einfach)

**Beispiel: ALL-INKL Privat Plus**

**Schritt 1: Paket buchen**

1. https://all-inkl.com/
2. Paket: **"Privat Plus"** (4,95 €/Monat)
3. Domain: **Bestehende Domain verbinden** (später)
4. Bestellung abschließen

**Schritt 2: KAS (Kundenverwaltung) öffnen**

Nach Buchung erhältst du:
```
KAS-Login: https://kas.all-inkl.com/
Benutzername: ???
Passwort: ???
```

**Schritt 3: Datenbank erstellen**

1. KAS → **"Datenbank-Administration"**
2. **"Neue Datenbank anlegen"**
3. Name: `wordpress_db`
4. Passwort: [sicheres Passwort generieren]
5. **Notiere:**
   - Datenbank-Name
   - Datenbank-User
   - Datenbank-Passwort
   - Datenbank-Host (meist: `localhost`)

**Schritt 4: FTP-Zugang erhalten**

Automatisch vorhanden:
```
FTP-Server: [dein-account].kasserver.com
FTP-User: [von ALL-INKL]
FTP-Passwort: [dein KAS-Passwort]
```

**Weiter zu:** [WordPress migrieren](#wordpress-migrieren)

---

### 5.3 Server-Setup: Variante B - Cloud Server (Flexibel)

**Beispiel: Hetzner CX11**

**⚠️ Erfordert Linux-Kenntnisse!**

**Schritt 1: Server bestellen**

1. https://www.hetzner.com/cloud
2. Projekt erstellen
3. Server hinzufügen:
   - **Standort:** Falkenstein (Deutschland)
   - **Image:** Ubuntu 22.04
   - **Type:** CX11 (2 GB RAM, 20 GB SSD)
   - **SSH-Key:** [erstelle einen SSH-Key]
   - **Name:** asv-wordpress-server

**Kosten: 4,15 €/Monat**

**Schritt 2: Per SSH verbinden**

```bash
ssh root@[SERVER-IP]
```

**Schritt 3: Server updaten**

```bash
apt update && apt upgrade -y
```

**Schritt 4: LAMP Stack installieren**

```bash
# Apache installieren
apt install apache2 -y

# MySQL installieren
apt install mysql-server -y

# PHP 8.1 installieren
apt install php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip -y

# Apache Module aktivieren
a2enmod rewrite
systemctl restart apache2
```

**Schritt 5: MySQL-Datenbank erstellen**

```bash
# MySQL öffnen
mysql -u root

# Datenbank erstellen
CREATE DATABASE wordpress_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# User erstellen
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'SICHERES_PASSWORT_HIER';

# Rechte vergeben
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Notiere:**
```
Datenbank: wordpress_db
User: wp_user
Passwort: [dein gewähltes Passwort]
Host: localhost
```

**Schritt 6: SSL-Zertifikat (Let's Encrypt)**

```bash
# Certbot installieren
apt install certbot python3-certbot-apache -y

# SSL-Zertifikat holen
certbot --apache -d asv-petri-heil.de -d www.asv-petri-heil.de
```

**Weiter zu:** [WordPress migrieren](#wordpress-migrieren)

---

## 6. WordPress migrieren {#wordpress-migrieren}

### 6.1 Migration mit Duplicator

**Schritt 1: Dateien hochladen**

Per FTP (FileZilla):

1. Verbinde zu deinem **neuen Server**
2. Navigiere zum Web-Root:
   - ALL-INKL: `/`
   - Hetzner: `/var/www/html/`
3. Lösche `index.html` (falls vorhanden)
4. Uploade die **beiden Duplicator-Dateien**:
   - `installer.php`
   - `[name]_archive.zip`

⏱️ **Dauer: 5-30 Minuten**

**Schritt 2: Installer aufrufen**

Öffne im Browser:
```
http://[NEUE-SERVER-IP]/installer.php
```

Oder falls Domain bereits umgezogen:
```
https://asv-petri-heil.de/cms/installer.php
```

**Schritt 3: Installation durchführen**

**Bildschirm 1: Archive auswählen**

1. Archive: `[name]_archive.zip` (automatisch erkannt)
2. Klicke auf **"Next"**

**Bildschirm 2: Systemcheck**

Prüft Server-Requirements:
- PHP Version ✓
- MySQL ✓
- Schreibrechte ✓

Klicke auf **"Next"**

**Bildschirm 3: Datenbank-Verbindung**

```
Host: localhost
Database: wordpress_db
User: wp_user
Password: [dein Datenbank-Passwort]
```

**Advanced Options:**
```
☐ Remove Rendundant Data (leer lassen)
```

Klicke auf **"Test Database"**

✅ Grüne Meldung: "Connection Success"

Klicke auf **"Next"**

**Bildschirm 4: URLs aktualisieren**

**WICHTIG: Hier änderst du die URLs!**

```
Old URL: https://asv-petri-heil.de/cms
New URL: https://deine-neue-domain.de/cms

ODER (falls du die Domain beibehältst):
Old URL: https://asv-petri-heil.de/cms
New URL: https://asv-petri-heil.de/cms (gleich lassen)
```

Klicke auf **"Next"**

**Bildschirm 5: Fertig!**

✅ Migration erfolgreich!

**WICHTIG:** Lösche die Installer-Dateien:
```
rm installer.php
rm [name]_archive.zip
rm installer-log.txt
rm installer-data.sql
```

---

### 6.2 Migration mit UpdraftPlus

**Schritt 1: WordPress frisch installieren**

1. Lade WordPress herunter: https://de.wordpress.org/download/
2. Entpacke und uploade per FTP
3. Rufe auf: `http://[SERVER-IP]/`
4. Installiere WordPress:
   - Datenbank: `wordpress_db`
   - User: `wp_user`
   - Passwort: [dein Passwort]
   - Präfix: `wp_` (Standard)

**Schritt 2: UpdraftPlus installieren**

1. WordPress Admin → **Plugins → Installieren**
2. Suche **"UpdraftPlus"**
3. Installieren & Aktivieren

**Schritt 3: Backup-Dateien hochladen**

1. Per FTP: Uploade alle Backup-Dateien nach:
   ```
   /wp-content/updraft/
   ```

   Dateien:
   - `backup_db.gz`
   - `backup_plugins.zip`
   - `backup_themes.zip`
   - `backup_uploads.zip`
   - `backup_others.zip`

**Schritt 4: Wiederherstellen**

1. WordPress Admin → **UpdraftPlus → Sichern/Wiederherstellen**
2. Tab: **"Vorhandene Sicherungen"**
3. Klicke auf **"Wiederherstellen"**
4. Wähle alle Komponenten:
   ```
   ☑ Plugins
   ☑ Themes
   ☑ Uploads
   ☑ Others
   ☑ Database
   ```
5. Klicke auf **"Restore"**

⏱️ **Dauer: 5-15 Minuten**

**Schritt 5: Neu einloggen**

Nach Wiederherstellung:
1. Gehe zu: `/wp-admin/`
2. Logge dich mit den **alten Zugangsdaten** ein

---

### 6.3 Manuelle Migration

**Schritt 1: WordPress frisch installieren**

(siehe oben: Migration mit UpdraftPlus → Schritt 1)

**Schritt 2: Dateien hochladen**

Per FTP:

1. Lösche auf dem **neuen Server**:
   - `/wp-content/plugins/` (Inhalt)
   - `/wp-content/themes/` (außer twentytwenty*)
   - `/wp-content/uploads/` (Inhalt)

2. Uploade von deinem **Backup**:
   - `backup/cms/wp-content/plugins/` → neuer Server `/wp-content/plugins/`
   - `backup/cms/wp-content/themes/` → neuer Server `/wp-content/themes/`
   - `backup/cms/wp-content/uploads/` → neuer Server `/wp-content/uploads/`

⏱️ **Dauer: 30-90 Minuten**

**Schritt 3: Datenbank importieren**

1. phpMyAdmin auf **neuem Server** öffnen
2. Datenbank auswählen: `wordpress_db`
3. Tab: **"Importieren"**
4. Datei wählen: `database.sql` (von Backup)
5. Klicke auf **"OK"**

**Schritt 4: URLs in Datenbank ändern**

**WICHTIG:** Die Datenbank enthält noch alte URLs!

1. phpMyAdmin → **SQL-Tab**
2. Führe diese Queries aus:

```sql
-- Prüfe aktuelle URLs
SELECT * FROM wp_options WHERE option_name IN ('siteurl', 'home');

-- URLs ändern
UPDATE wp_options SET option_value = 'https://neue-domain.de/cms' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://neue-domain.de/cms' WHERE option_name = 'home';

-- URLs in Posts/Pages ersetzen
UPDATE wp_posts SET post_content = REPLACE(post_content, 'https://asv-petri-heil.de/cms', 'https://neue-domain.de/cms');
UPDATE wp_posts SET guid = REPLACE(guid, 'https://asv-petri-heil.de/cms', 'https://neue-domain.de/cms');
```

**Schritt 5: wp-config.php anpassen**

Bearbeite `/wp-config.php`:

```php
define('DB_NAME', 'wordpress_db');
define('DB_USER', 'wp_user');
define('DB_PASSWORD', 'dein-neues-passwort');
define('DB_HOST', 'localhost');
```

**Schritt 6: Permalinks neu generieren**

1. WordPress Admin → **Einstellungen → Permalinks**
2. Klicke auf **"Änderungen speichern"** (ohne etwas zu ändern)

---

## 7. Nach-Migration Checkliste {#nach-migration-checkliste}

### ✅ Funktionalität prüfen

Teste ALLE wichtigen Bereiche:

- [ ] **Startseite** lädt korrekt
- [ ] **Events** (/cms/events/) werden angezeigt
- [ ] **Bilder/Uploads** werden angezeigt
- [ ] **Login** funktioniert
- [ ] **Formulare** funktionieren (Kontaktformular)
- [ ] **Google Maps** funktioniert (bei Events)

### ✅ Plugin-Checks

- [ ] **The Events Calendar** funktioniert
- [ ] Alle **Plugins sind aktiviert**
- [ ] Keine **PHP-Errors** (Werkzeuge → Website-Zustand)

### ✅ Performance

- [ ] **Caching aktiviert** (Plugin: WP Super Cache)
- [ ] **Bildkomprimierung** (Plugin: Smush)
- [ ] **SSL-Zertifikat** aktiv (https://)

### ✅ Sicherheit

- [ ] **Admin-Passwort geändert** (starkes Passwort!)
- [ ] **wp-config.php** Schreibschutz:
  ```bash
  chmod 440 wp-config.php
  ```
- [ ] **Security-Plugin** (WordFence oder Sucuri)
- [ ] **Automatische Updates** aktiviert

### ✅ SEO

- [ ] **Google Search Console** aktualisieren
- [ ] **Sitemap** neu einreichen
- [ ] **robots.txt** prüfen

---

## 8. Hosting-Kostenvergleich {#hosting-kostenvergleich}

### Managed Hosting (Einfach, kein technisches Wissen)

| Anbieter | Paket | €/Monat | €/Jahr | Speicher | Features |
|----------|-------|---------|--------|----------|----------|
| **ALL-INKL** | Privat Plus | 4,95 | 59,40 | 50 GB | ⭐ SSL, Backups, Support |
| **DomainFactory** | Managed WP M | 7,99 | 95,88 | 25 GB | SSL, Auto-Updates |
| **Webgo** | webgo 2000 | 5,95 | 71,40 | 40 GB | SSL, SSD, Support |
| **IONOS** | WordPress Starter | 4,00 | 48,00 | 10 GB | SSL, CDN |

**Empfehlung: ALL-INKL Privat Plus**
- Bestes Preis-Leistungs-Verhältnis
- Deutscher Support
- Tägliche Backups inklusive
- SSL-Zertifikat gratis

---

### Cloud Hosting (Flexibel, technisches Wissen erforderlich)

| Anbieter | Paket | €/Monat | €/Jahr | RAM | Speicher | Features |
|----------|-------|---------|--------|-----|----------|----------|
| **Hetzner** | CX11 | 4,15 | 49,80 | 2 GB | 20 GB SSD | ⭐ Snapshots, Floating IP |
| **Netcup** | VPS 200 G10 | 2,99 | 35,88 | 2 GB | 40 GB SSD | ⭐ Günstigste Option |
| **DigitalOcean** | Basic Droplet | 6,00 | 72,00 | 1 GB | 25 GB SSD | Globale Datacenter |
| **Contabo** | VPS S | 4,99 | 59,88 | 4 GB | 200 GB SSD | Viel Speicher |

**Empfehlung: Hetzner CX11**
- Beste Performance für den Preis
- Deutscher Anbieter, DSGVO-konform
- Rechenzentrum in Deutschland
- Snapshots für Backups

---

### Shared Hosting (Günstig, für kleine Seiten)

| Anbieter | Paket | €/Monat | €/Jahr | Speicher | Features |
|----------|-------|---------|--------|----------|----------|
| **Netcup** | Webhosting 2000 | 2,99 | 35,88 | 40 GB | ⭐ SSL, Backups, günstig |
| **HostEurope** | WebHosting M | 4,99 | 59,88 | 50 GB | SSL, Support |
| **1&1 IONOS** | Unlimited Plus | 8,00 | 96,00 | Unlimited | SSL, Website-Builder |

**Empfehlung: Netcup Webhosting 2000**
- Extrem günstig
- Ausreichend für Vereinsseite
- SSL & Backups inklusive

---

### 💰 Kostenvergleich Zusammenfassung

**Günstigste Option:**
- **Netcup Webhosting 2000** → **2,99 €/Monat** (35,88 €/Jahr)

**Beste Balance (Empfohlen):**
- **ALL-INKL Privat Plus** → **4,95 €/Monat** (59,40 €/Jahr)
- **Hetzner CX11 Cloud** → **4,15 €/Monat** (49,80 €/Jahr)

**Ersparnis-Rechnung:**

```
Aktueller Hoster: ??? €/Monat (Prüfe Rechnung!)
Neuer Hoster: 2,99-4,95 €/Monat

Beispiel:
Alter Hoster: 15 €/Monat = 180 €/Jahr
Neuer Hoster: 4,95 €/Monat = 59,40 €/Jahr
----------------------------------------
ERSPARNIS: 120,60 €/Jahr ✅
```

---

## 9. Wartung & Best Practices {#wartung--best-practices}

### 📅 Wöchentlich (10 Minuten)

- [ ] **WordPress-Updates** prüfen & installieren
- [ ] **Plugin-Updates** prüfen & installieren
- [ ] **Theme-Updates** prüfen & installieren
- [ ] **Kommentare** moderieren (Spam)

### 📅 Monatlich (30 Minuten)

- [ ] **Backup erstellen** (automatisch mit UpdraftPlus)
- [ ] **Backup herunterladen** (lokal speichern)
- [ ] **Sicherheit prüfen** (Dashboard → Werkzeuge → Website-Zustand)
- [ ] **Performance prüfen** (Google PageSpeed Insights)

### 📅 Vierteljährlich (1-2 Stunden)

- [ ] **Alte Plugins deaktivieren/löschen** (nicht mehr benötigt)
- [ ] **Datenbank optimieren** (Plugin: WP-Optimize)
- [ ] **Spam-Kommentare löschen** (dauerhaft)
- [ ] **Uploads-Ordner aufräumen** (alte/ungenutzte Bilder)

---

### 🔒 Sicherheits-Checkliste

#### Sofort umsetzen:

- [ ] **Starke Passwörter** für Admin-Accounts
- [ ] **2-Faktor-Authentifizierung** (Plugin: Two-Factor)
- [ ] **SSL-Zertifikat** installiert & aktiv
- [ ] **Admin-URL ändern** (Plugin: WPS Hide Login)
  - Standard: `/wp-admin/`
  - Neu: `/asv-geheim-login/`
- [ ] **Limit Login Attempts** (Plugin: Limit Login Attempts Reloaded)
- [ ] **Firewall** aktivieren (Plugin: WordFence)

#### Erweiterte Sicherheit:

- [ ] **Automatische Backups** (täglich)
- [ ] **Malware-Scan** (wöchentlich mit WordFence)
- [ ] **File Permissions** korrekt setzen:
  ```bash
  find /var/www/html -type d -exec chmod 755 {} \;
  find /var/www/html -type f -exec chmod 644 {} \;
  chmod 440 wp-config.php
  ```
- [ ] **WordPress Security Keys** regenerieren:
  - https://api.wordpress.org/secret-key/1.1/salt/
  - In `wp-config.php` einfügen

---

### ⚡ Performance-Optimierung

#### Caching (wichtig!)

**Plugin: WP Super Cache**

1. Installieren & Aktivieren
2. Einstellungen → WP Super Cache
3. Caching: **"An"**
4. Cache-Modus: **"Expert"**

**Erwartete Verbesserung:**
- Ladezeit: -50-70%
- Server-Last: -80%

#### Bildoptimierung

**Plugin: Smush**

1. Installieren & Aktivieren
2. Alle Bilder komprimieren (Bulk-Smush)

**Ersparnis:** 40-60% Dateigröße

#### Content Delivery Network (CDN)

**Optional: Cloudflare (kostenlos)**

1. Account erstellen: https://cloudflare.com
2. Domain hinzufügen: `asv-petri-heil.de`
3. DNS-Server ändern (bei Domain-Registrar)

**Vorteile:**
- Schnellere Ladezeiten weltweit
- DDoS-Schutz
- SSL-Zertifikat gratis
- Bandbreiten-Ersparnis

---

### 📊 Monitoring

#### Uptime-Monitoring (kostenlos)

**UptimeRobot:** https://uptimerobot.com

- Überwacht Website 24/7
- E-Mail bei Downtime
- Kostenlos bis 50 Websites

**Setup:**

1. Account erstellen
2. Monitor hinzufügen:
   - URL: `https://asv-petri-heil.de/cms`
   - Type: HTTP(s)
   - Interval: 5 Minuten

#### Performance-Monitoring

**Google Search Console:** https://search.google.com/search-console

- Prüft Ladezeiten
- Zeigt Fehler an
- Indexierungs-Status

---

### 🆘 Notfall-Plan

**Was tun wenn die Seite down ist?**

1. **Ruhe bewahren** 😌
2. **Prüfe Server-Status:**
   - Hoster-Control-Panel öffnen
   - Server-Status prüfen (online?)
3. **Prüfe Error-Logs:**
   - cPanel → Error Logs
   - Oder per SSH: `/var/log/apache2/error.log`
4. **Letzte Änderung rückgängig machen:**
   - Plugin/Theme deaktiviert? → Reaktivieren
   - Update gemacht? → Downgrade
5. **Backup wiederherstellen:**
   - Mit Duplicator oder UpdraftPlus
   - Letztes funktionierendes Backup

**Notfall-Kontakte:**

```
Hoster-Support: ??? (Telefonnummer notieren!)
WordPress-Experte: ??? (optional)
```

---

## 📝 Zusammenfassung

### ✅ Was du erreicht hast:

1. **WordPress-Backup erstellt** (vollständig)
2. **Neuen günstigen Server eingerichtet**
3. **WordPress erfolgreich migriert**
4. **Kosten gespart:** ~50-200 €/Jahr

### 🎯 Zeitinvestition vs. Ersparnis:

```
Initiales Setup: 4-7 Stunden
Monatliche Wartung: 2-4 Stunden
Jährlicher Zeitaufwand: ~30-50 Stunden

Kostenersparnis: 120-200 €/Jahr
→ "Stundenlohn": 2,40-6,60 €/Stunde
```

**Lohnt es sich?**

✅ **JA, wenn:**
- Du langfristig sparen willst (5+ Jahre)
- Du Interesse an WordPress hast
- Du gerne Dinge selbst machst

❌ **NEIN, wenn:**
- Du keine Zeit hast (< 2 Std./Monat)
- Du keinen technischen Support hast
- Die Seite geschäftskritisch ist

---

## 🆘 Hilfe & Support

**Community:**
- WordPress Forum: https://wordpress.org/support/
- WordPress Deutschland: https://de.wordpress.org/
- Reddit: r/Wordpress

**Professionelle Hilfe:**
- Fiverr: WordPress-Experten ab 5 €
- Upwork: WordPress-Entwickler (Stundenbasis)

**Diese Anleitung:**
- Erstellt: 2025-11-03
- Version: 1.0
- Für: ASV Großostheim / Jonas Glawion

---

## 📚 Weitere Ressourcen

- [WordPress Codex](https://codex.wordpress.org/)
- [The Events Calendar Docs](https://docs.theeventscalendar.com/)
- [WordPress Security Guide](https://wordpress.org/support/article/hardening-wordpress/)
- [WP Beginner Tutorials](https://www.wpbeginner.com/)

---

**Viel Erfolg mit deiner Migration!** 🚀

Bei Fragen: Kontaktiere mich oder die WordPress-Community.
