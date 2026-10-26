"""
Pruebas de la administración de salones: ocupación en vivo, presencia del
profesor y reportes. Usan el parámetro `momento` para fijar la hora local del
campus y no depender del reloj (lunes 26-oct-2026).
"""
LUNES_10_30 = "2026-10-26T10:30:00"
LUNES_13_00 = "2026-10-26T13:00:00"
DOMINGO_10_30 = "2026-10-25T10:30:00"


def _salon_con_clase(client, admin_headers, nombre="A-301"):
    salon = client.post("/salones", json={
        "nombre": nombre, "ubicacion": "Edificio A, Piso 3", "capacidad": 40,
    }, headers=admin_headers).json()
    r = client.post("/horarios", json={
        "salon_id": salon["id"], "dia_semana": 1,
        "hora_inicio": "10:00:00", "hora_fin": "12:00:00",
        "profesor": "Ana Pérez", "materia": "Cálculo II",
    }, headers=admin_headers)
    assert r.status_code == 201, r.text
    return salon["id"]


def test_ocupacion_requiere_rol_administrador(client, auth_headers):
    assert client.get("/salones/ocupacion", headers=auth_headers).status_code == 403


def test_salon_con_clase_en_curso_muestra_profesor_sin_confirmar(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_10_30},
                   headers=admin_headers)

    assert r.status_code == 200
    data = r.json()
    assert data["ocupante"] == "clase"
    assert data["clase_actual"]["profesor"] == "Ana Pérez"
    assert data["profesor_presente"] is None


def test_salon_sin_clase_ni_prestamo_esta_libre(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_13_00},
                   headers=admin_headers)

    assert r.json()["ocupante"] == "libre"
    assert r.json()["clase_actual"] is None


def test_listar_ocupacion_incluye_todos_los_salones(client, admin_headers):
    _salon_con_clase(client, admin_headers, "A-301")
    _salon_con_clase(client, admin_headers, "A-302")

    r = client.get("/salones/ocupacion", params={"momento": LUNES_10_30}, headers=admin_headers)

    assert r.status_code == 200
    assert [o["salon"]["nombre"] for o in r.json()] == ["A-301", "A-302"]


def test_confirmar_presencia_se_refleja_en_la_ocupacion(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.put(f"/salones/{salon_id}/presencia", params={"momento": LUNES_10_30},
                   json={"profesor_presente": True}, headers=admin_headers)
    assert r.status_code == 200
    assert r.json()["profesor_presente"] is True

    ocupacion = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_10_30},
                           headers=admin_headers).json()
    assert ocupacion["profesor_presente"] is True


def test_presencia_se_puede_corregir_sin_duplicar(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    url = f"/salones/{salon_id}/presencia"

    client.put(url, params={"momento": LUNES_10_30}, json={"profesor_presente": True},
               headers=admin_headers)
    r = client.put(url, params={"momento": LUNES_10_30},
                   json={"profesor_presente": False, "nota": "Avisó que no llega"},
                   headers=admin_headers)

    assert r.status_code == 200
    assert r.json()["profesor_presente"] is False
    ocupacion = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_10_30},
                           headers=admin_headers).json()
    assert ocupacion["profesor_presente"] is False


def test_presencia_sin_clase_en_curso_da_409(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.put(f"/salones/{salon_id}/presencia", params={"momento": DOMINGO_10_30},
                   json={"profesor_presente": True}, headers=admin_headers)

    assert r.status_code == 409


def test_presencia_requiere_rol_administrador(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.put(f"/salones/{salon_id}/presencia", params={"momento": LUNES_10_30},
                   json={"profesor_presente": True}, headers=auth_headers)

    assert r.status_code == 403


def test_prestamo_aprobado_muestra_quien_tiene_el_salon(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    # 14:00–16:00 hora Colombia = 19:00–21:00 UTC (así lo guarda el backend)
    solicitud = client.post("/prestamos-salon", json={
        "salon_id": salon_id,
        "fecha_inicio": "2026-10-26T19:00:00",
        "fecha_fin": "2026-10-26T21:00:00",
        "motivo": "Estudio en grupo",
    }, headers=auth_headers)
    assert solicitud.status_code == 201, solicitud.text
    client.patch(f"/prestamos-salon/{solicitud.json()['id']}",
                 json={"estado": "aprobado"}, headers=admin_headers)

    r = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": "2026-10-26T14:30:00"},
                   headers=admin_headers)

    data = r.json()
    assert data["ocupante"] == "prestamo"
    assert data["prestamo_actual"]["usuario_nombre"] == "Usuario de prueba 1"
    assert data["prestamo_actual"]["estado"] == "aprobado"


def test_solicitudes_pendientes_se_cuentan(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    client.post("/prestamos-salon", json={
        "salon_id": salon_id,
        "fecha_inicio": "2026-10-26T19:00:00",
        "fecha_fin": "2026-10-26T21:00:00",
    }, headers=auth_headers)

    r = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_13_00},
                   headers=admin_headers)

    assert r.json()["solicitudes_pendientes"] == 1


def test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(
    client, admin_headers, auth_headers
):
    salon_id = _salon_con_clase(client, admin_headers)

    creado = client.post(f"/salones/{salon_id}/reportes", json={
        "tipo": "equipo", "descripcion": "El video beam no enciende",
    }, headers=auth_headers)
    assert creado.status_code == 201
    reporte_id = creado.json()["id"]
    assert creado.json()["estado"] == "abierto"

    intento = client.patch(f"/salones/{salon_id}/reportes/{reporte_id}",
                           json={"estado": "resuelto"}, headers=auth_headers)
    assert intento.status_code == 403

    resuelto = client.patch(f"/salones/{salon_id}/reportes/{reporte_id}",
                            json={"estado": "resuelto"}, headers=admin_headers)
    assert resuelto.status_code == 200
    assert resuelto.json()["resuelto_en"] is not None


def test_reportes_abiertos_se_cuentan_y_se_filtran(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    for desc in ("Piso sucio", "Tablero roto"):
        client.post(f"/salones/{salon_id}/reportes",
                    json={"tipo": "limpieza", "descripcion": desc}, headers=auth_headers)
    primero = client.get(f"/salones/{salon_id}/reportes", headers=auth_headers).json()[0]
    client.patch(f"/salones/{salon_id}/reportes/{primero['id']}",
                 json={"estado": "resuelto"}, headers=admin_headers)

    abiertos = client.get(f"/salones/{salon_id}/reportes", params={"estado": "abierto"},
                          headers=auth_headers).json()
    ocupacion = client.get(f"/salones/{salon_id}/ocupacion", params={"momento": LUNES_13_00},
                           headers=admin_headers).json()

    assert len(abiertos) == 1
    assert ocupacion["reportes_abiertos"] == 1


def test_reporte_con_tipo_invalido_da_422(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    r = client.post(f"/salones/{salon_id}/reportes",
                    json={"tipo": "inventado", "descripcion": "algo"}, headers=auth_headers)

    assert r.status_code == 422


def test_reporte_de_salon_inexistente_da_404(client, auth_headers):
    r = client.post("/salones/9999/reportes",
                    json={"tipo": "otro", "descripcion": "algo"}, headers=auth_headers)

    assert r.status_code == 404
