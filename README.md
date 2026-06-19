# Bills - Facturacion

Aplicacion Flutter de facturacion local. La app incluye una API HTTP embebida con Shelf y una base SQLite persistente, por lo que no requiere servicios externos.

## Estructura del proyecto

```text
bills/
|-- app/          # Aplicacion Flutter local
`-- README.md     # Este archivo
```

## Requisitos

- Flutter SDK ^3.10.0

## Inicio rapido

```bash
cd app
flutter pub get
flutter run
```

Al iniciar, la app levanta automaticamente la API local y crea/actualiza la base SQLite persistente.

## Primer acceso

Si no hay usuarios, la pantalla inicial permite crear el primer administrador local. Luego puedes iniciar sesion con el usuario y contrasena creados.

## Funcionalidades

- Facturas y ventas
- Productos, categorias e ITBIS
- Clientes
- Usuarios locales y roles
- Autenticacion local con token

## Documentacion

- [App Flutter](app/README.md) - configuracion, estructura y ejecucion del cliente local.

## Licencia

MIT.
