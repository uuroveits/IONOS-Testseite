param()

$ErrorActionPreference = "Stop"
$stateDir = ".cursor\hooks\.state"
$stateFile = Join-Path $stateDir "last-status-hash.txt"

function Get-Hash {
  param([string]$Value)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hash = $sha.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant()
  }
  finally {
    $sha.Dispose()
  }
}

try {
  $status = git status --porcelain
  if ([string]::IsNullOrWhiteSpace($status)) {
    # Keine offenen Aenderungen -> keine Nachfrage.
    if (-not (Test-Path -Path $stateDir -PathType Container)) {
      New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $stateFile -NoNewline -Value ""
    Write-Output '{ "followup_message": "" }'
    exit 0
  }

  $currentHash = Get-Hash -Value $status
  $previousHash = ""
  if (Test-Path -Path $stateFile -PathType Leaf) {
    $previousHash = (Get-Content -Path $stateFile -Raw).Trim()
  }

  if ($currentHash -eq $previousHash) {
    # Keine neuen Aenderungen seit der letzten Nachfrage.
    Write-Output '{ "followup_message": "" }'
    exit 0
  }

  if (-not (Test-Path -Path $stateDir -PathType Container)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
  }
  Set-Content -Path $stateFile -NoNewline -Value $currentHash

  $message = @"
Es gibt ungesicherte Aenderungen im Projekt.
Soll ich jetzt fuer dich:
1) committen
2) pushen
3) zur IONOS hochladen

Antworte z. B. mit: "ja, alle drei" oder nur mit den Nummern.
"@

  $result = @{
    followup_message = $message
  } | ConvertTo-Json -Compress

  Write-Output $result
  exit 0
}
catch {
  # Fail-open: Bei Fehlern den normalen Ablauf nicht blockieren.
  Write-Output '{ "followup_message": "" }'
  exit 0
}
