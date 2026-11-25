# Referencia: Preprocesamiento de datos

## Scalers

```python
from sklearn.preprocessing import MinMaxScaler, StandardScaler, RobustScaler

# MinMax: escala a [0, 1] (o rango custom)
scaler = MinMaxScaler(feature_range=(0, 1))

# Standard: media=0, std=1 (para datos normales)
scaler = StandardScaler()

# Robust: usa mediana e IQR (resistente a outliers)
scaler = RobustScaler()

# Fit en train, transform en train y test
scaler.fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Desnormalizar
X_original = scaler.inverse_transform(X_scaled)
```

## Encoding de variables categóricas

```python
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, LabelEncoder

# One-hot (para categorías sin orden)
encoder = OneHotEncoder(handle_unknown="ignore", sparse_output=False)
X_encoded = encoder.fit_transform(X_train[["city", "gender"]])

# Ordinal (para categorías con orden)
encoder = OrdinalEncoder(categories=[["low", "medium", "high"]])
X_encoded = encoder.fit_transform(X_train[["level"]])

# Label (para target)
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y_train)
```

## Imputación de valores faltantes

```python
from sklearn.impute import SimpleImputer, KNNImputer

# Media/mediana/moda
imputer = SimpleImputer(strategy="median")
X_imputed = imputer.fit_transform(X_train)

# KNN (más preciso, más lento)
imputer = KNNImputer(n_neighbors=5)
X_imputed = imputer.fit_transform(X_train)
```

## Pipeline completo

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer

numeric_features = ["age", "income", "score"]
categorical_features = ["city", "gender"]

numeric_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler", StandardScaler()),
])

categorical_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("encoder", OneHotEncoder(handle_unknown="ignore")),
])

preprocessor = ColumnTransformer([
    ("num", numeric_transformer, numeric_features),
    ("cat", categorical_transformer, categorical_features),
])

pipeline = Pipeline([
    ("preprocessor", preprocessor),
    ("classifier", RandomForestClassifier(n_estimators=100)),
])

pipeline.fit(X_train, y_train)
```

## Validación de datos (pandas)

```python
import pandas as pd

def validate_data(df: pd.DataFrame, required_columns: list[str]) -> list[str]:
    """Retorna lista de errores encontrados."""
    errors = []

    # Columnas requeridas
    missing = [c for c in required_columns if c not in df.columns]
    if missing:
        errors.append(f"Columnas faltantes: {missing}")

    # Valores nulos
    for col in required_columns:
        null_count = df[col].isnull().sum()
        if null_count > 0:
            errors.append(f"'{col}': {null_count} valores nulos")

    # Rango de valores
    if "age" in df.columns:
        out_of_range = df[(df["age"] < 0) | (df["age"] > 120)]
        if not out_of_range.empty:
            errors.append(f"Edades fuera de rango: {len(out_of_range)} filas")

    # Duplicados
    if df.duplicated().any():
        errors.append(f"{df.duplicated().sum()} filas duplicadas")

    return errors
```