# Facturacion - App Flutter

Cliente Flutter del sistema de facturacion. Integra la API del backend en modo remoto y una API SQLite embebida en modo local branchless.

## Requisitos

- Flutter SDK ^3.10.0
- Backend API en ejecucion para `ENV=dev` o `ENV=prod` (ver [backend/README.md](../backend/README.md))

## Configuracion

### Variables de entorno

Copia el ejemplo y ajusta segun tu entorno:

```bash
cp .env.example .env
```

En `.env`:

```env
# Entorno: local | dev | prod
ENV=dev

# URL de la API (dev)
BASE_URL_DEV=http://localhost:3000

# URL de la API (produccion)
BASE_URL_PROD=https://tu-api.example.com
```

- **Modo local**: usa `ENV=local` para levantar una API embebida con SQLite dentro de la app.
- **Desktop/Web**: `BASE_URL_DEV=http://localhost:3000` suele ser correcto.
- **Android emulador**: usa `BASE_URL_DEV=http://10.0.2.2:3000`.
- **Dispositivo fisico**: usa la IP de tu maquina, por ejemplo `BASE_URL_DEV=http://192.168.1.x:3000`.

En `ENV=local` no hace falta backend externo. La app crea una base SQLite persistente y expone una API HTTP local solo para el cliente. Credenciales sembradas:

- `admin@bills.local` / `Password123`
- `cajero@bills.local` / `Password123`
- `vendedor@bills.local` / `Password123`

El archivo `.env` esta declarado en `pubspec.yaml` como asset; no subas claves ni datos sensibles.

## Ejecucion

```bash
flutter pub get
flutter run
```

En modo debug, al arrancar se comprueba que el backend este accesible en la URL configurada cuando `ENV=dev`.

## Estructura del proyecto

Arquitectura por capas (features) con inyeccion de dependencias (GetIt) y enrutamiento (GoRouter).

```text
lib/
|-- app.dart                 # MaterialApp + tema + router
|-- main.dart                # Inicializacion: dotenv, DI, health check, router
|-- router.dart              # Rutas: /login, /home/* (facturas, clientes, productos, etc.)
|-- injection.dart           # Registro de servicios y BLoCs (GetIt)
|-- core/
|   |-- constants/           # ApiConstants (baseUrl, timeouts, paths)
|   |-- local_api/           # API local embebida, auth y SQLite
|   |-- network/             # ApiClient (Dio), BranchInterceptor remoto
|   |-- theme/               # AppTheme
|   `-- utils/
`-- features/
    |-- auth/                # Login, sesion, sucursales (branch), JWT
    |   |-- data/            # datasources, models, repositories
    |   |-- domain/          # entities, repositories, usecases
    |   `-- presentation/    # login_view, login_form, auth_bloc
    |-- home/                # Shell con drawer/sidebar, menu, placeholder views
    |   `-- presentation/    # home_shell_view, app_drawer, sidebar_menu, home_menu_entries
    |-- products/            # Listado y alta de productos (items por sucursal)
    |   |-- data/
    |   |-- domain/
    |   `-- presentation/    # products_view, products_bloc, product_list, product_form
    |-- clients/
    |-- bills/
    `-- sales/
```

### Rutas principales

| Ruta | Descripcion |
|------|-------------|
| `/login` | Inicio de sesion y seleccion de sucursal |
| `/home/facturas` | Facturas |
| `/home/clientes` | Clientes |
| `/home/productos` | Productos |
| `/home/categorias` | Categorias |
| `/home/sucursales` | Sucursales (solo remoto) |

En modo remoto, las peticiones que requieren sucursal envian el header `X-Branch-Id` (BranchInterceptor) con la sucursal seleccionada. En `ENV=local` no existe concepto de sucursal.

## Dependencias principales

- **go_router** - Enrutamiento y redireccion segun estado de autenticacion
- **flutter_bloc** - Estado (AuthBloc, ProductsBloc, etc.)
- **get_it** - Inyeccion de dependencias
- **dio** - Cliente HTTP hacia la API
- **flutter_secure_storage** - Almacenamiento seguro del token/sesion
- **flutter_dotenv** - Carga de `.env`
- **equatable** - Igualdad en entidades y estados
- **shelf / shelf_router** - API HTTP local embebida
- **sqlite3 / sqlite3_flutter_libs** - Persistencia local

## Tests

```bash
flutter test
```
