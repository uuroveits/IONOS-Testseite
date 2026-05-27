param(
  [string]$FtpHost = "access1085251142.webspace-data.io",
  [string]$User = "u124210619",
  [string]$RemoteDir = "wwwroot",
  [switch]$UseFtps = $true,
  [switch]$AllowInsecureTls,
  [switch]$SavePassword,
  [switch]$PlainPasswordPrompt = $true,
  [switch]$ForceIpv4 = $true,
  [int]$Port = 21
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Assert-FileExists {
  param([string]$Path)
  if (-not (Test-Path -Path $Path -PathType Leaf)) {
    throw "Datei nicht gefunden: $Path"
  }
}

$passwordFile = "ionos.ftp.pass.sec"

function Read-PasswordSecurely {
  if ($PlainPasswordPrompt) {
    do {
      $pw1 = Read-Host "FTP-Passwort (sichtbar)"
      $pw2 = Read-Host "FTP-Passwort wiederholen"
      if ($pw1 -ne $pw2) {
        Write-Host "Passwoerter stimmen nicht ueberein. Bitte erneut eingeben." -ForegroundColor Yellow
      }
    } while ($pw1 -ne $pw2)
    return (ConvertTo-SecureString -String $pw1 -AsPlainText -Force)
  }

  return (Read-Host "FTP-Passwort" -AsSecureString)
}

function Get-SecurePassword {
  param([string]$PasswordFilePath)

  if (Test-Path -Path $PasswordFilePath -PathType Leaf) {
    try {
      $encrypted = (Get-Content -Path $PasswordFilePath -Raw).Trim()
      if ([string]::IsNullOrWhiteSpace($encrypted)) {
        throw "Passwortdatei ist leer."
      }
      Write-Host "Nutze gespeichertes FTP-Passwort ($PasswordFilePath)."
      $secure = ($encrypted | ConvertTo-SecureString)
      $plain = [System.Net.NetworkCredential]::new("", $secure).Password
      if ([string]::IsNullOrEmpty($plain) -or $plain.Length -lt 2) {
        throw "Passwortdatei enthaelt kein gueltiges Passwort."
      }
      return $secure
    }
    catch {
      Write-Host "Gespeicherte Passwortdatei ist ungueltig und wird neu erstellt." -ForegroundColor Yellow
      Remove-Item -Path $PasswordFilePath -ErrorAction SilentlyContinue
    }
  }

  $entered = Read-PasswordSecurely

  $save = $SavePassword
  if (-not $SavePassword) {
    $savePrompt = Read-Host "Passwort verschluesselt speichern? (j/n)"
    $save = $savePrompt -match '^(j|ja|y|yes)$'
  }

  if ($save) {
    $entered | ConvertFrom-SecureString | Set-Content -Path $PasswordFilePath -NoNewline
    Write-Host "Passwort verschluesselt gespeichert: $PasswordFilePath" -ForegroundColor Green
  }

  return $entered
}

function Convert-SecureToPlainText {
  param(
    [Parameter(Mandatory = $true)]
    [Security.SecureString]$SecureValue
  )

  return [System.Net.NetworkCredential]::new("", $SecureValue).Password
}

Write-Host "IONOS Upload gestartet" -ForegroundColor Cyan
Write-Host "Server: verbunden"
Write-Host "Zielpfad: /$RemoteDir"

$enteredUser = Read-Host "FTP-Benutzername (Enter fuer '$User')"
if (-not [string]::IsNullOrWhiteSpace($enteredUser)) {
  $User = $enteredUser
}
Write-Host "FTP-Benutzer: $User"
$securePassword = Get-SecurePassword -PasswordFilePath $passwordFile
$plainPassword = Convert-SecureToPlainText -SecureValue $securePassword

try {
  $files = @("index.html", "styles.css", "web.config", "kontakt.php")
  $lastCurlExitCode = 0
  $lastCurlOutput = ""
  foreach ($file in $files) {
    Assert-FileExists -Path $file
  }

  $scheme = "ftp"
  Write-Host "Protokoll: FTPS (explizit)"
  Write-Host "Port: $Port"
  Write-Host ("Netzwerk: " + ($(if ($ForceIpv4) { "IPv4" } else { "Standard (IPv4/IPv6)" })))

  $normalizedRemoteDir = $RemoteDir.Trim("/")
  $baseUri = "{0}://{1}:{2}/{3}" -f $scheme, $FtpHost, $Port, $normalizedRemoteDir
  $auth = "{0}:{1}" -f $User, $plainPassword

  foreach ($file in $files) {
    $target = "$baseUri/$file"
    Write-Host "Lade hoch: $file -> /$RemoteDir/$file"

    $curlArgs = @(
      "--silent",
      "--show-error",
      "--fail",
      "--create-dirs",
      "--user", $auth,
      "-T", $file,
      $target
    )

    if ($ForceIpv4) {
      $curlArgs += "-4"
    }

    $curlArgs += "--ftp-pasv"

    if ($UseFtps) {
      $curlArgs += "--tlsv1.2"
      $curlArgs += "--ssl-reqd"
      $curlArgs += "--ftp-ssl-control"
      if ($AllowInsecureTls) {
        $curlArgs += "--insecure"
      }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $curlOutputLines = & curl.exe @curlArgs 2>&1
    $ErrorActionPreference = $previousErrorActionPreference
    $lastCurlExitCode = $LASTEXITCODE
    $lastCurlOutput = ($curlOutputLines -join "`n")
    if ($lastCurlExitCode -ne 0) {
      throw "Upload fehlgeschlagen fuer '$file' (curl exit code: $lastCurlExitCode)."
    }

    Write-Host "OK: $file" -ForegroundColor Green
  }

  Write-Host "Upload abgeschlossen." -ForegroundColor Green
  Write-Host "Teste jetzt deine Domain im Browser."
}
catch {
  Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
  if ($lastCurlOutput) {
    Write-Host "curl-Fehlerdetails:" -ForegroundColor Red
    Write-Host $lastCurlOutput -ForegroundColor Red
  }
  Write-Host "Tipps:" -ForegroundColor Yellow
  if ($lastCurlExitCode -eq 67 -or $lastCurlOutput -match "530") {
    Write-Host " - Login abgelehnt (530): FTP-Benutzer, FTP-Passwort und FTP-Rechte im IONOS-Panel pruefen."
    Write-Host " - Gespeichertes Passwort loeschen und neu eingeben: Remove-Item .\ionos.ftp.pass.sec"
    Write-Host " - Danach erneut testen: .\upload-ionos.ps1 -UseFtps -Port 21"
    Write-Host " - Hinweis: Der Fehler tritt vor dem Dateiupload auf, der Remote-Pfad ist hier nicht die Ursache."
  }
  elseif ($lastCurlExitCode -eq 35 -or $lastCurlOutput -match "SEC_E_INVALID_TOKEN") {
    Write-Host " - TLS-Handshake-Problem: explizites FTPS auf Port 21 pruefen."
    Write-Host " - Teste: .\upload-ionos.ps1 -UseFtps -Port 21 -AllowInsecureTls"
  }
  else {
    Write-Host " - Explizites FTPS: .\upload-ionos.ps1 -UseFtps -Port 21"
    Write-Host " - Zielordner pruefen: -RemoteDir wwwroot"
  }
  throw
}
finally {
  if ($plainPassword) {
    $plainPassword = $null
  }
}
