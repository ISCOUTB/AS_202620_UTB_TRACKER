# Apaga UTB Tracker: cierra lo que esté escuchando en los puertos 8000 y 8080,
# incluido el proceso "recargador" de uvicorn --reload que deja el puerto tomado.
param([switch]$Silencioso)

$pids = Get-NetTCPConnection -LocalPort 8000, 8080 -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
foreach ($id in $pids) {
    $padre = (Get-CimInstance Win32_Process -Filter "ProcessId=$id" -ErrorAction SilentlyContinue).ParentProcessId
    Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$padre" -ErrorAction SilentlyContinue
    if ($p -and $p.CommandLine -match 'uvicorn|http\.server') { Stop-Process -Id $padre -Force -ErrorAction SilentlyContinue }
}
Start-Sleep 1
$quedan = Get-NetTCPConnection -LocalPort 8000, 8080 -State Listen -ErrorAction SilentlyContinue
if ($quedan) {
    Write-Host 'No se pudieron liberar todos los puertos:' -ForegroundColor Yellow
    $quedan | Select-Object LocalPort, OwningProcess | Format-Table
} elseif (-not $Silencioso) {
    Write-Host 'UTB Tracker apagado (puertos 8000 y 8080 libres).' -ForegroundColor Green
}
