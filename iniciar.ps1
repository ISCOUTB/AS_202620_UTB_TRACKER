# Arranca UTB Tracker completo en Windows: backend (FastAPI) + app web (Flutter).
#
#   .\iniciar.ps1                     # uso normal, desde la raíz del repo
#   .\iniciar.ps1 -ReiniciarDatos     # además recarga los datos de ejemplo (clases con la hora actual)
#   .\iniciar.ps1 -SinCompilar        # no recompila la app (más rápido si no cambiaste el frontend)
#
# Abre dos ventanas (backend y app). Para apagar todo: .\detener.ps1
param(
    [switch]$ReiniciarDatos,
    [switch]$SinCompilar
)
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$py = Join-Path $raiz 'venv\Scripts\python.exe'
$web = Join-Path $raiz 'frontend\build\web'

function Paso($t) { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Falla($t) { Write-Host "`nERROR: $t" -ForegroundColor Red; Read-Host 'Presiona Enter para cerrar'; exit 1 }

# 1. Liberar puertos 8000 (backend) y 8080 (app)
Paso 'Liberando puertos 8000 y 8080'
& (Join-Path $raiz 'detener.ps1') -Silencioso

# 2. Entorno de Python
if (-not (Test-Path $py)) {
    Paso 'Creando entorno de Python (solo la primera vez)'
    if (-not (Get-Command py -ErrorAction SilentlyContinue)) { Falla 'No se encontró Python. Instálalo desde https://www.python.org (marca "Add to PATH").' }
    py -m venv (Join-Path $raiz 'venv')
    & $py -m pip install -q -r (Join-Path $raiz 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { Falla 'No se pudieron instalar las dependencias de Python.' }
}

# 3. Base de datos y datos de ejemplo
if ($ReiniciarDatos -or -not (Test-Path (Join-Path $raiz 'utb_tracker.db'))) {
    Paso 'Cargando datos de ejemplo'
    & $py (Join-Path $raiz 'scripts\seed_demo.py')
    if ($LASTEXITCODE -ne 0) { Falla 'No se pudieron cargar los datos de ejemplo.' }
}

# 4. Backend en su propia ventana
Paso 'Encendiendo backend en http://127.0.0.1:8000'
Start-Process powershell -WorkingDirectory $raiz -ArgumentList '-NoExit', '-Command',
    "`$Host.UI.RawUI.WindowTitle='UTB Tracker - BACKEND (no cerrar)'; & '$py' -m uvicorn app.main:app --host 127.0.0.1 --port 8000"

# 5. Compilar la app web
if (-not $SinCompilar -or -not (Test-Path (Join-Path $web 'index.html'))) {
    $flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
    if (-not $flutter -and (Test-Path 'C:\src\flutter\bin\flutter.bat')) { $flutter = 'C:\src\flutter\bin\flutter.bat' }
    if (-not $flutter) { Falla 'No se encontró Flutter (se esperaba en C:\src\flutter).' }
    Paso 'Compilando la app (1-2 minutos)'
    Push-Location (Join-Path $raiz 'frontend')
    try {
        & $flutter pub get | Out-Null
        & $flutter build web --no-wasm-dry-run --dart-define=API_BASE_URL=http://127.0.0.1:8000
        if ($LASTEXITCODE -ne 0) { Falla 'La app no compiló. Revisa el error de arriba.' }
    } finally { Pop-Location }
}

# 6. Servir la app compilada en su propia ventana
Paso 'Encendiendo la app en http://127.0.0.1:8080'
Start-Process powershell -WorkingDirectory $web -ArgumentList '-NoExit', '-Command',
    "`$Host.UI.RawUI.WindowTitle='UTB Tracker - APP (no cerrar)'; & '$py' -m http.server 8080 --bind 127.0.0.1"

# 7. Esperar a que ambos respondan y abrir el navegador
Paso 'Comprobando que todo responda'
$ok = $false
foreach ($i in 1..30) {
    try {
        $b = Invoke-WebRequest 'http://127.0.0.1:8000/salud' -UseBasicParsing -TimeoutSec 2
        $a = Invoke-WebRequest 'http://127.0.0.1:8080' -UseBasicParsing -TimeoutSec 2
        if ($b.StatusCode -eq 200 -and $a.StatusCode -eq 200) { $ok = $true; break }
    } catch { Start-Sleep 1 }
}
if (-not $ok) { Falla 'El backend o la app no respondieron. Mira las ventanas "UTB Tracker - BACKEND/APP" para ver el error.' }

Write-Host "`nLISTO. Abriendo http://127.0.0.1:8080" -ForegroundColor Green
Write-Host 'Entra con  Nombre: Auxiliar Demo   Clave: Auxiliar123!'
Write-Host 'Para apagar todo: .\detener.ps1'
Start-Process 'http://127.0.0.1:8080'
