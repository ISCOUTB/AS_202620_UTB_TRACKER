"""
Script de demostración interactiva de mensajería asíncrona (Transactional Outbox + Worker).
Usa firmas y servicios reales del proyecto en una base de datos SQLite temporal aislada.
"""
import os
import sys

# Asegurar path del proyecto
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from datetime import datetime, timedelta, timezone
import logging
import tempfile
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.models.auth_models import Usuario
from app.models.recurso_models import Recurso, Prestamo
from app.messaging.models import MensajeOutbox, NotificacionProcesada
from app.messaging.worker import procesar_pendientes, NotificadorSimulado
from app.services.loans import crear_prestamo
from app.schemas import schemas


def setup_logger():
    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter(
        '{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","msg":"%(message)s"}',
        datefmt="%Y-%m-%dT%H:%M:%S",
    )
    handler.setFormatter(formatter)
    
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    root_logger.handlers = [handler]


def main():
    setup_logger()
    logger = logging.getLogger("demo_mensajeria")
    print("=" * 70)
    print(" DEMOSTRACIÓN DE MENSAJERÍA ASÍNCRONA — UTB TRACKER")
    print("=" * 70)

    # Configuración de base de datos temporal
    temp_dir = tempfile.gettempdir()
    db_path = os.path.join(temp_dir, f"tractar_demo_{datetime.now().strftime('%Y%m%d%H%M%S')}.db")
    db_url = f"sqlite:///{db_path.replace(os.sep, '/')}"
    engine = create_engine(db_url, echo=False)
    Session = sessionmaker(bind=engine)
    db = Session()

    try:
        # Crear todas las tablas necesarias
        Base.metadata.create_all(engine)
        print(f"\n[OK] Base de datos temporal creada en: {db_path}")

        # Seed inicial: Usuario y Recursos
        usuario = Usuario(
            id=1,
            email="estudiante@utb.edu.co",
            nombre="Estudiante Demo",
            rol="usuario_utb",
            password="dummy_password_hash",
            activo=True,
        )
        recurso1 = Recurso(
            id=1,
            categoria="computador",
            serial="DEMO-XPS-001",
            descripcion="Laptop Dell XPS 13",
            estado="disponible",
            activo=True,
        )
        recurso2 = Recurso(
            id=2,
            categoria="otro",
            serial="DEMO-OSC-002",
            descripcion="Osciloscopio Digital",
            estado="disponible",
            activo=True,
        )
        db.add_all([usuario, recurso1, recurso2])
        db.commit()

        # ----------------------------------------------------------------------
        # PARTE A: Publicación sin worker (Desacoplamiento temporal)
        # ----------------------------------------------------------------------
        print("\n" + "-" * 70)
        print(" PARTE A: Publicación de préstamo SIN worker")
        print("-" * 70)
        datos_p1 = schemas.PrestamoCreate(
            recurso_id=1,
            usuario_id=1,
            fecha_devolucion_esperada=datetime(2026, 10, 30, 18, 0),
        )
        prestamo1 = crear_prestamo(
            db=db,
            datos=datos_p1,
            idempotency_key="idemp-demo-001",
            correlation_id="req-corr-001",
        )
        print(f"-> Préstamo creado exitosamente: ID={prestamo1.id}, Estado={prestamo1.estado}")
        
        # Consultar estado en outbox
        msg1 = db.query(MensajeOutbox).filter(MensajeOutbox.correlation_id == "req-corr-001").first()
        assert msg1 is not None
        print(f"-> Registro en mensajes_outbox:")
        print(f"   message_id     : {msg1.message_id}")
        print(f"   correlation_id : {msg1.correlation_id}")
        print(f"   tipo           : {msg1.tipo} (v{msg1.version})")
        print(f"   estado         : {msg1.estado}")
        print(f"   intentos       : {msg1.intentos}")
        print(f"   payload        : {msg1.payload}")

        # ----------------------------------------------------------------------
        # PARTE B y C: Reintentos con fallos temporales y trazabilidad del message_id
        # ----------------------------------------------------------------------
        print("\n" + "-" * 70)
        print(" PARTE B y C: Reintentos (2 fallos simulados -> éxito) con logs de punta a punta")
        print("-" * 70)
        notificador_temp = NotificadorSimulado(fallos_antes_de_exito=2)

        # Ciclo 1: Primer intento (falla)
        print("\n[Ciclo Worker 1]")
        ahora1 = msg1.siguiente_intento
        procesar_pendientes(db, notificador_temp, ahora=ahora1)
        db.refresh(msg1)
        print(f"-> Tras ciclo 1: estado={msg1.estado}, intentos={msg1.intentos}, prox_intento={msg1.siguiente_intento.isoformat()}")

        # Ciclo 2: Segundo intento (falla)
        print("\n[Ciclo Worker 2]")
        ahora2 = msg1.siguiente_intento + timedelta(seconds=1)
        procesar_pendientes(db, notificador_temp, ahora=ahora2)
        db.refresh(msg1)
        print(f"-> Tras ciclo 2: estado={msg1.estado}, intentos={msg1.intentos}, prox_intento={msg1.siguiente_intento.isoformat()}")

        # Ciclo 3: Tercer intento (éxito)
        print("\n[Ciclo Worker 3]")
        ahora3 = msg1.siguiente_intento + timedelta(seconds=1)
        procesar_pendientes(db, notificador_temp, ahora=ahora3)
        db.refresh(msg1)
        print(f"-> Tras ciclo 3: estado={msg1.estado}, intentos={msg1.intentos}, procesado_en={msg1.procesado_en}")
        
        # Verificar deduplicación en notificaciones_procesadas
        reg_dedup = db.query(NotificacionProcesada).filter_by(message_id=msg1.message_id).first()
        print(f"-> Registro de deduplicación creado: message_id={reg_dedup.message_id}, procesado_en={reg_dedup.procesado_en}")

        # ----------------------------------------------------------------------
        # PARTE D: Fallo permanente hasta estado "muerto" (DLQ)
        # ----------------------------------------------------------------------
        print("\n" + "-" * 70)
        print(" PARTE D: Fallo permanente hasta agotar reintentos (estado 'muerto')")
        print("-" * 70)
        datos_p2 = schemas.PrestamoCreate(
            recurso_id=2,
            usuario_id=1,
            fecha_devolucion_esperada=datetime(2026, 10, 31, 12, 0),
        )
        prestamo2 = crear_prestamo(
            db=db,
            datos=datos_p2,
            idempotency_key="idemp-demo-002",
            correlation_id="req-corr-dlq",
        )
        msg2 = db.query(MensajeOutbox).filter(MensajeOutbox.correlation_id == "req-corr-dlq").first()
        print(f"-> Préstamo 2 creado: ID={prestamo2.id}. Mensaje ID={msg2.message_id} en outbox.")

        notificador_infinito = NotificadorSimulado(fallos_antes_de_exito=999)
        ahora_dlq = msg2.siguiente_intento
        while msg2.estado == "pendiente":
            procesar_pendientes(db, notificador_infinito, ahora=ahora_dlq, max_intentos=5)
            db.refresh(msg2)
            if msg2.estado == "pendiente":
                ahora_dlq = msg2.siguiente_intento + timedelta(seconds=1)

        print(f"-> Resultado final del mensaje 2:")
        print(f"   estado       : {msg2.estado}")
        print(f"   intentos     : {msg2.intentos}")
        print(f"   ultimo_error : {msg2.ultimo_error}")

        # ----------------------------------------------------------------------
        # PARTE E: Reentrega del mismo message_id con duplicado descartado
        # ----------------------------------------------------------------------
        print("\n" + "-" * 70)
        print(" PARTE E: Reentrega del mensaje 1 con deduplicación en consumidor")
        print("-" * 70)
        # Simulamos que por una falla en la red o reinicio del broker el mensaje 1 vuelve a procesarse
        notificador_reentrega = NotificadorSimulado(fallos_antes_de_exito=0)
        print(f"-> Reintentando procesar mensaje 1 (message_id={msg1.message_id})...")
        
        # Llamamos procesar_un_mensaje directamente para forzar la reentrega
        from app.messaging.worker import _procesar_un_mensaje
        _procesar_un_mensaje(
            db=db,
            msg=msg1,
            notificador=notificador_reentrega,
            ahora=datetime.now(timezone.utc),
            max_intentos=5,
        )
        print(f"-> Envíos realizados por el notificador: {notificador_reentrega._envios} (esperado: 0 por deduplicación)")

        print("\n" + "=" * 70)
        print(" DEMOSTRACIÓN FINALIZADA CON ÉXITO")
        print("=" * 70)

    finally:
        db.close()
        engine.dispose()
        if os.path.exists(db_path):
            os.remove(db_path)
            print(f"[OK] Base de datos temporal borrada: {db_path}\n")


if __name__ == "__main__":
    main()
