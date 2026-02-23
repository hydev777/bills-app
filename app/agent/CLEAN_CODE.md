# Código limpio en Dart/Flutter

Principios aplicados al proyecto: DRY, never nest, nombrado claro, funciones y widgets acotados. Para uso de `const` y rendimiento, ver [RENDIMIENTO.md](RENDIMIENTO.md).

## DRY (Don't Repeat Yourself)

- No copies y pegues bloques de código. Si la misma lógica o el mismo fragmento de UI aparece en varios sitios, extrae:
  - **UI**: un widget con nombre descriptivo (clase que extiende `StatelessWidget` o `Widget`), no una función que devuelve `Widget` (ver RENDIMIENTO.md).
  - **Lógica**: un método privado, una función en un archivo de utilidades dentro de la feature, o en `core/` si es transversal.
- Ejemplo de extracción de lógica repetida:

```dart
// Malo: misma validación repetida
if (email.isEmpty || !email.contains('@')) { ... }
// en otro archivo
if (email.isEmpty || !email.contains('@')) { ... }

// Bueno: una función reutilizable
bool isValidEmail(String email) =>
    email.isNotEmpty && email.contains('@');
```

## Never nest

- Mantén como máximo 2–3 niveles de anidación. Si hay más, extrae a método privado o a un widget con nombre que describa la responsabilidad.
- Usa **early return** o **guard clauses**: salir pronto cuando no se cumplan condiciones, para reducir indentación.

```dart
// Malo: anidación profunda
Widget build(BuildContext context) {
  return BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is AuthAuthenticated) {
        return Scaffold(
          body: state.session.accessibleBranches.isEmpty
              ? const EmptyBranchesMessage()
              : ListView.builder(
                  itemCount: state.session.accessibleBranches.length,
                  itemBuilder: (context, index) {
                    final branch = state.session.accessibleBranches[index];
                    return ListTile(
                      title: Text(branch.name),
                      onTap: () => _selectBranch(context, branch.id),
                    );
                  },
                ),
        );
      }
      return const SizedBox.shrink();
    },
  );
}

// Bueno: early return y widgets extraídos
Widget build(BuildContext context) {
  return BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is! AuthAuthenticated) {
        return const SizedBox.shrink();
      }
      final branches = state.session.accessibleBranches;
      if (branches.isEmpty) {
        return const Scaffold(body: EmptyBranchesMessage());
      }
      return _BranchList(
        branches: branches,
        onSelectBranch: (id) => _selectBranch(context, id),
      );
    },
  );
}
```

## Nombrado

- **Variables y parámetros**: `camelCase`, descriptivos. Evitar abreviaturas no obvias (`usr` → `user`, `btn` → `button` cuando no sea evidente).
- **Funciones y métodos**: verbo o pregunta clara: `getSession()`, `isValid()`, `saveUser()`, `hasAccess()`.
- **Clases y widgets**: `PascalCase`: `AuthBloc`, `LoginForm`, `ProductListItem`.
- **Constantes**: `lowerCamelCase` o `SCREAMING_SNAKE_CASE` según la convención del proyecto (en Dart suele usarse `lowerCamelCase` para const).
- **Archivos**: snake_case, coherentes con el contenido: `auth_repository.dart`, `login_view.dart`, `product_form_widget.dart`.

```dart
// Malo
final d = DateTime.now();
bool chk(String s) => s.length > 5;
class ProdList extends StatelessWidget { ... }

// Bueno
final now = DateTime.now();
bool hasMinLength(String text) => text.length > 5;
class ProductListWidget extends StatelessWidget { ... }
```

## Tamaño y responsabilidad única

- Funciones y métodos: cortos; si un método hace varias cosas, dividir o extraer.
- Widgets: una responsabilidad clara; si `build` es muy largo, extraer subwidgets con nombre.
- Archivos: si un archivo crece mucho (p. ej. > 200–300 líneas), valorar dividir por responsabilidad (p. ej. varios widgets en archivos separados dentro de `widgets/`).

## Const

- Usa `const` en constructores de widgets y en literales que no dependan de estado cuando sea posible. Reduce rebuilts y ayuda al rendimiento. Detalle en [RENDIMIENTO.md](RENDIMIENTO.md).
