# Política y Modelo de Privacidad de Datos — UTB Tracker

> **Documento verificado contra los modelos y esquemas del repositorio.**  
> Cada afirmación técnica incluye su ubicación exacta (`archivo:línea`).  
> Las mejoras no implementadas se señalan explícitamente como **PROPUESTO — NO IMPLEMENTADO**.

---

## 1. Marco Legal y Principios de Tratamiento

El tratamiento de datos en el sistema UTB Tracker se rige bajo la legislación colombiana de protección de datos personales:
- **Ley Estatutaria 1581 de 2012:** Régimen General de Protección de Datos Personales en Colombia.
- **Decreto Reglamentario 1377 de 2013:** Reglamentación parcial en materia de recolección, autorización y políticas de tratamiento.
- **Derecho Fundamental de Hábeas Data (Artículo 15 de la Constitución Política de Colombia):** Garantiza a los titulares el derecho a conocer, actualizar y rectificar las informaciones que se hayan recogido sobre ellas en bancos de datos y archivos institucionales.

### Bases de Tratamiento Aplicables
1. **Autorización previa y explícita del titular:** Otorgada por el estudiante, profesor o funcionario al momento de registrarse voluntariamente en la plataforma (`app/routers/auth.py:29-34`, `app/services/auth.py:19-62`).
2. **Vínculo institucional y ejecución de relación académica:** Necesidad legítima de la Universidad Tecnológica de Bolívar (UTB) para la custodia, asignación y control patrimonial de sus recursos físicos, laboratorios y aulas de clase.

---

## 2. Inventario Exhaustivo de Datos Personales en el Modelo de Datos

A continuación se detalla cada dato personal que el sistema captura, su tabla y columna física en el esquema relacional (`app/models/`), su finalidad operativa, la base de tratamiento, los roles con acceso y el plazo de retención.

