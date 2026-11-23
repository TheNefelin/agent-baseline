# Configuración y logging

Dos capas de configuración, ambas válidas: **`pydantic-settings`** (recomendada) o **`python-dotenv` + clase propia**. Lo que no cambia: las variables requeridas **fallan al arrancar** si faltan, nunca valores hardcodeados ni secretos ficticios.

## `src/core/config.py` (pydantic-settings)

Todo lo externo es **opcional** (el proyecto decide qué integra). Las variables `TEST_*` son `None` por defecto y solo las leen las pruebas; se declaran igual en el `Settings` porque Pydantic ignora variables `.env` que no estén declaradas aquí.

```python
import json
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
  DEBUG: bool = False

  DATABASE_URL: str
  TEST_DATABASE_URL: str | None = None   # solo para tests (BD real aislada)

  CORS_ORIGINS: str  # JSON string: ["http://localhost:3000"]
  SECRET_KEY: str
  API_KEY: str

  # Externos opcionales según el proyecto:
  GOOGLE_CLIENT_ID: str | None = None
  CLOUDINARY_CLOUD_NAME: str | None = None
  CLOUDINARY_API_KEY: str | None = None
  CLOUDINARY_API_SECRET: str | None = None
  BREVO_API_KEY: str | None = None
  BREVO_FROM_EMAIL: str | None = None
  BREVO_FROM_NAME: str | None = None
  TEST_BREVO_EMAIL: str | None = None   # solo para tests live

  @property
  def cors_origins_list(self) -> list[str]:
    return json.loads(self.CORS_ORIGINS)

  model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()
```

Nota: si una integración es obligatoria, mueve esa variable a `str` sin default — arrancará con error claro si falta. Ejemplo real: `DATABASE_URL`, `SECRET_KEY`, `API_KEY` son requeridas; Cloudinary y Brevo son opcionales.

### Variante `python-dotenv` + clase propia

```python
import json
import os

from dotenv import load_dotenv

# El entorno real (CI, Docker, Vercel) gana sobre el .env local: override=False.
load_dotenv(override=False)


def _required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Falta la variable de entorno requerida: {name}. Defínela en tu .env.")
    return value


def _parse_cors_origins() -> list[str]:
    raw = os.getenv("CORS_ORIGINS", "").strip()
    if not raw:
        return []  # vacío = ningún origen cross-origin permitido
    try:
        origins = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"CORS_ORIGINS no es JSON válido: {raw!r}") from exc
    if not isinstance(origins, list) or not all(isinstance(o, str) for o in origins):
        raise RuntimeError("CORS_ORIGINS debe ser un arreglo JSON de strings.")
    return origins


class Settings:
    DATABASE_URL: str = _required("DATABASE_URL")
    API_KEY: str = _required("API_KEY")
    CORS_ORIGINS: list[str] = _parse_cors_origins()


settings = Settings()
```

- **`override=False`**: el entorno del sistema gana sobre el `.env`. Con `override=True` una variable stale del sistema queda oculta por el `.env` local.
- **CORS fail-closed**: `CORS_ORIGINS` vacío o ausente significa "sin orígenes cross-origin permitidos", nunca una lista por defecto. Parsea el JSON al arrancar y aborta si no es un arreglo de strings.
- Nunca combines `allow_origins=['*']` con `allow_credentials=True`: el navegador lo rechaza y esconde el fallo.

## `src/core/database.py`

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base

from src.core.config import settings

engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG, pool_pre_ping=True)
# expire_on_commit=False: tras un commit los atributos del ORM se expirarían y leerlos
# volvería a disparar SQL (o MissingGreenlet en async). Si necesitas un valor tras el
# commit, cópialo a una variable ANTES del commit.
AsyncSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=engine, class_=AsyncSession, expire_on_commit=False)
Base = declarative_base()


async def get_db():
  async with AsyncSessionLocal() as session:
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
```

- `pool_pre_ping=True` detecta conexiones muertas en poolers.
- `get_db()` es la **única** que hace `commit()`/`rollback()`: una transacción por request (§4.2 del SKILL).

## `src/core/logger.py` (JSON + request_id por petición)

```python
import json, logging, sys
from contextvars import ContextVar
from datetime import datetime, timezone

_request_id: ContextVar[str] = ContextVar("request_id", default="")


def set_request_id(value: str) -> None:
  _request_id.set(value)


def get_request_id() -> str:
  return _request_id.get()


class JsonFormatter(logging.Formatter):
  def format(self, record: logging.LogRecord) -> str:
    entry = {"timestamp": datetime.now(tz=timezone.utc).isoformat(), "level": record.levelname,
             "logger": record.name, "message": record.getMessage(), "request_id": get_request_id()}
    if hasattr(record, "props"):
      entry.update(record.props)
    return json.dumps(entry, ensure_ascii=False)


def setup_logger() -> logging.Logger:
  logger = logging.getLogger("api")
  logger.setLevel(logging.INFO)
  handler = logging.StreamHandler(sys.stdout)
  handler.setFormatter(JsonFormatter())
  logger.addHandler(handler)
  return logger


logger = setup_logger()
```

```python
# main.py — middleware que setea el request_id y loguea cada request
@app.middleware("http")
async def log_requests(request: Request, call_next):
  request_id = str(uuid.uuid4())
  set_request_id(request_id)
  start = time.time()
  response = await call_next(request)
  logger.info("%s %s", request.method, request.url.path, extra={
    "props": {"method": request.method, "path": request.url.path,
              "status_code": response.status_code,
              "duration_ms": round((time.time() - start) * 1000, 2)}})
  return response
```
