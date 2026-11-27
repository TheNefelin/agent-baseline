## 13. Tests (con BD real, aislada y segura)

Principios:
- **BD real PostgreSQL dedicada** (`TEST_DATABASE_URL`), no SQLite: los tests prueban lo mismo que prod (tipos, FKs, asyncpg). **Una BD de tests por proyecto, aislada; nunca la compartida.**
- **Nunca DROP SCHEMA, TRUNCATE global ni drop_all**: el fixture **solo limpia las tablas del proyecto** (prefijo propio, definidas en `postgre_schema.sql`). `DROP SCHEMA public CASCADE` destruye constraints de tablas ajenas en BDs compartidas y es ilegal. La garantía real son credenciales **sin permisos de DDL/DROP sobre producción** + la BD dedicada.
- **Guard de destino (barrera temprana, no la garantía)**: `conftest.py` aborta antes de tocar nada si `TEST_DATABASE_URL` no termina en `_test`, es `postgres`, o su **destino** (host resuelto a IP, puerto, nombre) coincide con `DATABASE_URL`. Es *best-effort* (alias/DNS/proxies pueden eludirlo): la **garantía real** son credenciales **sin permisos de DDL/DROP sobre producción** + la BD dedicada. Este guard es **obligatorio**.
- `conftest.py` centraliza: engine, sesión, override de `get_db` y `verify_api_key`, y siembra los datos mínimos (roles y un usuario admin).
- Un test = 1 caso (éxito + cada error). Fórmula por recurso: create ✓, duplicate ✗, list empty, list, filter, get_by_id, get_by_id 404, update, update 404, update duplicate, delete, delete 404, pagination.
- **Tests live aislados**: los que tocan servicios externos reales (enviar email a Brevo, cobrar, subir a Cloudinary) van en archivos `test_*_live.py` marcados `@pytest.mark.live` y **excluidos por defecto** (`addopts = -m "not live"` en `pytest.ini`). Solo corren a demanda con `pytest -m live`. Esto evita que la suite común dispare llamadas pagadas/irreversibles. Condicional extra si requieren credencial: `@pytest.mark.skipif(not settings.TEST_BREVO_EMAIL)`.

```ini
# pytest.ini
[pytest]
pythonpath = .
asyncio_mode = auto
addopts = -m "not live"

[markers]
live: tests que tocan servicios externos reales (envio de email, pagos); se corren a demanda con `pytest -m live`
```

```python
# tests/test_contact_live.py
import pytest
from src.core.config import settings
from src.api.contact import brevo

pytestmark = pytest.mark.live


@pytest.mark.skipif(not settings.TEST_BREVO_EMAIL, reason="TEST_BREVO_EMAIL no configurado")
async def test_send_contact_email_live():
  message_id = await brevo.send_contact_email(to=settings.TEST_BREVO_EMAIL, ...)
  assert message_id
```

### Convención de archivos .sql (obligatoria)

Todo proyecto backend con BD debe tener al menos:

| Archivo | Obligatorio | Contenido |
|---|---|---|
| `postgre_schema.sql` | ✅ Sí | DDL: CREATE TABLE IF NOT EXISTS + índices + constraints |
| `postgre_seed.sql` | ✅ Sí | Seeds idempotentes (ON CONFLICT / WHERE NOT EXISTS) |
| `postgre_auth.sql` | ⚠️ Opcional | Datos de auth (roles, usuarios iniciales) |

Estos archivos son la **fuente de verdad** de qué tablas pertenecen al proyecto. Los tests usan esta lista para saber qué limpiar.

### Limpieza entre tests (solo tablas del proyecto)

```python
# tests/conftest.py
# Solo las tablas de ESTE proyecto (mismo prefijo que prod), derivadas de postgre_schema.sql.
# El aislamiento entre proyectos lo da la BD dedicada, no esta lista.
TEST_TABLES = ["app_wishlist_items", "app_reviews", "app_products",
               "app_categories", "app_user_sessions", "app_users", "app_roles"]


async def _clean_tables(session: AsyncSession):
    """Vacía las tablas del proyecto entre tests (reset de identidades)."""
    await session.execute(
        text(f"TRUNCATE {', '.join(TEST_TABLES)} RESTART IDENTITY CASCADE")
    )
    await session.commit()
```