| Dato Personal | Tabla y Columna (`archivo:línea`) | Tipo de Dato | Finalidad Específica | Base de Tratamiento | Quién Accede | Plazo de Retención |
|---|---|---|---|---|---|---|
| **Nombre completo** | `usuarios.nombre`<br>(`app/models/auth_models.py:19`) | `String` | Identificación del usuario en la interfaz y credencial de inicio de sesión (`app/services/auth.py:70`). | Autorización explícita al registrarse. | El propio usuario, administradores y auxiliares de laboratorio. | Mientras la cuenta permanezca activa en la universidad. |
| **Correo institucional** | `usuarios.email`<br>(`app/models/auth_models.py:20`) | `String (UNIQUE)` | Identificador unívoco, emisión del token JWT (`sub: user.email` en `app/core/security.py:10`), y canal para notificaciones de préstamos. | Vínculo institucional UTB y autorización. | El propio usuario, administradores y proceso automatizado del worker. | Mientras la cuenta esté activa; purga tras desvinculación académica. |
| **Hash de contraseña** | `usuarios.password`<br>(`app/models/auth_models.py:24`) | `String (bcrypt)` | Autenticación criptográfica segura (almacenado con sal dinámica, no reversible). | Consentimiento y necesidad técnica de seguridad. | Ningún usuario; solo el servicio de autenticación (`app/services/auth.py:71`). | Hasta el cambio o eliminación de la cuenta. |
| **Rol institucional** | `usuarios.rol`<br>(`app/models/auth_models.py:22`) | `String` | Control de acceso basado en roles (`usuario_utb`, `administrador`, `auxiliar`). | Vínculo contractual o matrícula académica en la UTB. | Sistema de autorización (`app/core/deps.py:60-74`) y el propio usuario. | Vigencia de la cuenta. |
| **Fecha de registro** | `usuarios.fecha_registro`<br>(`app/models/auth_models.py:21`) | `DateTime` | Auditoría de creación de la cuenta de usuario. | Interés legítimo institucional. | Administradores y auxiliares. | Indefinido (historial de auditoría). |
| **Estado de la cuenta** | `usuarios.activo`<br>(`app/models/auth_models.py:25`) | `Boolean` | Trazabilidad del ciclo de vida (soporte para desactivación por soft-delete). | Interés legítimo y control de seguridad. | Administradores y auxiliares. | Permanente en BD como registro inactivo. |
| **Historial de Préstamos de Equipos** | `prestamos.usuario_id`<br>(`app/models/recurso_models.py:49`) | `Integer (FK)` | Relaciona qué persona física tomó en custodia un equipo electrónico, con fechas esperadas y reales de devolución. | Vínculo institucional y control patrimonial. | El usuario solicitante (`app/routers/loans.py:57-60`), administradores y auxiliares. | Vigencia del semestre académico (actualmente sin política de purga automática). |
| **Historial de Préstamos de Salones** | `prestamos_salon.usuario_id`<br>(`app/models/salon_models.py:73`) | `Integer (FK)` | Identifica al docente o estudiante responsable de la reserva de un aula física de la universidad. | Control operativo de infraestructura. | El solicitante (`app/routers/prestamos_salon.py:52-55`), administradores y auxiliares. | Semestre académico activo. |
| **Motivo de Reserva de Aula** | `prestamos_salon.motivo`<br>(`app/models/salon_models.py:76`) | `String` | Justificación académica o extracurricular de la solicitud de espacio físico. | Autorización del titular en el formulario. | Administradores y auxiliares para evaluación de la solicitud. | Semestre académico activo. |
| **Reportes de Daños en Equipos** | `reportes.usuario_id`, `descripcion`<br>(`app/models/recurso_models.py:84,86`) | `Integer (FK)`, `Text` | Trazabilidad de incidentes reportados por usuarios sobre el estado de los dispositivos. | Interés legítimo institucional y custodia de activos. | Administradores y auxiliares de mantenimiento. | Historial de vida útil del equipo físico reportado. |
| **Control de Asistencia Docente (Salones)** | `presencias_salon.profesor_presente`, `registrado_por`<br>(`app/models/salon_models.py:99,102`) | `Boolean`, `Integer (FK)` | Registro de cumplimiento y presencia del docente en la franja de clase por parte del auxiliar. | Vínculo laboral/contractual docente y supervisión académica. | Administradores, auxiliares de laboratorio y coordinadores. | Semestre académico activo. |
| **Novedades y Reportes de Aula** | `reportes_salon.usuario_id`, `descripcion`<br>(`app/models/salon_models.py:116,119`) | `Integer (FK)`, `String` | Reporte ciudadano de novedades en aulas (limpieza, aire acondicionado, mobiliario). | Interés legítimo institucional y gestión de instalaciones. | El usuario reportante, auxiliares y personal de mantenimiento. | Hasta el cierre y resolución del reporte (`resuelto_en`). |
| **Nombre de Docente en Horarios** | `horarios.profesor`<br>(`app/models/salon_models.py:59`) | `String (Nullable)` | Publicación de la franja horaria ocupada por una cátedra académica específica. | Programación académica institucional de la UTB. | Todos los usuarios autenticados que consulten la disponibilidad del salón. | Semestre lectivo correspondiente (`horarios.semestre`). |
| **Carga Útil de Eventos Asíncronos** | `mensajes_outbox.payload`<br>(`app/messaging/models.py:44`) | `Text (JSON)` | Contiene `usuario_id`, `prestamo_id`, `recurso_id` y fecha esperada para coordinar el envío de correos. | Notificación de servicio pactada con el usuario. | Worker de mensajería (`app/messaging/worker.py:220-240`). | Hasta la confirmación de entrega (pasa a estado `"enviado"`). |
| **Registros de Eventos en Logs** | Salida estándar Uvicorn / Worker (`app/main.py:62-73`, `worker.py:91-97`) | `Texto plano` | Correlación diagnóstica (`request_id`, `correlation_id`, y en `worker.py:91` el correo electrónico del usuario). | Monitoreo técnico y seguridad operacional. | Administradores de infraestructura y DevOps. | Rotación típica de 30 días en agregadores de logs. |

---

## 3. Análisis de Minimización de Datos y Brechas Detectadas

El principio de minimización (artículo 4 de la Ley 1581 de 2012) exige que los datos tratados sean estrictamente los necesarios para cumplir la finalidad del servicio. La inspección del código reveló varias brechas:

### 3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios
- **Evidencia en código:** `app/schemas/auth.py:33-41` y `app/routers/auth.py:53-59`.
- **Condición:** El esquema `UserResponse` expone públicamente:
  ```python
  class UserResponse(BaseModel):
      id: int
      nombre: str
      email: str
      fecha_registro: datetime
      rol: str
  ```
  Al consultarse `GET /auth/user/{user_id}`, cualquier usuario autenticado obtiene el correo institucional, la fecha de registro y el rol del usuario consultado.
- **Mejora de minimización (PROPUESTO — NO IMPLEMENTADO):**
  - Restringir `GET /auth/user/{user_id}` para que solo pueda ser invocado por el propio titular o por administradores/auxiliares.
  - Para referencias públicas en la app móvil (por ejemplo, ver quién tiene prestado un equipo o reservado un salón), crear un esquema recortado `UserPublicResponse` que contenga únicamente el nombre de pila o una versión ofuscada del nombre, omitiendo el correo institucional y la fecha de registro.

### 3.2 Correo en Logs del Notificador Simulado
- **Evidencia en código:** `app/messaging/worker.py:91-97`:
  ```python
  logger.info(
      "[NotificadorSimulado] Notificación enviada — "
      "email=%s asunto=%r envio_num=%d",
      email,
      asunto,
      self._envios,
  )
  ```
