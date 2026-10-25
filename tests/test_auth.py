"""
Pruebas automatizadas del módulo de autenticación (S9 — req. 9.3).

Cubre:
- Registro de nuevos usuarios con hash bcrypt seguro (req. 9.8 / QS-04).
- Rechazo de duplicados (409 Conflict).
- Inicio de sesión exitoso y generación de token JWT firmado.
- Rechazo de contraseñas incorrectas o usuarios inexistentes (401 Unauthorized).
- Consulta y eliminación de usuarios.
- Endpoint GET /auth/me para el usuario autenticado.
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
            "email": "admin_login@utb.edu.co",
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
    # El login ahora retorna datos del usuario
    assert "user" in data
    assert data["user"]["nombre"] == "Admin Campus"


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


def test_obtener_usuario_por_id(client, auth_headers):
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

    response = client.get(f"/auth/user/{user_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["nombre"] == "Consulta ID"


def test_obtener_usuario_inexistente_404(client, auth_headers):
    response = client.get("/auth/user/999999", headers=auth_headers)
    assert response.status_code == 404


def test_eliminar_usuario(client, admin_headers):
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

    res_del = client.delete(f"/auth/delete/{user_id}", headers=admin_headers)
    assert res_del.status_code == 200


def test_endpoint_me(client, auth_headers):
    """GET /auth/me debe retornar los datos del usuario autenticado."""
    response = client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["nombre"] == "Usuario de prueba 1"
    assert data["email"] == "user1@utb.edu.co"
    assert data["rol"] == "usuario_utb"


def test_endpoint_me_sin_token(client):
    """GET /auth/me sin token debe retornar 401."""
    response = client.get("/auth/me")
    assert response.status_code == 401


def test_endpoint_protegido_sin_token(client):
    """Endpoints protegidos deben rechazar peticiones sin token."""
    response = client.get("/auth/user/1")
    assert response.status_code == 401


def test_eliminar_usuario_sin_rol_admin(client, auth_headers):
    """Solo admin/auxiliar puede eliminar usuarios."""
    response = client.delete("/auth/delete/1", headers=auth_headers)
    assert response.status_code == 403


def test_registro_fuerza_rol_usuario_utb(client):
    """El registro público no permite auto-asignar rol administrador."""
    response = client.post(
        "/auth/register",
        json={
            "nombre": "Hacker Intent",
            "email": "hacker@utb.edu.co",
            "rol": "administrador",
            "password": "PasswordSegura123!",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["rol"] == "usuario_utb"


def test_admin_listar_usuarios(client, admin_headers, auth_headers):
    """Solo admin puede consultar la lista completa de usuarios."""
    # Usuario común no tiene permiso
    res_comun = client.get("/auth/users", headers=auth_headers)
    assert res_comun.status_code == 403

    # Admin consulta lista exitosamente
    res_admin = client.get("/auth/users", headers=admin_headers)
    assert res_admin.status_code == 200
    usuarios = res_admin.json()
    assert len(usuarios) >= 2


def test_admin_actualizar_rol_usuario(client, admin_headers, auth_headers):
    """Solo admin puede actualizar roles desde el panel administrativo."""
    # Crear usuario base
    reg = client.post(
        "/auth/register",
        json={
            "nombre": "Para Promover",
            "email": "promover@utb.edu.co",
            "rol": "usuario_utb",
            "password": "Password123!",
        },
    )
    user_id = reg.json()["id"]

    # Usuario normal no puede cambiar rol
    res_no_auth = client.patch(
        f"/auth/user/{user_id}/role",
        json={"rol": "auxiliar"},
        headers=auth_headers,
    )
    assert res_no_auth.status_code == 403

    # Admin actualiza rol a auxiliar
    res_admin = client.patch(
        f"/auth/user/{user_id}/role",
        json={"rol": "auxiliar"},
        headers=admin_headers,
    )
    assert res_admin.status_code == 200
    assert res_admin.json()["rol"] == "auxiliar"

    # Verificar rol inválido
    res_invalido = client.patch(
        f"/auth/user/{user_id}/role",
        json={"rol": "super_hacker"},
        headers=admin_headers,
    )
    assert res_invalido.status_code == 400

