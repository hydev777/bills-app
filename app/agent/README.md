# Agente Flutter – Buenas prácticas

Esta carpeta define las convenciones y la estructura que debe seguir el proyecto Flutter. Úsala como referencia para mantener **clean architecture**, **feature-first** y **código limpio**.

## Documento principal

**[flutter-master.md](flutter-master.md)** – Guía unificada: estructura, código limpio y rendimiento en un solo archivo.

## Documentos por tema (opcional)

| Documento | Descripción |
|-----------|-------------|
| [ESTRUCTURA.md](ESTRUCTURA.md) | Estructura actual del proyecto: carpetas, capas y responsabilidades. |
| [CLEAN_CODE.md](CLEAN_CODE.md) | Principios de código limpio en Dart/Flutter. |
| [RENDIMIENTO.md](RENDIMIENTO.md) | Prácticas de buen rendimiento en Flutter. |

## Resumen rápido

- **Feature-first**: cada funcionalidad vive en `lib/features/<feature>/`.
- **Clean Architecture**: capas `data` → `domain` → `presentation` dentro de cada feature.
- **Inyección**: `GetIt` en `injection.dart`; registrar datasources, repositories, use cases y BLoCs.
- **Estado**: BLoC/Cubit para lógica de presentación; eventos y estados inmutables.
- **Resultado/errores**: `Result<T, Failure>` en dominio; no propagar excepciones crudas a la UI.
- **DRY**: no código repetido; extraer widgets y lógica reutilizable.
- **Never nest**: máximo 2–3 niveles de anidación; early return y widgets extraídos.
- **Nombrado**: variables/funciones/clases bien nombradas (camelCase, PascalCase, descriptivos).
- **Widgets en vez de helpers**: usar clases que extiendan `StatelessWidget` para UI reutilizable, no funciones que devuelvan `Widget`.
- **Const**: usar `const` en widgets y literales que no dependan de estado.
- **Rendimiento**: ver [RENDIMIENTO.md](RENDIMIENTO.md) (listas lazy, buildWhen, keys).

Cuando añadas o modifiques código, sigue la estructura y las guías de esta carpeta.
