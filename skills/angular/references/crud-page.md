# Listados paginados y estado agrupado

> Detalle de la sección **Listados** de la skill `angular`. Dos formas de reutilizar paginación: composición (default) y herencia (alternativa).

## Composición (default)

```ts
// shared/base/pagination-state.ts
export class PaginationState {
  readonly currentPage = signal(1);
  readonly limit = signal<number>(10);
  readonly search = signal('');
  readonly totalPages = signal(0);

  readonly payload = computed(() => ({
    page: this.currentPage(),
    limit: this.limit(),
    search: this.search(),
  }));

  nextPage(): void { ... }
  prevPage(): void { ... }
  onFilterChange(filter: { search: string; limit: number }): void { ... }
  onRefreshClick(): void { ... }
}
```

```ts
// en la página
protected readonly pagination = inject(PaginationState);
protected readonly listRX = rxResource({
  params: () => this.pagination.payload(),
  stream: ({ params }) => this.featureService.getAll(params),
});
```

Ventaja: se testea sin `TestBed`, no acopla features a una clase base y permite dos páginas con estados independientes.

## Herencia (alternativa)

```ts
export abstract class CrudPage<TModel> {
  protected readonly totalPages = signal(0);
  protected readonly currentPage = signal(1);
  protected readonly limit = signal<number>(10);
  protected readonly search = signal('');

  protected readonly getAllPayload = computed(() => ({
    page: this.currentPage(),
    limit: this.limit(),
    search: this.search(),
  }));

  abstract reload(): void;
}
```

Se justifica solo si todas las páginas son idénticas y el equipo ya la usa. Costo: acoplamiento y test más difícil; al especializar el payload aparece TS2416 por la varianza de `Signal<T>` (ver `filtro-catalogo.md`).

## Estado agrupado por feature

Objeto plano con signals y computed, nunca signals sueltas:

```ts
protected readonly feature = {
  dataList:     computed<FeatureModel[]>(() => this.listRX.value() ?? []),
  isLoading:    computed<boolean>(() => this.listRX.isLoading()),
  isSaving:     signal<boolean>(false),
  showModal:    signal<boolean>(false),
  selectedItem: signal<FeatureModel | null>(null),
};
```

Convención de handlers: `onCreate*`, `onEdit*`, `onDelete*`, `onClear*` (cierra y limpia `selectedItem`) y `onSubmit*` (desestructura `{ id, data }` y delega en el servicio de mutaciones).