**Regla**: `TRUNCATE` solo las tablas del proyecto (con `RESTART IDENTITY CASCADE` para resetear secuencias). **Nunca** `DROP SCHEMA`, `TRUNCATE` sin lista, ni `drop_all` sobre la BD. Los tests **no crean ni eliminan tablas ni BD** — solo ejecutan tests y limpian datos entre runs.

### `tests/conftest.py`

```python
from uuid import uuid4, UUID
import socket
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import NullPool

from src.core.database import Base, get_db
from src.core.config import settings
from src.core.dependencies import verify_api_key
from src.core.limiter import limiter
from src.core.security import create_access_token
from src.main import app

ADMIN_USER_ID = UUID("00000000-0000-0000-0000-000000000001")
ADMIN_TOKEN = create_access_token(ADMIN_USER_ID, "admin")

# Guard de destino: barrera temprana contra una BD no aislada.
def _resolve_host(host: str) -> set:
  try:
    return {info[4][0] for info in socket.getaddrinfo(host, None)}
  except OSError:
    return {host}


_test = make_url(settings.TEST_DATABASE_URL)
_dev = make_url(settings.DATABASE_URL) if getattr(settings, "DATABASE_URL", None) else None
if not _test.database or not _test.database.endswith("_test") or _test.database == "postgres":
    raise RuntimeError(
        "TEST_DATABASE_URL debe apuntar a una BD de pruebas dedicada "
        f"(nombre terminado en '_test'), no '{_test.database}'."
    )
if _dev and _resolve_host(_test.host or "") & _resolve_host(_dev.host or "") \
        and (_test.port, _test.database) == (_dev.port, _dev.database):
    raise RuntimeError(
        "TEST_DATABASE_URL apunta al MISMO destino que DATABASE_URL (dev/producción); "
        "rechazado para no borrar datos."
    )

engine = create_async_engine(settings.TEST_DATABASE_URL, poolclass=NullPool)
TestingSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=engine, class_=AsyncSession)


# Solo las tablas de ESTE proyecto (derivadas de postgre_schema.sql).
TEST_TABLES = ["app_wishlist_items", "app_reviews", "app_products",
               "app_categories", "app_user_sessions", "app_users", "app_roles"]


async def _clean_tables(session: AsyncSession):
    """Vacía las tablas del proyecto entre tests (reset de identidades)."""
    await session.execute(
        text(f"TRUNCATE {', '.join(TEST_TABLES)} RESTART IDENTITY CASCADE")
    )
    await session.commit()


@pytest.fixture(scope="module")
async def setup_db():
    # Aplica el DDL real del proyecto (postgre_schema.sql, idempotente).
    # NO hace DROP SCHEMA ni crea/elimina BD. La BD de tests es dedicada.
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


@pytest.fixture
async def db(setup_db):
    async with TestingSessionLocal() as session:
        await _clean_tables(session)
        # Seed mínimo del proyecto: roles y usuario admin (con IDs fijos para los
        # tokens de prueba).
        session.add_all([Role(id=1, name="user"), Role(id=2, name="admin")])
        session.add(User(id=ADMIN_USER_ID, email="admin@test.com", role_id=2))
        await session.flush()
        yield session


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    limiter.reset()
    yield


@pytest.fixture
async def client(db):
    async def override_get_db():
        yield db

    async def override_verify_api_key():
        return True

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[verify_api_key] = override_verify_api_key
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test",
                           headers={"Authorization": f"Bearer {ADMIN_TOKEN}"}) as ac:
        yield ac
    app.dependency_overrides.clear()
```

### Ejemplo de test (`tests/test_products.py`)

