$savePath = "C:\AuditLog"
$fileName = "Event_4663_$((Get-Date).ToString('yyyyMMdd')).txt"
$filePath = Join-Path -Path $savePath -ChildPath $fileName
$yesterday = (Get-Date).AddDays(-1)
$events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663; StartTime=$yesterday}

function ShouldIgnoreFile($fileName) {
    $ignorePatterns = @(".tmp", ".~lock.")
    foreach ($pattern in $ignorePatterns) {
        if ($fileName -like "*$pattern*") {
            return $true
        }
    }
    return $false
}


foreach ($event in $events) {
    $eventXml = [xml]$event.ToXml()
    $eventData = $eventXml.Event.EventData.Data
    $objectName = $($eventData | Where-Object {$_.Name -eq 'ObjectName'} | Select-Object -ExpandProperty '#text')
    if (ShouldIgnoreFile($objectName)) {
        Write-Host "Ignorando evento para arquivo: $objectName"
        continue
    }

    $details = @"
-
  Ação: "Delete"
  Usuário: $($eventData | Where-Object {$_.Name -eq 'SubjectUserName'} | Select-Object -ExpandProperty '#text')
  Tipo: $($eventData | Where-Object {$_.Name -eq 'ObjectType'} | Select-Object -ExpandProperty '#text')
  Caminho: $($eventData | Where-Object {$_.Name -eq 'ObjectName'} | Select-Object -ExpandProperty '#text')
-

"@
    $details | Out-File -FilePath $filePath -Append
}

Write-Host "Eventos do dia salvos com sucesso em $filePath"
