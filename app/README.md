# Facturacion - App Flutter

Cliente Flutter local para facturacion. La app levanta una API HTTP embebida con Shelf y usa SQLite como almacenamiento persistente.

## Requisitos

- Flutter SDK ^3.10.0

## Ejecucion

```bash
flutter pub get
flutter run
```

No hace falta configurar variables de entorno ni levantar servicios externos. En el arranque se inicia la API local y se registra su URL en el cliente Dio.

## Primer acceso

Cuando no existen usuarios, la app muestra el formulario para crear el primer administrador local. Despues de crearlo, inicia sesion con ese usuario y contrasena.

## Estructura del proyecto

Arquitectura por capas con features, inyeccion de dependencias con GetIt y enrutamiento con GoRouter.

```text
lib/
|-- app.dart                 # MaterialApp + tema + router
|-- main.dart                # Inicializacion de API local, DI y router
|-- router.dart              # Rutas: /login, /home/*
|-- injection.dart           # Registro de servicios y BLoCs
|-- core/
|   |-- constants/           # ApiConstants
|   |-- local_api/           # API local embebida, auth y SQLite
|   |-- network/             # Dio, auth interceptor y health local
|   |-- theme/               # AppTheme
|   `-- utils/
`-- features/
    |-- auth/                # Login, sesion local y bootstrap admin
    |-- home/                # Shell con sidebar/menu
    |-- products/            # Productos, categorias e ITBIS
    |-- clients/             # Clientes
    |-- bills/               # Facturas
    |-- sales/               # Venta mostrador
    `-- users/               # Usuarios locales
```

## Rutas principales

| Ruta | Descripcion |
|------|-------------|
| `/login` | Inicio de sesion y creacion del primer administrador |
| `/home/facturas` | Facturas |
| `/home/clientes` | Clientes |
| `/home/productos` | Productos |
| `/home/categorias` | Categorias |
| `/home/venta` | Venta mostrador |
| `/home/usuarios` | Usuarios locales, solo administradores |

## Dependencias principales

- **go_router** - Enrutamiento y redireccion segun autenticacion
- **flutter_bloc** - Estado de features
- **get_it** - Inyeccion de dependencias
- **dio** - Cliente HTTP hacia la API embebida
- **flutter_secure_storage** - Almacenamiento seguro del token/sesion
- **equatable** - Igualdad en entidades y estados
- **shelf / shelf_router** - API HTTP local embebida
- **sqlite3 / sqlite3_flutter_libs** - Persistencia local

## Tests

```bash
flutter test
```
