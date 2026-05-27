param()

$ErrorActionPreference = "Stop"

try {
  $status = git status --porcelain
  if ([string]::IsNullOrWhiteSpace($status)) {
    # Keine offenen Aenderungen -> keine Nachfrage.
    Write-Output '{ "followup_message": "" }'
    exit 0
  }

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
