"""
Script de medición empírica para el escenario de calidad QS-03 (UTB Tracker).
Prueba de concurrencia y latencia sobre la API real desplegada en Uvicorn.

Escenario QS-03 (arc42 sección 10):
- Estímulo: Múltiples usuarios usan el sistema al mismo tiempo (hora pico).
- Medida: Soporta al menos 300 usuarios simultáneos sin errores ni caídas.
- Umbral: 0 caídas/errores, tiempo de respuesta controlado.

Uso:
    python scripts/medir_qs03.py [--base-url http://127.0.0.1:8000] [--concurrencias 50,150,300] [--timeout 5.0]
"""
import argparse
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request
import urllib.error
import json


TIMEOUT_DEFAULT = 5.0  # Timeout por petición en segundos


def obtener_token(base_url: str, timeout: float) -> str:
    """Autentica contra POST /auth/login para obtener un token JWT válido."""
    login_url = f"{base_url}/auth/login"
    payload = json.dumps({
        "nombre": "Estudiante Medicion",
        "password": "Medicion2026!",
    }).encode("utf-8")

    req = urllib.request.Request(
        login_url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data["access_token"]
    except Exception as exc:
        print(f"ERROR: No se pudo autenticar en {login_url}: {exc}", file=sys.stderr)
        sys.exit(1)


def ejecutar_peticion(url: str, headers: dict, timeout: float) -> tuple[int, float, str]:
    """
    Ejecuta una petición HTTP individual midiendo el tiempo con time.perf_counter.
    Retorna: (status_code, duracion_ms, error_msg)
    """
    req = urllib.request.Request(url, headers=headers, method="GET")
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            t1 = time.perf_counter()
            return resp.status, (t1 - t0) * 1000.0, ""
    except urllib.error.HTTPError as he:
        t1 = time.perf_counter()
        return he.code, (t1 - t0) * 1000.0, f"HTTPError {he.code}"
    except Exception as e:
        t1 = time.perf_counter()
        return 0, (t1 - t0) * 1000.0, f"Exception: {type(e).__name__} ({e})"


def percentil(valores: list[float], p: float) -> float:
    """Calcula el percentil p (0.0 a 1.0) sobre una lista ordenada."""
    if not valores:
        return 0.0
    idx = int(len(valores) * p)
    if idx >= len(valores):
        idx = len(valores) - 1
    return valores[idx]


def ejecutar_corrida(base_url: str, headers: dict, concurrencia: int, timeout: float) -> dict:
    """
    Lanza una ráfaga de peticiones concurrentes distribuidas equitativamente
    entre los 3 endpoints de lectura de hora pico:
    - GET /recursos (catálogo)
    - GET /salones (listado de salones)
    - GET /salones/1/disponibilidad?dia_semana=1 (matriz de disponibilidad)
    """
    endpoints = [
        f"{base_url}/recursos",
        f"{base_url}/salones",
        f"{base_url}/salones/1/disponibilidad?dia_semana=1",
    ]

    urls_a_probar = [endpoints[i % len(endpoints)] for i in range(concurrencia)]

    latencias = []
    errores = 0
    codigos_status = {}
    detalle_errores = []

    t_inicio = time.perf_counter()
    with ThreadPoolExecutor(max_workers=concurrencia) as executor:
        futuros = [
            executor.submit(ejecutar_peticion, url, headers, timeout)
            for url in urls_a_probar
        ]
        for f in as_completed(futuros):
            status, dur_ms, err = f.result()
            codigos_status[status] = codigos_status.get(status, 0) + 1
            latencias.append(dur_ms)
            if status != 200:
                errores += 1
                if err:
                    detalle_errores.append(err)
    t_fin = time.perf_counter()

    latencias.sort()
    duracion_total_s = t_fin - t_inicio
    throughput = len(latencias) / duracion_total_s if duracion_total_s > 0 else 0

    return {
        "concurrencia": concurrencia,
        "total_peticiones": len(latencias),
        "exitosas_200": codigos_status.get(200, 0),
        "errores": errores,
        "codigos_status": codigos_status,
        "duracion_total_s": duracion_total_s,
        "throughput_req_s": throughput,
        "p50_ms": percentil(latencias, 0.50),
        "p95_ms": percentil(latencias, 0.95),
        "p99_ms": percentil(latencias, 0.99),
        "max_ms": max(latencias) if latencias else 0.0,
        "min_ms": min(latencias) if latencias else 0.0,
        "promedio_ms": sum(latencias) / len(latencias) if latencias else 0.0,
        "detalle_errores": detalle_errores[:5],
    }


def main():
    parser = argparse.ArgumentParser(description="Medición QS-03 UTB Tracker")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="URL base de la API FastAPI")
    parser.add_argument("--concurrencias", default="50,150,300", help="Niveles de concurrencia separados por coma")
    parser.add_argument("--timeout", type=float, default=TIMEOUT_DEFAULT, help="Timeout por petición en segundos")
    args = parser.parse_args()

    niveles = [int(x.strip()) for x in args.concurrencias.split(",") if x.strip()]
    print("=" * 80)
    print(f"MEDICIÓN EMPÍRICA QS-03 — UTB Tracker")
    print(f"URL Base: {args.base_url}")
    print(f"Niveles de concurrencia: {niveles}")
    print(f"Timeout por petición: {args.timeout} s")
    print("=" * 80)

    print("Obteniendo token de autenticación JWT...")
    token = obtener_token(args.base_url, args.timeout)
    headers = {
        "Authorization": f"Bearer {token}",
        "User-Agent": "UTB-Tracker-LoadTest/1.0",
    }
    print("Token obtenido con éxito. Iniciando corridas de medición...\n")

    resultados_totales = []

    for conc in niveles:
        for intento in [1, 2]:
            print(f"--> Ejecutando corrida: {conc} usuarios concurrentes (Intento {intento}/2)...")
            res = ejecutar_corrida(args.base_url, headers, conc, args.timeout)
            res["intento"] = intento
            resultados_totales.append(res)
            print(
                f"    Completado en {res['duracion_total_s']:.2f}s | "
                f"Éxitos: {res['exitosas_200']}/{res['total_peticiones']} | "
                f"Errores: {res['errores']} | "
                f"p50: {res['p50_ms']:.2f}ms | p95: {res['p95_ms']:.2f}ms | p99: {res['p99_ms']:.2f}ms | max: {res['max_ms']:.2f}ms"
            )
            time.sleep(1.0)  # Breve pausa entre ráfagas

    print("\n" + "=" * 80)
    print("RESUMEN TABULAR DE RESULTADOS (SALIDA CRUDA)")
    print("=" * 80)
    print(f"{'Usuarios':<10} {'Intento':<9} {'Total':<8} {'Éxitos':<8} {'Errores':<8} {'p50 (ms)':<10} {'p95 (ms)':<10} {'p99 (ms)':<10} {'Max (ms)':<10} {'Req/s':<8}")
    print("-" * 92)
    for r in resultados_totales:
        print(
            f"{r['concurrencia']:<10} {r['intento']:<9} {r['total_peticiones']:<8} "
            f"{r['exitosas_200']:<8} {r['errores']:<8} {r['p50_ms']:<10.2f} "
            f"{r['p95_ms']:<10.2f} {r['p99_ms']:<10.2f} {r['max_ms']:<10.2f} {r['throughput_req_s']:<8.1f}"
        )
    print("=" * 80)


if __name__ == "__main__":
    main()

