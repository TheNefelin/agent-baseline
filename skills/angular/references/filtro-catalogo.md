# Listado paginado con filtro por catálogo

> Detalle de la subsección **Listados** de la skill `angular`. Aplica a listados filtrados por un estado o catálogo (estados de una entidad, categorías, tipos).

## Payload propio de la página

```ts
protected readonly filterPayload = computed(() => ({
  page: this.currentPage(),
  limit: this.limit(),
  search: this.search(),
  filter: { idStatus: this.selectedStatusId() },
}));
```

- Se declara **privado por página**, no se sobrescribe el payload base: si el base es `PaginationRequestModel<null>` y el de la página es `PaginationRequestModel<StatusFilter>`, la varianza de `Signal<T>` produce **TS2416** (`computed<...<StatusFilter>>` no es asignable a `computed<...<null>>`).
- El filtro viaja tipado por feature, no como `string` suelto.

## Sentinel `0 = todos`

- `selectedStatusId = signal<number>(0)`; el servicio omite números `<= 0` al construir la query, así que `0` significa "sin filtro" sin ramas extra.
- El select emite el modelo completo y la página recibe el modelo:

```ts
protected onFilterByStatus(status: StatusModel | null): void {
  this.selectedStatusId.set(status?.idStatus ?? 0);
  this.currentPage.set(1);          // todo cambio de filtro vuelve a la página 1
}
```

## Stream puro

```ts
protected readonly listRX = rxResource({
  params: () => this.filterPayload(),
  stream: ({ params }) => {
    if (!params) return of(null);
    return this.featureService.getAllPagination(params).pipe(
      map((response) => this.mapPaginated(response)),
      catchError((err) => {
        console.error('[FeaturePage] getAllPagination:', err);
        return of(this.emptyPaginated());
      }),
    );
  },
});
```

- Los efectos de paginación (`totalPages.set()`, `currentPage`) viven **solo** en `mapPaginated`/`emptyPaginated`. Dentro del `map` quedan stale cuando la request falla.
- El `catchError` devuelve un payload vacío, no `throwError`: el listado se ve vacío y el error ya lo mostró el interceptor.

## List presentacional

El componente de tabla no filtra ni consulta: recibe datos y reemite el filtro.

```ts
readonly selectedStatus = output<StatusModel | null>();
```

```html
<app-status-select-component
  [selectedId]="selectedStatusId()"
  (selectedItem)="selectedStatus.emit($event)" />
```
