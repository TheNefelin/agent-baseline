## 9. Uploads de imágenes (multipart + servicio de almacenamiento)

- Endpoint `POST /{resource}/upload-image` con `UploadFile` + form fields (`id` o `{parent}_id` según cree o actualice el registro).
- El service borra la imagen anterior (si existe) **antes** de subir la nueva.
- `DELETE /{resource}/{id}/image` borra del storage y limpia el campo URL.
- `extract_public_id(url)` saca el public_id desde la URL, saltando el bloque de transformación.

```python
# src/core/cloudinary.py — patrón de almacenamiento (idéntico para S3 u otro)
def upload_image_16_9(file_bytes: bytes, folder: str, public_id: str | None = None) -> tuple[str, str]:
  result = cloudinary.uploader.upload(
    file_bytes, folder=folder, public_id=public_id, resource_type="image", format="webp",
    transformation={"width": 1280, "height": 720, "crop": "fill", "gravity": "center", "quality": "auto"},
  )
  return result["secure_url"], result["public_id"]


def upload_image_1_1(file_bytes: bytes, folder: str, public_id: str | None = None) -> tuple[str, str]:
  result = cloudinary.uploader.upload(
    file_bytes, folder=folder, public_id=public_id, resource_type="image", format="webp",
    transformation={"width": 512, "height": 512, "crop": "fill", "gravity": "center", "quality": "auto"},
  )
  return result["secure_url"], result["public_id"]


def delete_image(public_id: str, retries: int = 2) -> bool:
  for attempt in range(retries):
    try:
      result = cloudinary.uploader.destroy(public_id, resource_type="image")
    except Exception as exc:
      if attempt < retries - 1:
        continue
      logger.error(f"Cloudinary destroy failed for {public_id}: {exc}")
      return False
    status = result.get("result") if isinstance(result, dict) else None
    if status in ("ok", "not found"):
      return True
    if attempt < retries - 1:
      continue
    logger.error(f"Cloudinary destroy returned unexpected status for {public_id}: {result}")
    return False
  return False


def extract_public_id(url: str) -> str | None:
  if not url:
    return None
  try:
    after_upload = url.split("/upload/")[1]
    # Saltar el bloque de transformación opcional (c_fill,h_720,q_auto,w_1280,f_webp)
    # hasta la versión (v<timestamp>). Sin esto, destroy() recibe un public_id
    # inválido ("v.../folder/file") y el storage no borra el archivo.
    while after_upload and not after_upload.startswith("v"):
      after_upload = after_upload.split("/", 1)[1]
    parts = after_upload.split("/", 1)[1] if "/" in after_upload else after_upload
    return parts.rsplit(".", 1)[0]
  except Exception:
    return None
```

```python
# routes.py
@router.post("/upload-image", response_model=dtos.ProductResponse, status_code=200)
async def upload_product_image(id: int = Form(), file: UploadFile = File(...), db=Depends(get_db), _: dict = Depends(require_admin)):
  return await service.upload_image(db, id, await file.read())
```

```python
from starlette.concurrency import run_in_threadpool

# service.py — sube la nueva PRIMERO y borra la anterior después (si la subida falla, la vieja sigue disponible)
async def upload_image(db, id, file_bytes):
  entity = await repository.get_by_id(db, id)
  if not entity:
    raise NotFoundError("Product")
  # El SDK de Cloudinary es BLOQUEANTE: offload a un thread para no bloquear el event loop.
  image_url, _ = await run_in_threadpool(cloudinary_upload, file_bytes, folder="products")
  if entity.image_url:
    public_id = extract_public_id(entity.image_url)
    if public_id:
      await run_in_threadpool(cloudinary_delete, public_id)
  return dtos.ProductResponse.model_validate(await repository.set_image_url(db, id, image_url))
```

> **Nota**: `cloudinary.uploader.upload/destroy` son sincrónicas; llamarlas directo dentro de `async def` bloquea el event loop bajo carga (mismo patrón en `delete()`).

**Eliminación con imagen**: el `delete()` del service borra la imagen del storage antes de borrar el registro.

### Limpieza en fallo (rollback del storage)

Si la subida tiene éxito pero la persistencia en la BD falla (o al revés), el archivo queda huérfano en el storage. Envolver la subida en un `try/except` que borre lo subido si algo falla después:

```python
# src/core/image.py — sube la nueva PRIMERO y borra la anterior después
async def upload_image_16_9(folder: str, file_bytes: bytes) -> str:
  public_id = None
  try:
    url, public_id = cloudinary_upload_16_9(file_bytes=file_bytes, folder=folder)
    return url
  except Exception as e:
    if public_id:
      try:
        cloudinary_delete_image(public_id)
      except Exception:
        pass
    raise e
```

- Subir **primero**, borrar **después**: si la subida falla, la imagen vieja sigue disponible.
- Si el borrado del storage falla, no propagar: el registro ya se borró, y un archivo huérfano es mejor que una excepción al usuario.
- `delete_image(public_id, retries=2)`: reintentar el `destroy` un par de veces (el storage puede tener latencia) y considerar `result == "not found"` como éxito.

### `extract_public_id` (sacar el public_id desde la URL)

Las URLs de Cloudinary incluyen un bloque de transformación opcional (`c_fill,w_1280,q_auto,...`) antes de la versión (`v<timestamp>`). Hay que saltarlo hasta la versión:

```python
def extract_public_id(url: str) -> str | None:
  if not url: return None
  try:
    after_upload = url.split("/upload/")[1]
    while after_upload and not after_upload.startswith("v"):
      after_upload = after_upload.split("/", 1)[1]
    parts = after_upload.split("/", 1)[1] if "/" in after_upload else after_upload
    return parts.rsplit(".", 1)[0]
  except Exception:
    return None
```

Sin el loop, `destroy()` recibe un public_id inválido (`v.../folder/file`) y el storage no borra el archivo.
