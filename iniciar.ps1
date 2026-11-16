# Arranca UTB Tracker en Windows con UN comando: API + worker de correos + app web, y la app
# apuntando a ESA API (ADR-0014). Así nunca te registras en un servidor y entras en otro.
#
#   .\iniciar.ps1                     # local completo: API, worker y app en este PC
#   .\iniciar.ps1 -ReiniciarDatos     # además recarga los datos de ejemplo
#   .\iniciar.ps1 -SinCompilar        # no recompila la app (más rápido si no cambiaste el frontend)
#   .\iniciar.ps1 -Nube               # solo la app, contra el servidor OFICIAL en la nube
#
# Servidor oficial: https://129-80-171-141.nip.io (el del APK). El local usa utb_tracker.db.
# Los correos en local NO se envían: se guardan en logs\correos\ (ábrelos para ver los enlaces).
# Para apagar todo: .\detener.ps1
param(
    [switch]$Nube,
    [switch]$ReiniciarDatos,
    [switch]$SinCompilar
)
# 'Continue': en PowerShell 5.1 los avisos por stderr de Python/Flutter (p. ej. SECRET_KEY)
# con 'Stop' abortan el script; cada paso ya valida su $LASTEXITCODE.
$ErrorActionPreference = 'Continue'
$raiz = $PSScriptRoot
$py = Join-Path $raiz 'venv\Scripts\python.exe'
$web = Join-Path $raiz 'frontend\build\web'
$logs = Join-Path $raiz 'logs'
$nube = 'https://129-80-171-141.nip.io'
$local = 'http://127.0.0.1:8000'
$api = if ($Nube) { $nube } else { $local }
# La compilación recuerda a qué servidor apunta; si cambia, se recompila.
$marca = Join-Path $web 'servidor.txt'
New-Item -ItemType Directory -Force $logs | Out-Null

function Paso($t) { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Falla($t) { Write-Host "`nERROR: $t" -ForegroundColor Red; Read-Host 'Presiona Enter para cerrar'; exit 1 }

# 1. Apagar lo que haya quedado de antes (puertos 8000/8080 y worker)
Paso 'Liberando puertos 8000 y 8080'
& (Join-Path $raiz 'detener.ps1') -Silencioso

# 2. Entorno de Python (sirve la app y, en local, la API y el worker)
if (-not (Test-Path $py)) {
    Paso 'Creando entorno de Python (solo la primera vez)'
    if (-not (Get-Command py -ErrorAction SilentlyContinue)) { Falla 'No se encontró Python. Instálalo desde https://www.python.org (marca "Add to PATH").' }
    py -m venv (Join-Path $raiz 'venv')
    & $py -m pip install -q -r (Join-Path $raiz 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { Falla 'No se pudieron instalar las dependencias de Python.' }
}

if (-not $Nube) {
    # 3. Base de datos: crea o actualiza el esquema (columnas nuevas incluidas) y datos de ejemplo
    $nueva = -not (Test-Path (Join-Path $raiz 'utb_tracker.db'))
    Paso 'Preparando la base de datos local'
    & $py (Join-Path $raiz 'scripts\preparar_bd.py')
    if ($LASTEXITCODE -ne 0) { Falla 'No se pudo preparar la base de datos (mira el mensaje de arriba).' }
    if ($nueva -or $ReiniciarDatos) {
        Paso 'Cargando datos de ejemplo'
        & $py (Join-Path $raiz 'scripts\seed_demo.py')
        if ($LASTEXITCODE -ne 0) { Falla 'No se pudieron cargar los datos de ejemplo.' }
    }

    # 4. API y worker, cada uno en su ventana. Comparten la MISMA base (utb_tracker.db).
    Paso "Encendiendo la API en $local"
    Start-Process powershell -WorkingDirectory $raiz -ArgumentList '-NoExit', '-Command',
        "`$Host.UI.RawUI.WindowTitle='UTB Tracker - API (no cerrar)'; `$env:URL_PUBLICA='$local'; `$env:VERIFICACION_OBLIGATORIA='true'; & '$py' -m uvicorn app.main:app --host 127.0.0.1 --port 8000"
    Paso 'Encendiendo el worker de correos y notificaciones'
    Start-Process powershell -WorkingDirectory $raiz -ArgumentList '-NoExit', '-Command',
        "`$Host.UI.RawUI.WindowTitle='UTB Tracker - WORKER (no cerrar)'; `$env:URL_PUBLICA='$local'; & '$py' -m app.messaging"
}

# 5. Compilar la app web apuntando a la API elegida
$compiladaPara = if (Test-Path $marca) { (Get-Content $marca -Raw).Trim() } else { '' }
if (-not $SinCompilar -or -not (Test-Path (Join-Path $web 'index.html')) -or $compiladaPara -ne $api) {
    $flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
    if (-not $flutter -and (Test-Path 'C:\src\flutter\bin\flutter.bat')) { $flutter = 'C:\src\flutter\bin\flutter.bat' }
    if (-not $flutter) { Falla 'No se encontró Flutter (se esperaba en C:\src\flutter).' }
    Paso "Compilando la app contra $api (1-2 minutos)"
    Push-Location (Join-Path $raiz 'frontend')
    try {
        & $flutter pub get | Out-Null
        # PERMITIR_CAMBIAR_SERVIDOR: el login y el perfil dejan cambiar de servidor en esta compilación.
        & $flutter build web --no-wasm-dry-run --dart-define=API_BASE_URL=$api --dart-define=PERMITIR_CAMBIAR_SERVIDOR=true
        if ($LASTEXITCODE -ne 0) { Falla 'La app no compiló. Revisa el error de arriba.' }
        Set-Content -Path $marca -Value $api -Encoding ascii
    } finally { Pop-Location }
}

# 6. Servir la app compilada en su propia ventana
Paso 'Encendiendo la app en http://127.0.0.1:8080'
Start-Process powershell -WorkingDirectory $web -ArgumentList '-NoExit', '-Command',
    "`$Host.UI.RawUI.WindowTitle='UTB Tracker - APP (no cerrar)'; & '$py' -m http.server 8080 --bind 127.0.0.1"

# 7. Esperar a que la API y la app respondan y abrir el navegador
Paso 'Comprobando que todo responda'
$ok = $false
foreach ($i in 1..40) {
    try {
        $b = Invoke-WebRequest "$api/salud" -UseBasicParsing -TimeoutSec 5
        $a = Invoke-WebRequest 'http://127.0.0.1:8080' -UseBasicParsing -TimeoutSec 2
        if ($b.StatusCode -eq 200 -and $a.StatusCode -eq 200) { $ok = $true; break }
    } catch { Start-Sleep 1 }
}
if (-not $ok) { Falla "La API ($api) o la app no respondieron. Revisa las ventanas 'UTB Tracker' o tu internet." }

Write-Host "`nLISTO. Abriendo http://127.0.0.1:8080  (servidor: $api)" -ForegroundColor Green
if ($Nube) {
    Write-Host 'Usas el servidor OFICIAL: las mismas cuentas que en el celular.'
} else {
    Write-Host 'Usas el servidor LOCAL de este PC (cuentas de prueba, no las del celular).'
    Write-Host 'Cuentas de prueba (una por rol): mira la lista que imprime scripts\seed_demo.py'
    Write-Host '  o la tabla USUARIOS al inicio de ese archivo. Ver docs\COMO_EJECUTAR.md, sección 4.'
    Write-Host "Los correos (verificación, recuperación) se guardan en $logs\correos"
}
Write-Host 'Para apagar todo: .\detener.ps1'
Start-Process 'http://127.0.0.1:8080'
