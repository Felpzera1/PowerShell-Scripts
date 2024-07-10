#importar 
Import-Module UpdateServices
$ErrorActionPreference = "SilentlyContinue"

#conectar 
$wsus = Get-WsusServer -Name "WSUS01" -PortNumber 8530

#lista 
$computers = $wsus.GetComputerTargets()

# Criar lista de objetos
$computerList = $computers | ForEach-Object {
# Extrair dominio
    $computerName = $_.FullDomainName -replace "\.redetop\.com\.br$", ""
    [PSCustomObject]@{
        Nome = $computerName
    }
}

#Exportar para arquivo
$computerList | Export-Csv -Path "C:\Computers.csv" -NoTypeInformation -Encoding UTF8


#Exportar na tela
#$computerList

# Caminho para o arquivo CSV 
$csvPath = "C:\Computers.csv"

# Caminho para o PsExec 
$psexecPath = "C:\Windows\System32\PsExec.exe"

# Comando que você deseja executar remotamente

#$remoteCommand = "net stop wuauserv"
#$remoteCommand = "cd %systemroot%\SoftwareDistribution"
#$remoteCommand = "ren Download Download.old"
#$remoteCommand = "net start wuauserv"
#$remoteCommand = "net stop bits"
#$remoteCommand = "net start bits"
$remoteCommand = "Wuauclt.exe /resetauthorization /detectnow"

# Ler a lista de computadores do arquivo CSV
$computerList = Import-Csv -Path $csvPath

# Executar o comando em cada computador
foreach ($computer in $computerList)  {
    $computerName = $computer.Nome 
    
    # Construir o comando PsExec
    $psexecCommand = "$psexecPath \\$computerName -s $remoteCommand"
    
    # Executar o comando PsExec
    Write-Host "Executando comando em $computerName..."
    Invoke-Expression $psexecCommand

} 

#Gerando o log final, sinalizando os erros e sucesso na execução

$logPath = "C:\log.txt"
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logPath -Append
}

# Função para gerar relatório ao final do processo
function Generate-Report {
    # Lógica para determinar sucesso ou falha do processo
    if ($error) {
        Write-Log "O processo falhou."
        Write-Log "Detalhes do erro:"
        $error | ForEach-Object { Write-Log $_.Exception }
    } else {
        Write-Log "O processo foi concluído com sucesso."
    }
}

# Exemplo de uso
try {
    # Código do processo aqui
    Get-ChildItem "C:\log232323.txt"
} catch {
    Write-Error $_
}

# Gerar relatório ao final do processo
Generate-Report