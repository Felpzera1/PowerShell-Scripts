# Defina o diretório onde os logs serão salvos
$logDirectory = "C:\AuditLogs"
if (!(Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Defina a data atual
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Defina o caminho do arquivo de log para remoções
$logFilePath = "$logDirectory\auditlog-removidos-$currentDate.txt"

try {
    # Coletar eventos de remoção de grupo
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security';
        Id = 4729, 4733;
        StartTime = (Get-Date).AddDays(-1)
    } | ForEach-Object {
        # Converter o evento para XML 
        $eventXml = [xml]$_.ToXml()

        # Inicializar uma lista para armazenar todas as informações do evento
        $eventDetails = @()

        # Iterar sobre todos os elementos no XML do evento
        foreach ($dataNode in $eventXml.Event.EventData.Data) {
            $nodeName = $dataNode.Name
            $nodeValue = $dataNode.'#text'

            # Formatar cada informação como uma linha de texto
            $eventDetails += "$nodeName $nodeValue"
        }

        # Formatar a string com todas as informações do evento
        $eventDetailsString = @"
Ação:                "Removido"
Data e Hora:         $($_.TimeCreated)
Evento ID:           $($_.Id)
Responsável:         $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "SubjectUserName" } | Select-Object -ExpandProperty "#text")
Grupo:               $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" } | Select-Object -ExpandProperty "#text")
Usuário:             $($eventXml.Event.EventData.Data | Where-Object { $_.Name -eq "MemberName" } | Select-Object -ExpandProperty "#text")

"@

        # Escrever no arquivo de log
        Add-Content -Path $logFilePath -Value $eventDetailsString
    }

    # Verificar se há eventos coletados
    if ($events.Count -eq 0) {
        Write-Host "Nenhum evento de remoção de grupo encontrado."
    } else {
        Write-Host "Eventos de remoção de grupo coletados com sucesso."
    }
} catch {
    Write-Host "Erro ao coletar eventos de remoção de grupo: $_"
}

# Verificar se o arquivo de log foi criado para remoções
if (!(Test-Path -Path $logFilePath)) {
    Write-Host "O arquivo de log para remoções não foi criado em $logFilePath."
}
