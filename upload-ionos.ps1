param(
  [string]$FtpHost = "access-5019567185.webspace-host.com",
  [string]$User = "su452804",
  [string]$RemoteDir = "wwwroot",
  [switch]$UseFtps
)

$ErrorActionPreference = "Stop"

function Assert-FileExists {
  param([string]$Path)
  if (-not (Test-Path -Path $Path -PathType Leaf)) {
    throw "Datei nicht gefunden: $Path"
  }
}

Write-Host "IONOS Upload gestartet" -ForegroundColor Cyan
Write-Host "Host: $FtpHost"
Write-Host "Remote-Verzeichnis: $RemoteDir"

$enteredUser = Read-Host "FTP-Benutzername (Enter fuer '$User')"
if (-not [string]::IsNullOrWhiteSpace($enteredUser)) {
  $User = $enteredUser
}
$securePassword = Read-Host "FTP-Passwort" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

try {
  $files = @("index.html", "styles.css", "web.config", "kontakt.php")
  foreach ($file in $files) {
    Assert-FileExists -Path $file
  }

  $scheme = if ($UseFtps) { "ftps" } else { "ftp" }
  $baseUri = "{0}://{1}:{2}@{3}/{4}" -f $scheme, $User, $plainPassword, $FtpHost, $RemoteDir

  foreach ($file in $files) {
    $target = "$baseUri/$file"
    Write-Host "Lade hoch: $file -> $FtpHost/$RemoteDir/$file"

    & curl.exe --silent --show-error --fail --ftp-create-dirs -T $file $target

    Write-Host "OK: $file" -ForegroundColor Green
  }

  Write-Host "Upload abgeschlossen." -ForegroundColor Green
  Write-Host "Teste jetzt deine Domain im Browser."
}
finally {
  if ($plainPassword) {
    $plainPassword = $null
  }
}
