# Referencia: scikit-learn

## Modelos clásicos

```python
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.svm import SVC, SVR
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression, LinearRegression
from xgboost import XGBClassifier, XGBRegressor

# Clasificación
model = RandomForestClassifier(n_estimators=100, random_state=42)
model = SVC(kernel="rbf", C=1.0, probability=True)
model = XGBClassifier(n_estimators=100, learning_rate=0.1)

# Regresión
model = RandomForestRegressor(n_estimators=100, random_state=42)
model = SVR(kernel="rbf", C=1.0)
model = XGBRegressor(n_estimators=100, learning_rate=0.1)
```

## Pipelines

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer

numeric_features = ["age", "income"]
categorical_features = ["city", "gender"]

preprocessor = ColumnTransformer(
    transformers=[
        ("num", StandardScaler(), numeric_features),
        ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features),
    ]
)

pipeline = Pipeline([
    ("preprocessor", preprocessor),
    ("classifier", RandomForestClassifier(n_estimators=100)),
])

pipeline.fit(X_train, y_train)
predictions = pipeline.predict(X_test)
```

## Métricas

```python
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, classification_report, roc_auc_score,
    mean_squared_error, mean_absolute_error, r2_score,
)

# Clasificación
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, average="weighted")
recall = recall_score(y_test, y_pred, average="weighted")
f1 = f1_score(y_test, y_pred, average="weighted")
cm = confusion_matrix(y_test, y_pred)
print(classification_report(y_test, y_pred))

# Regresión
mse = mean_squared_error(y_test, y_pred)
mae = mean_absolute_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)
```

## Cross-validation

```python
from sklearn.model_selection import cross_val_score, KFold, StratifiedKFold

# Clasificación (estratificado)
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=cv, scoring="accuracy")
print(f"Accuracy: {scores.mean():.4f} ± {scores.std():.4f}")

# Regresión
cv = KFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(model, X, y, cv=cv, scoring="neg_mean_squared_error")
print(f"MSE: {-scores.mean():.4f} ± {scores.std():.4f}")
```

## Baseline

```python
from sklearn.dummy import DummyClassifier, DummyRegressor

# Clasificación: predecir la clase más frecuente
baseline = DummyClassifier(strategy="most_frequent")
baseline.fit(X_train, y_train)
baseline_score = baseline.score(X_test, y_test)

# Regresión: predecir la media
baseline = DummyRegressor(strategy="mean")
baseline.fit(X_train, y_train)
baseline_pred = baseline.predict(X_test)
baseline_mse = mean_squared_error(y_test, baseline_pred)

# Comparar
print(f"Baseline MSE: {baseline_mse:.4f}")
print(f"Modelo MSE:   {model_mse:.4f}")
print(f"Mejora:       {baseline_mse - model_mse:.4f}")
```

## Feature importance

```python
# Random Forest / XGBoost
importances = model.feature_importances_
feature_names = X.columns
sorted_idx = importances.argsort()[::-1]

for idx in sorted_idx[:10]:
    print(f"{feature_names[idx]}: {importances[idx]:.4f}")
```