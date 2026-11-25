# Referencia: Anti-patrones en ML

## 1. Predecir aleatoriedad

**Problema**: Entrenar un modelo para predecir resultados de lotería, dados, ruleta.

**Por qué falla**: No hay señal predictiva. El modelo memoriza ruido (overfitting) y es peor que el baseline.

**Señal de alerta**: El modelo tiene loss alto en validación pero bajo en train. El baseline (predecir el promedio) tiene mejor score.

**Solución**: Verificar señal predictiva antes de entrenar. Si el baseline es mejor, no entrenar.

## 2. Data leakage

**Problema**: Usar información del futuro para predecir el pasado.

**Ejemplos**:
- Normalizar con estadísticas del dataset completo (incluyendo test)
- Usar features que solo existen después del evento a predecir
- No respetar orden temporal en series de tiempo

**Solución**: Fit scaler solo en train. Respetar orden temporal. Revisar correlaciones sospechosas.

## 3. Scaler por columna

**Problema**: `MinMaxScaler` fit en `(N, 6)` normaliza cada columna independientemente.

**Por qué falla**: Si todas las columnas tienen el mismo rango (1-41), el scaler debería ser global. Por columna, cada feature tiene su propia escala, lo que distorsiona la relación.

**Solución**: Fit en datos aplanados: `scaler.fit(data.reshape(-1, 1))`.

## 4. Evaluar en train

**Problema**: Reportar métricas sobre los datos de entrenamiento.

**Por qué falla**: El modelo ya vio esos datos. El score es optimista y no generaliza.

**Solución**: Usar cross-validation o un test set separado. Nunca evaluar en train.

## 5. Sin baseline

**Problema**: No comparar contra un modelo trivial (predecir el promedio, la moda).

**Por qué falla**: No sabes si tu modelo mejora sobre lo más simple posible.

**Solución**: Siempre calcular baseline. Si el modelo no supera al baseline, no sirve.

## 6. Sin reproducibilidad

**Problema**: No fijar seeds. Los resultados cambian entre ejecuciones.

**Solución**: Fijar `random.seed`, `np.random.seed`, `tf.random.set_seed`. Documentar la seed.

## 7. Overfitting

**Problema**: El modelo memoriza los datos de entrenamiento.

**Señales**: train_loss << val_loss, gap grande entre train y val score.

**Soluciones**: EarlyStopping, Dropout, regularización L2, más datos, menos complejidad.

## 8. Formato legacy (.h5)

**Problema**: Usar `model.save('modelo.h5')` en Keras 3.

**Por qué evitarlo**: Deprecated. El formato nativo es `.keras`.

**Solución**: Usar `model.save('modelo.keras')`.

## 9. Capas redundantes

**Problema**: Agregar capas sin justificación (ej. `Dense(12, relu)` entre `Dense(64)` y `Dense(6)`).

**Por qué evitarlo**: Aumenta complejidad sin beneficio. Más parámetros = más overfitting.

**Solución**: Cada capa debe tener una justificación. Si no mejora, eliminarla.

## 10. Código muerto

**Problema**: Métodos/funciones que nunca se llaman (`fit_all`, `format_predictions`).

**Por qué evitarlo**: Confunde, aumenta mantenimiento, oculta bugs.

**Solución**: Eliminar. Si se necesita en el futuro, se recupera de git.