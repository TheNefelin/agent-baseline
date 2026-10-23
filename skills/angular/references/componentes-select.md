# Selects y resolución de modelos

> Detalle de la subsección **Selects** de la skill `angular`. Aplica a selects de catálogo, listas de seleccionados y formularios con relaciones.

## Select de catálogo

- Emite el **modelo completo**: `selectedItem = output<FeatureModel | null>()` (`null` al limpiar).
- Carga sus opciones con su propio recurso (`httpResource` o `rxResource`) y no delega esa carga al padre.
- Inputs: `selectedId` (`number | undefined`, sin default numérico) para preseleccionar y `clearTrigger` (`number`) para resetear la selección visual.
- Emitir el modelo evita que el consumidor haga un segundo fetch para resolver `id → modelo` y elimina el contrato ambiguo.

```ts
readonly selectedId = input<number | undefined>(undefined);
readonly clearTrigger = input<number>(0);
readonly selectedItem = output<FeatureModel | null>();
```

## Lista de seleccionados

- Recibe `input<FeatureModel[]>([])` (default vacío).
- Emite `delete = output<FeatureModel>()`, sin prefijo `on`.
- El handler interno hace `event.preventDefault()` y `event.stopPropagation()` antes de emitir para no disparar el submit del formulario contenedor.

## Consumo en el formulario

```ts
protected addRelated(item: FeatureModel | null): void {
  if (!item) return;
  this.formData.update((data) => ({ ...data, related: [...(data.related ?? []), item] }));
}
```

- En creación la lista vive solo en `formData` (aún no hay filas puente); en edición, borrar un elemento persiste de inmediato. La página distingue con `isEditMode()`.

## Reglas

- Nunca emitir solo el id: obliga al padre a re-consultar el catálogo.
- `clearTrigger` no se usa como reset del formulario completo; para eso está `linkedSignal`.
- Un select que filtra un listado reemite el filtro como output y la página reinicia `currentPage` a 1.
