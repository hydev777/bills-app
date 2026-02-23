# Buenas prácticas de rendimiento en Flutter

Reglas accionables para mantener un buen rendimiento en la UI y en el árbol de widgets.

## Widgets en lugar de funciones que devuelven Widget

Las funciones que devuelven `Widget` no crean un `Element` estable en el árbol: Flutter no puede optimizar reutilizando elementos ni puede hacer const. Cualquier pieza de UI reutilizable debe ser una **clase** que extienda `StatelessWidget` (o `Widget` con `Element` propio).

```dart
// Malo: función que devuelve Widget
Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

// Bueno: widget dedicado
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
```

Ventajas del widget: puede ser `const` cuando sus argumentos son constantes, participa correctamente en el árbol de elementos y solo se reconstruye cuando cambian sus parámetros.

## Uso de const

- Usa el constructor `const` en todos los widgets que no dependan de datos variables (textos fijos, iconos, padding, etc.).
- Construye listas y mapas constantes con `const []` o `const {}` cuando el contenido sea constante.
- El compilador puede reutilizar la misma instancia y Flutter evita rebuilds innecesarios en hijos const.

```dart
// Malo: sin const, se recrea en cada rebuild
return Padding(
  padding: const EdgeInsets.all(16),
  child: Text('Título'),
);

// Bueno: widget const cuando no depende de datos variables
return const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Título'),
);
```

En listas de hijos, marca como `const` los widgets que no dependan de datos dinámicos:

```dart
children: [
  const SizedBox(height: 16),
  const Divider(),
  Text(user.name), // no const: depende de user
],
```

## Evitar rebuilds innecesarios

- **Extraer widgets**: si solo una parte de la pantalla depende del estado (p. ej. del BLoC), extrae esa parte a un widget hijo. Así solo ese hijo se reconstruye cuando cambia el estado.
- **BlocBuilder**: usa `buildWhen` para no reconstruir cuando el estado no afecta a la UI que estás mostrando.

```dart
BlocBuilder<AuthBloc, AuthState>(
  buildWhen: (previous, current) =>
      previous.runtimeType != current.runtimeType,
  builder: (context, state) { ... },
)
```

- **BlocSelector**: cuando solo necesites un campo del estado, usa `BlocSelector` para que el builder solo se ejecute cuando ese campo cambie.

## Listas largas

- Usa **ListView.builder**, **GridView.builder** o **CustomScrollView** con slivers lazy en lugar de crear todos los hijos de una vez (evita `ListView(children: items.map(...).toList())` con listas grandes).
- Así solo se construyen los elementos visibles (y un pequeño margen).

```dart
// Malo para muchas items
ListView(children: items.map((e) => ItemTile(e)).toList())

// Bueno
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)
```

## Keys

- Usa `Key` cuando Flutter pueda confundir la identidad de un widget entre frames: listas dinámicas con reordenación, inserción o borrado, o cuando necesites preservar estado (p. ej. formularios dentro de un PageView).
- No abuses: solo cuando haya problemas visibles de estado incorrecto o rendimiento. Preferir `ValueKey` con un id estable (p. ej. `ValueKey(item.id)`).

Resumen: preferir **widgets** a funciones que devuelven Widget, usar **const** siempre que se pueda, **extraer widgets** y **buildWhen/BlocSelector** para limitar rebuilds, y **listas lazy** para listas largas.