- **Condición:** Se imprime el correo electrónico completo del usuario en las bitácoras del servidor. Si los logs son exportados a servicios en la nube o compartidos con desarrolladores para depuración, se produce una fuga involuntaria de datos personales.
- **Mejora de minimización (PROPUESTO — NO IMPLEMENTADO):**
  - Anonimizar la salida del log enmascarando los caracteres intermedios del buzón:
    ```python
    def _enmascarar_email(email: str) -> str:
        partes = email.split("@")
        if len(partes) != 2:
            return "***"
        usuario, dominio = partes
        visible = usuario[:2] if len(usuario) >= 2 else usuario[:1]
        return f"{visible}***@{dominio}"
    ```

### 3.3 Datos en Carga Útil del Outbox
- **Evidencia en código:** `app/messaging/events.py:11-12, 21-29` y `app/services/loans.py:99-108`.
- **Análisis:** En este punto el sistema aplica una **buena práctica de minimización ya implementada**: el payload del outbox no incluye el correo electrónico en claro ni el nombre del estudiante, sino únicamente el identificador numérico `usuario_id`. El worker resuelve el correo directamente desde la base de datos en el instante del envío (`app/messaging/worker.py:232`), evitando replicar datos de contacto innecesarios en la cola de mensajes.

### 3.4 Campo `profesor` en Horarios Académicos
- **Evidencia en código:** `app/models/salon_models.py:59` (`profesor = Column(String, nullable=True)`).
- **Condición:** El nombre del docente se registra como texto libre sin normalización ni referencia a una tabla de docentes autorizados. Esto genera potenciales discrepancias y exposición de nombres de personal docente sin un enlace formal a su política de consentimiento de publicación de agenda.
- **Mejora de minimización (PROPUESTO — NO IMPLEMENTADO):**
  - Vincular formalmente la columna a `usuarios.id` mediante clave foránea, garantizando que el docente sea un usuario registrado con consentimiento previo para la asignación de horarios visibles.

---

## 4. Hallazgos de Privacidad Ligados al Modelado de Amenazas

1. **Enumeración masiva de titulares (Ligado a T-03):**  
   La exposición de IDs secuenciales enteros en `GET /auth/user/{user_id}` (`auth.py:53-59`) permite a un atacante construir un script que scrapeé en cuestión de segundos la lista completa de nombres, correos y roles de toda la comunidad universitaria registrada. Esto constituye un incidente grave de violación a la confidencialidad de datos bajo la Ley 1581 de 2012.
2. **Exposición del Token en el Sistema de Archivos Móvil (Ligado a T-11):**  
   Al almacenar el JWT en `.utb_sesion.json` (`frontend/lib/core/storage/token_storage.dart:18-19`), cualquier aplicación con permisos de lectura en el almacenamiento o un usuario en un equipo de cómputo compartido de sala de cómputo puede extraer el token y acceder a los datos de préstamos y perfiles del titular sin autorización.
3. **Persistencia Indefinida sin Política de Supresión (Derecho de Cancelación / Olvido):**  
   El sistema implementa soft-delete (`Usuario.activo = False` en `app/services/auth.py:103`), pero no provee ningún procedimiento de anonimización o purga definitiva para usuarios que ejercen su derecho de cancelación o que se gradúan y desvinculan de la universidad. Las tablas `prestamos` y `prestamos_salon` mantienen las claves foráneas hacia los registros de por vida.

---

## 5. Medidas y Propuestas de Cumplimiento (Roadmap)

Todas las medidas en esta sección corresponden a **PROPUESTO — NO IMPLEMENTADO**:

1. **Mecanismo de Consentimiento Explicito en UI:**  
   Incorporar una casilla obligatoria de verificación en la pantalla de registro de Flutter (`frontend/lib/features/auth/`): *"Acepto la Política de Tratamiento de Datos Personales de la Universidad Tecnológica de Bolívar conforme a la Ley 1581 de 2012"*, guardando la marca de tiempo del consentimiento en la base de datos.
2. **Procedimiento de Anonimización de Préstamos Históricos:**  
   Diseñar una rutina SQL semestral que desvincule los préstamos antiguos mayores a 2 años asignando `usuario_id = NULL` (o a un usuario genérico de auditoría `0`), preservando los indicadores estadísticos de uso del inventario pero eliminando la asociación directa con la persona física.
3. **Endpoint de Ejercicio de Derechos ARCO (Acceso, Rectificación, Cancelación, Oposición):**  
   Habilitar un endpoint dedicado `DELETE /auth/me` que permita al usuario solicitar la desactivación de su cuenta y la supresión de sus datos de contacto activos conforme al marco de Hábeas Data.
