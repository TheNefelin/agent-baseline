# Referencia: TensorFlow/Keras

## Arquitectura de modelo (Keras 3)

```python
from tensorflow.keras import layers, models

model = models.Sequential([
    layers.Input(shape=(input_dim,)),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(64, activation="relu"),
    layers.Dense(output_units, activation="sigmoid"),  # o softmax, linear
])

model.compile(
    optimizer="adam",
    loss="mean_squared_error",  # o binary_crossentropy, categorical_crossentropy
    metrics=["mae"],  # o accuracy
)
```

## Callbacks

```python
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau

callbacks = [
    EarlyStopping(
        monitor="val_loss",
        patience=15,
        restore_best_weights=True,
        verbose=1,
    ),
    ModelCheckpoint(
        "best_model.keras",
        monitor="val_loss",
        save_best_only=True,
        verbose=1,
    ),
    ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=5,
        min_lr=1e-6,
        verbose=1,
    ),
]

model.fit(X_train, y_train, validation_data=(X_val, y_val), callbacks=callbacks)
```

## Persistencia (formato nativo .keras)

```python
# Guardar
model.save("modelo.keras")  # Formato nativo Keras 3

# Cargar
from tensorflow.keras.models import load_model
model = load_model("modelo.keras")

# Con custom objects
model = load_model("modelo.keras", custom_objects={"MyLayer": MyLayer})
```

## Normalización

```python
from sklearn.preprocessing import MinMaxScaler, StandardScaler

# Global (todos los valores juntos) — recomendado para datos homogéneos
scaler = MinMaxScaler(feature_range=(0, 1))
scaler.fit(data.reshape(-1, 1))  # flatten para min/max global
data_norm = scaler.transform(data.reshape(-1, 1)).reshape(data.shape)

# Por columna (solo si las columnas tienen escalas distintas)
scaler = MinMaxScaler(feature_range=(0, 1))
scaler.fit(data)  # (N, features)
data_norm = scaler.transform(data)

# Desnormalizar
data_original = scaler.inverse_transform(data_norm.reshape(-1, 1)).reshape(data_norm.shape)
```

## Reproducibilidad

```python
import random
import numpy as np
import tensorflow as tf

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
tf.random.set_seed(SEED)

# Para determinismo completo (más lento):
# tf.config.experimental.enable_op_determinism()
```

## Overfitting: señales y soluciones

| Señal | Solución |
|---|---|
| val_loss sube mientras train_loss baja | EarlyStopping, Dropout, regularización L2 |
| Gran gap entre train y val loss | Más datos, menos complejidad, dropout |
| Loss muy bajo en train, alto en val | Reducir capas/neuronas, aumentar datos |
| Loss oscila mucho | Reducir learning rate, aumentar batch size |

## Formato legacy (.h5)

```python
# Solo para compatibilidad con código antiguo
model.save("modelo.h5")
model = load_model("modelo.h5")
# Advertencia: deprecated en Keras 3, usar .keras
```