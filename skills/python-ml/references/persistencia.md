# Referencia: Persistencia de modelos

## scikit-learn (joblib)

```python
import joblib
from pathlib import Path

MODEL_PATH = Path("modelo.joblib")
SCALER_PATH = Path("scaler.joblib")
CONFIG_PATH = Path("config.json")

# Guardar
joblib.dump(model, MODEL_PATH)
joblib.dump(scaler, SCALER_PATH)

# Cargar
model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

# Validar integridad
if not MODEL_PATH.exists():
    raise FileNotFoundError(f"Modelo no encontrado: {MODEL_PATH}")
```

## TensorFlow/Keras (formato nativo)

```python
# Guardar
model.save("modelo.keras")  # Formato nativo Keras 3

# Cargar
from tensorflow.keras.models import load_model
model = load_model("modelo.keras")

# Con custom objects
model = load_model("modelo.keras", custom_objects={"MyLayer": MyLayer})
```

## Hiperparámetros (JSON)

```python
import json

config = {
    "hidden_layers": [128, 64],
    "output_units": 6,
    "activation": "relu",
    "output_activation": "sigmoid",
    "epochs": 50,
    "batch_size": 32,
    "seed": 42,
}

with open("config.json", "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)

# Cargar
with open("config.json", encoding="utf-8") as f:
    config = json.load(f)
```

## Validar integridad del archivo

```python
import h5py

def is_valid_h5(filepath: str) -> bool:
    """Verifica que el archivo sea un HDF5 válido con modelo."""
    try:
        with h5py.File(filepath, "r") as f:
            return "model_weights" in f or "model_config" in f
    except Exception:
        return False
```

## Versionado

```python
from datetime import datetime
from pathlib import Path
import hashlib

def save_with_version(model, scaler, config, base_dir: Path):
    """Guarda modelo con timestamp y hash para trazabilidad."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    version_dir = base_dir / f"v_{timestamp}"
    version_dir.mkdir(parents=True, exist_ok=True)

    model.save(version_dir / "model.keras")
    joblib.dump(scaler, version_dir / "scaler.joblib")
    with open(version_dir / "config.json", "w") as f:
        json.dump(config, f, indent=2)

    # Hash del modelo para verificación
    model_bytes = (version_dir / "model.keras").read_bytes()
    model_hash = hashlib.sha256(model_bytes).hexdigest()
    (version_dir / "hash.txt").write_text(model_hash)

    return version_dir
```