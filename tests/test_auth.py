"""
Pruebas automatizadas del módulo de autenticación (S9 — req. 9.3).

Cubre:
- Registro de nuevos usuarios con hash bcrypt seguro (req. 9.8 / QS-04).
- Rechazo de duplicados (409 Conflict).
- Inicio de sesión exitoso y generación de token JWT firmado.
- Rechazo de contraseñas incorrectas o usuarios inexistentes (401 Unauthorized).
- Consulta y eliminación de usuarios.
"""


def test_registro_usuario_exitoso(client):
    response = client.post(
        "/auth/register",
        json={
            "nombre": "Estudiante Prueba",
            "email": "estudiante@utb.edu.co",
            "rol": "usuario_utb",
            "password": "PasswordSegura123!",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["nombre"] == "Estudiante Prueba"
    assert data["email"] == "estudiante@utb.edu.co"
    assert data["rol"] == "usuario_utb"
    assert "id" in data
    # La contraseña nunca debe ser devuelta en la respuesta
    assert "password" not in data


def test_registro_usuario_duplicado_rechazado(client):
    payload = {
        "nombre": "Docente Duplicado",
        "email": "docente@utb.edu.co",
        "rol": "usuario_utb",
        "password": "Password123!",
    }
    r1 = client.post("/auth/register", json=payload)
    assert r1.status_code == 201

    r2 = client.post("/auth/register", json=payload)
    assert r2.status_code == 409
    assert "Ya existe un usuario" in r2.json()["detail"]


def test_login_exitoso_genera_jwt(client):
    # Primero se registra el usuario
    client.post(
        "/auth/register",
        json={
            "nombre": "Admin Campus",
            "email": "admin@utb.edu.co",
            "rol": "administrador",
            "password": "AdminSecret2026*",
        },
    )

    # Iniciar sesión
    response = client.post(
        "/auth/login",
        json={
            "nombre": "Admin Campus",
            "password": "AdminSecret2026*",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert len(data["access_token"]) > 20


def test_login_password_incorrecto_rechazado(client):
    client.post(
        "/auth/register",
        json={
            "nombre": "Usuario Clave",
            "email": "clave@utb.edu.co",
            "rol": "usuario_utb",
            "password": "ClaveCorrecta99",
        },
    )

    response = client.post(
        "/auth/login",
        json={
            "nombre": "Usuario Clave",
            "password": "ClaveINCORRECTA",
        },
    )
    assert response.status_code == 401
    assert "incorrectos" in response.json()["detail"]


def test_login_usuario_inexistente_rechazado(client):
    response = client.post(
        "/auth/login",
        json={
            "nombre": "NoExisteEnBD",
            "password": "CualquierPassword",
        },
    )
    assert response.status_code == 401


def test_obtener_usuario_por_id(client):
    res_reg = client.post(
        "/auth/register",
        json={
            "nombre": "Consulta ID",
            "email": "consulta@utb.edu.co",
            "rol": "usuario_utb",
            "password": "Password123",
        },
    )
    user_id = res_reg.json()["id"]

    response = client.get(f"/auth/user/{user_id}")
    assert response.status_code == 200
    assert response.json()["nombre"] == "Consulta ID"


def test_obtener_usuario_inexistente_404(client):
    response = client.get("/auth/user/999999")
    assert response.status_code == 404


def test_eliminar_usuario(client):
    res_reg = client.post(
        "/auth/register",
        json={
            "nombre": "Borrar Usuario",
            "email": "borrar@utb.edu.co",
            "rol": "usuario_utb",
            "password": "Password123",
        },
    )
    user_id = res_reg.json()["id"]

    res_del = client.delete(f"/auth/delete/{user_id}")
    assert res_del.status_code == 200

    # Verificar que ya no existe
    res_get = client.get(f"/auth/user/{user_id}")
    assert res_get.status_code == 404
