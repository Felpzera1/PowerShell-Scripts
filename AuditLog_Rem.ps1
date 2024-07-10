$logDirectory = "C:\AuditLogs"
if (!(Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

$currentDate = Get-Date -Format "yyyy-MM-dd"

$logFilePath = "$logDirectory\auditlog-removidos-$currentDate.txt"

try {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security';
        Id = 4729, 4733;
        StartTime = (Get-Date).AddDays(-1)
    } | ForEach-Object {
        $eventXml = [xml]$_.ToXml()
        $eventDetails = @()

       
        foreach ($dataNode in $eventXml.Event.EventData.Data) {
            $nodeName = $dataNode.Name
            $nodeValue = $dataNode.'#text'
            $eventDetails += "$nodeName $nodeValue"
        }
        $eventDetailsString = @"
Ação:                "Removido"
Data e Hora:         $($_.TimeCreated)
Evento ID:           $($_.Id)
Responsável:         $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "SubjectUserName" } | Select-Object -ExpandProperty "#text")
Grupo:               $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" } | Select-Object -ExpandProperty "#text")
Usuário:             $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "MemberName" } | Select-Object -ExpandProperty "#text")

"@

        
        Add-Content -Path $logFilePath -Value $eventDetailsString
    }

   
    if ($events.Count -eq 0) {
        Write-Host "Nenhum evento de remoção de grupo encontrado."
    } else {
        Write-Host "Eventos de remoção de grupo coletados com sucesso."
    }
} catch {
    Write-Host "Erro ao coletar eventos de remoção de grupo: $_"
}

if (!(Test-Path -Path $logFilePath)) {
    Write-Host "O arquivo de log para remoções não foi criado em $logFilePath."
}
