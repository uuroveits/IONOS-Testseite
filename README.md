# IONOS Testseite

Einfache statische Webseite mit Kontaktformular und FTPS-Upload zu IONOS.

## Projektinhalt

- `index.html` - Startseite
- `styles.css` - Styling
- `kontakt.php` - Kontaktformular-Backend
- `web.config` - Standarddokument-Konfiguration fuer IIS/IONOS
- `upload-ionos.ps1` - Uploadskript (FTPS explizit)

## Lokale Nutzung

Die Seite kann lokal direkt per Doppelklick auf `index.html` geoeffnet werden.

## Upload zu IONOS

Standardbefehl:

```powershell
.\upload-ionos.ps1 -UseFtps -Port 21 -User u124210619
```

Hinweise:

- Der Upload nutzt explizites FTPS (wie FileZilla: FTP + TLS).
- Zielpfad ist standardmaessig `/wwwroot`.
- Beim ersten Lauf wird das FTP-Passwort abgefragt.
- Optional kann das Passwort verschluesselt gespeichert werden.

### Passwortdatei

- Datei: `ionos.ftp.pass.sec`
- Wird aus Sicherheitsgruenden **nicht** versioniert (`.gitignore`).
- Wenn der Login nicht klappt, Passwortdatei loeschen und neu eingeben:

```powershell
Remove-Item .\ionos.ftp.pass.sec -ErrorAction SilentlyContinue
```

## Git-Workflow

Typischer Ablauf:

```powershell
git add .
git commit -m "Aenderung beschreiben"
git push
```

## Automatische Nachfrage (Commit/Push/Upload)

Im Projekt ist ein Cursor-Hook konfiguriert:

- `.cursor/hooks.json`
- `.cursor/hooks/ask-commit-push-upload.ps1`

Wenn nach einer Agent-Antwort uncommittete Aenderungen existieren, wird automatisch gefragt, ob:

1. committed werden soll
2. gepusht werden soll
3. zu IONOS hochgeladen werden soll

## Setup auf neuem Geraet

1. Repository klonen
2. In Cursor oeffnen
3. Einmal Upload mit Passworteingabe starten:

```powershell
.\upload-ionos.ps1 -UseFtps -Port 21 -User u124210619
```

4. Optional Passwort speichern bestaetigen

Damit ist das Geraet fuer weitere Uploads eingerichtet.