```python
async def test_create_product(client, db):
    response = await client.post("/api/products/", json={
        "category_id": 1, "name": "Widget", "slug": "widget", "price": 1000,
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Widget"


async def test_create_product_duplicate_name(client, db):
    await client.post("/api/products/", json={"category_id": 1, "name": "Widget", "slug": "widget", "price": 1000})
    response = await client.post("/api/products/", json={"category_id": 1, "name": "Widget", "slug": "other", "price": 500})
    assert response.status_code == 400
    assert "already exists" in response.json()["detail"]
```

**Flujo de trabajo**: `pytest` corre contra `TEST_DATABASE_URL` (BD dedicada `*_test`). Los tests limpian **solo las tablas del proyecto** (TRUNCATE con lista explícita). **Nunca** DROP SCHEMA, TRUNCATE sin lista, ni drop_all. El rol de tests **no debe tener permisos de DDL/DROP** sobre producción. Para repoblar la BD de desarrollo usa `repopulate_db.py`; el seed debe ser idempotente (FKs por natural keys, no IDs en duro).

---

### Repoblar la BD de desarrollo (seed idempotente)

Todo proyecto backend con BD debe incluir un script `repopulate_db.py` que aplica el DDL + seed sobre la BD de desarrollo. **No crea ni elimina la BD** — solo aplica los `.sql` (que usan `CREATE TABLE IF NOT EXISTS`). Si se quiere empezar desde cero, el desarrollador elimina la BD manualmente.

**Template completo:**

```python
# repopulate_db.py
import argparse
import os
import sys
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
SCHEMA_FILE = BASE_DIR / "postgre_schema.sql"
SEED_FILE = BASE_DIR / "postgre_seed.sql"
AUTH_SCHEMA_FILE = BASE_DIR / "postgre_auth.sql"


def _normalize(url: str) -> str:
    return url.replace("postgresql+asyncpg://", "postgresql://", 1)


async def _apply_file(conn, path, label):
    sql = path.read_text(encoding="utf-8")
    await conn.execute(sql)
    print(f"Applied {label}: {path.name}")


async def main() -> int:
    parser = argparse.ArgumentParser(description="Rebuild the database from SQL files.")
    parser.add_argument("--test", action="store_true", help="Use TEST_DATABASE_URL instead of DATABASE_URL.")
    args = parser.parse_args()

    load_dotenv(BASE_DIR / ".env")
    url = os.getenv("TEST_DATABASE_URL" if args.test else "DATABASE_URL")
    if not url:
        print("ERROR: DATABASE_URL is not defined in .env.", file=sys.stderr)
        return 1
    url = _normalize(url)

    for file, label in ((SCHEMA_FILE, "schema"), (SEED_FILE, "seed")):
        if not file.exists():
            print(f"ERROR: {file.name} not found in {BASE_DIR}.", file=sys.stderr)
            return 1

    conn = await asyncpg.connect(url)
    try:
        await _apply_file(conn, SCHEMA_FILE, "schema")
        if AUTH_SCHEMA_FILE.exists():
            await _apply_file(conn, AUTH_SCHEMA_FILE, "auth schema")
        await _apply_file(conn, SEED_FILE, "seed")
    finally:
        await conn.close()

    print("Done. Database rebuilt.")
    return 0


if __name__ == "__main__":
    import asyncio
    raise SystemExit(asyncio.run(main()))
```

- El seed debe ser **idempotente**: FKs por natural keys (no IDs en duro), `ON CONFLICT` o `INSERT ... WHERE NOT EXISTS`.
- El DDL y el seed viven en archivos `.sql` versionados (`postgre_schema.sql`, `postgre_seed.sql`, `postgre_auth.sql`), no en código Python.
- Para tests: el fixture aplica el mismo `.sql` (idempotente) y hace rollback por test — no toca la BD de desarrollo.
- **Nunca** DROP DATABASE, DROP SCHEMA, ni drop_all. Si se necesita empezar de cero, el desarrollador lo hace manualmente.