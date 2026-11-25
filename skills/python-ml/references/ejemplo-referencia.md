# Referencia: Caso de estudio — Lucky_IA

Proyecto de predicción de lotería (TensorFlow/Keras) usado como ejemplo
de buenas prácticas de código y malas prácticas de diseño de ML.

## Lo que está bien (patrones a replicar)

### Estructura de proyecto
```
project/
├── main.py
├── config/settings.py
├── src/
│   ├── data/ (loader, preprocessor)
│   ├── models/ (lottery_model)
│   └── utils/ (evaluation)
├── tests/ (pytest)
├── requirements.txt
└── README.md
```

### Validación de datos (loader.py)
- Verifica columnas requeridas
- Detecta valores nulos y fuera de rango
- Detecta fechas duplicadas
- Convierte fechas a datetime
- Reporta errores con números de fila

### Persistencia completa
- Modelo (.keras/.h5) + scaler (.pkl) + config (.json)
- Validación de integridad con h5py antes de cargar
- Fallback a entrenamiento nuevo si la carga falla

### Cross-validation (TimeSeriesSplit)
- 5-fold con split cronológico (sin data leakage)
- Score promedio + desviación
- Baseline de comparación (predecir el promedio)

### Tests (pytest)
- Tests para `make_unique` (conteo, unicidad, rango, duplicados, orden)
- Tests para `load_lottery_data` (DataFrame, columnas, nulos, rango, duplicados, archivo inexistente)
- 11 tests pasando

### CI/CD (GitHub Actions)
- Workflow en `.github/workflows/test.yml`
- Python 3.12, pip install, pytest

### Menú de modelo guardado
- Pregunta si cargar modelo existente o entrenar nuevo
- Maneja caso de scaler faltante

## Lo que está mal (anti-patrones a evitar)

### 1. Predecir aleatoriedad
El modelo intenta predecir números de lotería a partir de la fecha.
Los sorteos son aleatorios → no hay señal predictiva.
El modelo memoriza ruido y es **peor** que el baseline (loss 0.32 vs 0.035).

### 2. make_unique sesgado (corregido)
Original: rellenaba números faltantes con los más pequeños (sesgo).
Corregido: usa `random.sample` y ordena.

### 3. Scaler por columna (corregido)
Original: `MinMaxScaler` fit en `(N, 6)` normalizaba cada columna independientemente.
Corregido: fit en datos aplanados `(N*6, 1)` para min/max global.

### 4. Código muerto (eliminado)
- `fit_all()` en preprocessor (nunca se llamaba)
- `format_predictions()` en evaluation (nunca se llamaba)
- `validation_split` param en `LotteryModel.fit` (nunca se usaba)
- Capa `Dense(output_units * 2, relu)` redundante

### 5. Broad except (corregido)
Original: `except Exception` ocultaba errores reales.
Corregido: excepciones específicas (`FileNotFoundError`, `DataValidationError`, etc.)

### 6. Sin type hints (corregido)
Original: `def predict(model, preprocessor)` sin tipos.
Corregido: `def predict(model: LotteryModel, preprocessor: DataPreprocessor) -> None`.

### 7. DATA_DIR engañoso (corregido)
Original: `DATA_DIR` apuntaba a un archivo, no a un directorio.
Corregido: renombrado a `DATA_PATH`.

## Lección principal

**Antes de entrenar un modelo, verifica que exista señal predictiva.**
Si el baseline tiene mejor score que tu modelo, el modelo no sirve.
No insistas: cambia de problema o de features.