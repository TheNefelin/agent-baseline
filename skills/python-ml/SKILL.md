---
name: python-ml
description: "Machine Learning clásico en Python (scikit-learn, TensorFlow/Keras): clasificación, regresión, validación, métricas, persistencia de modelos, anti-patrones. NO para APIs (`fastapi`/`dotnet`), bases de datos (`sql`/`nosql`) ni IA generativa."
---

# SKILL: Machine Learning Clásico en Python — Patrón Senior

Guía de referencia para construir modelos de ML clásico (no generativo) en Python, con buenas prácticas validadas. Cubre clasificación, regresión, clustering, validación, métricas y persistencia.

**Referencias** (se leen bajo demanda, rutas relativas a esta skill): `references/scikit-learn.md`, `references/tensorflow-keras.md`, `references/validacion.md`, `references/preprocesamiento.md`, `references/persistencia.md`, `references/anti-patrones.md`, `references/ejemplo-referencia.md`.

> **Frescura:** verificado 2026-11-25 · ámbito: scikit-learn 1.8.0, TensorFlow 2.20.0, Keras 3.13.0, Python 3.12 · fuente: Lucky_IA (proyecto de referencia) + documentación oficial.

## Cuándo NO usar

| Situación | Skill |
|---|---|
| API REST en Python | `fastapi` |
| API en .NET | `dotnet` |
| Bases de datos | `sql` / `nosql` |
| Frontend | `angular` / `astro` |
| IA generativa (LLMs, chatbots, generación de texto) | (fuera de alcance) |
| Reinforcement Learning avanzado | (fuera de alcance) |
| Computer Vision / NLP profundo | (fuera de alcance) |

## 1. Principio fundamental

**Antes de entrenar, verifica que exista señal predictiva.**

Si no hay relación entre entrada y salida (ej. predecir lotería desde fecha), ningún modelo la va a encontrar. El modelo memorizará ruido (overfitting) y será peor que el baseline (predecir el promedio).

Regla: si el baseline tiene mejor score que tu modelo, el modelo no sirve. No insistas: cambia de problema o de features.

## 2. Estructura de proyecto

```
project/
├── main.py (o train.py)       # Punto de entrada
├── config/settings.py         # Configuración centralizada
├── src/
│   ├── data/                  # loader, preprocessor
│   ├── models/                # definición y entrenamiento
│   └── utils/                 # evaluación, métricas
├── tests/                     # pytest
├── requirements.txt           # versiones fijas (pip freeze)
└── README.md                  # Documentación
```

## 3. Validación (obligatorio)

- **Siempre cross-validation** (k-fold o TimeSeriesSplit para series temporales)
- **Siempre comparar contra un baseline** (predecir el promedio, la moda, o un modelo trivial)
- **Siempre fijar seeds** (`random.seed`, `np.random.seed`, `tf.random.set_seed`) para reproducibilidad
- **Nunca evaluar en train** — el resultado es optimista y no generaliza
- **Nunca usar datos futuros** para predecir el pasado (data leakage)

## 4. Métricas mínimas por tipo de problema

| Problema | Métricas obligatorias |
|---|---|
| Regresión | MSE, MAE, R², baseline comparison |
| Clasificación | Accuracy, precision, recall, F1, confusion matrix |
| Clustering | Silhouette score, inertia |

Detalle de métricas, curvas ROC/PR y matrices de confusión en `references/scikit-learn.md`.

## 5. Anti-patrones (NO hacer)

| Anti-patrón | Por qué evitarlo |
|---|---|
| Predecir aleatoriedad | No hay patrón que aprender; el modelo memoriza ruido |
| Data leakage (usar datos futuros) | El modelo "ve el futuro" en entrenamiento |
| Scaler por columna | Normalizar cada feature independientemente sesga la escala global |
| Evaluar en train | Resultado optimista, no generaliza a datos nuevos |
| Sin baseline | No sabes si el modelo mejora sobre lo trivial |
| Sin reproducibilidad | No puedes replicar resultados ni depurar |
| `model.save('modelo.h5')` | Formato legacy; usar `.keras` (nativo Keras 3) |
| `layers.Input(shape=...)` en Sequential | Deprecated en Keras 3; usar `input_shape` en la primera capa |

Detalle completo de anti-patrones con ejemplos en `references/anti-patrones.md`.

## 6. Persistencia

- Guardar **modelo + scaler + config** (hiperparámetros) juntos
- Usar formato nativo (`.keras`, no `.h5`)
- Validar integridad al cargar (try/except con fallback)
- Versionar con hash o timestamp para trazabilidad

Detalle de serialización y carga en `references/persistencia.md`.

## 7. Checklist final (¿esto es SENIOR?)

- [ ] Señal predictiva verificada (baseline comparison)
- [ ] Cross-validation con score honesto
- [ ] Seeds fijados (reproducible)
- [ ] Métricas apropiadas al problema
- [ ] Modelo + scaler + config persistidos
- [ ] Tests para funciones críticas (make_unique, loader, preprocessor)
- [ ] Sin data leakage
- [ ] Sin código muerto
- [ ] Sin capas redundantes en el modelo
- [ ] Type hints en todas las funciones

## 8. Referencias internas

| Tema | Archivo | Cuándo leerlo |
|---|---|---|
| scikit-learn (SVM, RF, XGBoost, pipelines, métricas) | `references/scikit-learn.md` | al implementar modelos clásicos |
| TensorFlow/Keras (redes neuronales, callbacks, persistencia) | `references/tensorflow-keras.md` | al construir redes neuronales |
| Validación (cross-validation, baseline, data leakage) | `references/validacion.md` | antes de entrenar o evaluar |
| Preprocesamiento (scalers, encoding, imputación) | `references/preprocesamiento.md` | al preparar datos |
| Persistencia (joblib, JSON config, versionado) | `references/persistencia.md` | al guardar/cargar modelos |
| Anti-patrones (qué NO hacer) | `references/anti-patrones.md` | al revisar código o diseñar |
| Caso de estudio (Lucky_IA) | `references/ejemplo-referencia.md` | al necesitar un ejemplo concreto |

## 9. Fuentes

- **scikit-learn**: documentación oficial (`scikit-learn.org`).
- **TensorFlow/Keras**: documentación oficial (`tensorflow.org`, `keras.io`).
- **Cross-validation**: scikit-learn `cross_val_score`, `TimeSeriesSplit`.
- **Persistencia**: `joblib` para objetos sklearn, `model.save()` para Keras.
- **Anti-patrones**: experiencia práctica en proyectos de ML (Lucky_IA como caso de estudio).