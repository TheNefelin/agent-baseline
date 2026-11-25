# Referencia: Validación y evaluación

## Cross-validation

```python
from sklearn.model_selection import (
    cross_val_score, KFold, StratifiedKFold, TimeSeriesSplit,
)

# Clasificación (estratificado)
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=cv, scoring="accuracy")
print(f"Accuracy: {scores.mean():.4f} ± {scores.std():.4f}")

# Series temporales (sin shuffle, test posterior al train)
tscv = TimeSeriesSplit(n_splits=5)
for fold, (train_idx, test_idx) in enumerate(tscv.split(X), 1):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    model.fit(X_train, y_train)
    score = model.score(X_test, y_test)
    print(f"Fold {fold}: {score:.4f}")
```

## Baseline (siempre comparar)

```python
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.metrics import mean_squared_error, accuracy_score

# Regresión: predecir la media
baseline = DummyRegressor(strategy="mean")
baseline.fit(X_train, y_train)
baseline_pred = baseline.predict(X_test)
baseline_mse = mean_squared_error(y_test, baseline_pred)

# Clasificación: predecir la clase más frecuente
baseline = DummyClassifier(strategy="most_frequent")
baseline.fit(X_train, y_train)
baseline_acc = baseline.score(X_test, y_test)

# Comparar
print(f"Baseline: MSE={baseline_mse:.4f}")
print(f"Modelo:   MSE={model_mse:.4f}")
print(f"Mejora:   {baseline_mse - model_mse:.4f}")
```

## Data leakage (evitar)

| Tipo | Ejemplo | Solución |
|---|---|---|
| Temporal | Usar datos futuros para predecir pasado | TimeSeriesSplit, respetar orden temporal |
| Target leakage | Feature que contiene info del target | Revisar correlaciones, eliminar features sospechosos |
| Train/test contamination | Scaler fit en todo el dataset | Fit scaler solo en train, transform en test |
| Duplicados | Mismo registro en train y test | Deduplicar antes de split |

## Reproducibilidad

```python
import random
import numpy as np

SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# TensorFlow
import tensorflow as tf
tf.random.set_seed(SEED)

# scikit-learn
# Pasar random_state=SEED a todos los modelos
model = RandomForestClassifier(random_state=SEED)
```

## Curvas de aprendizaje

```python
from sklearn.model_selection import learning_curve
import matplotlib.pyplot as plt

train_sizes, train_scores, val_scores = learning_curve(
    model, X, y, cv=5, scoring="accuracy",
    train_sizes=np.linspace(0.1, 1.0, 10),
)

plt.plot(train_sizes, train_scores.mean(axis=1), label="Train")
plt.plot(train_sizes, val_scores.mean(axis=1), label="Validation")
plt.xlabel("Tamaño del training set")
plt.ylabel("Score")
plt.legend()
plt.show()
```

## Overfitting: detección

| Señal | Acción |
|---|---|
| Train score alto, val score bajo | Reducir complejidad, más datos, regularización |
| Train y val score bajos | Más features, más complejidad, más datos |
| Val score oscila mucho | Más datos, cross-validation con más folds |
| Val score mejora con más datos | Agregar más datos (no cambiar modelo) |