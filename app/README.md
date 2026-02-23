# Facturación — App Flutter

Cliente Flutter del sistema de facturación. Login con selección de sucursal, menú lateral (Facturas, Clientes, Productos, Categorías, Sucursales) e integración con la API del backend.

## Requisitos

- Flutter SDK ^3.10.0  
- Backend API en ejecución (ver [backend/README.md](../backend/README.md))

## Configuración

### Variables de entorno

Copia el ejemplo y ajusta según tu entorno:

```bash
cp .env.example .env
```

En `.env`:

```env
# Entorno: dev | prod
ENV=dev

# URL de la API (dev)
BASE_URL_DEV=http://localhost:3000

# URL de la API (producción)
BASE_URL_PROD=https://tu-api.example.com
```

- **Desktop/Web**: `BASE_URL_DEV=http://localhost:3000` suele ser correcto.
- **Android emulador**: usa `BASE_URL_DEV=http://10.0.2.2:3000`.
- **Dispositivo físico**: usa la IP de tu máquina, por ejemplo `BASE_URL_DEV=http://192.168.1.x:3000`.

El archivo `.env` está declarado en `pubspec.yaml` como asset; no subas claves ni datos sensibles.

## Ejecución

```bash
flutter pub get
flutter run
```

En modo debug, al arrancar se comprueba que el backend esté accesible en la URL configurada.

## Estructura del proyecto

Arquitectura por capas (features) con inyección de dependencias (GetIt) y enrutamiento (GoRouter).

```
lib/
├── app.dart                 # MaterialApp + tema + router
├── main.dart                # Inicialización: dotenv, DI, health check, router
├── router.dart              # Rutas: /login, /home/* (facturas, clientes, productos, etc.)
├── injection.dart           # Registro de servicios y BLoCs (GetIt)
├── core/
│   ├── constants/           # ApiConstants (baseUrl, timeouts, paths)
│   ├── network/             # ApiClient (Dio), BranchInterceptor (X-Branch-Id)
│   ├── theme/               # AppTheme
│   └── utils/
├── features/
│   ├── auth/                # Login, sesión, sucursales (branch), JWT
│   │   ├── data/            # datasources, models, repositories
│   │   ├── domain/          # entities, repositories, usecases
│   │   └── presentation/    # login_view, login_form, auth_bloc
│   ├── home/                # Shell con drawer/sidebar, menú, placeholder views
│   │   └── presentation/    # home_shell_view, app_drawer, sidebar_menu, home_menu_entries
│   └── products/            # Listado y alta de productos (ítems por sucursal)
│       ├── data/
│       ├── domain/
│       └── presentation/    # products_view, products_bloc, product_list, product_form
```

### Rutas principales

| Ruta | Descripción |
|------|-------------|
| `/login` | Inicio de sesión y selección de sucursal |
| `/home/facturas` | Facturas (placeholder) |
| `/home/clientes` | Clientes (placeholder) |
| `/home/productos` | Productos (listado y creación) |
| `/home/categorias` | Categorías (placeholder) |
| `/home/sucursales` | Sucursales (placeholder) |

Tras el login, las peticiones a la API que requieren sucursal envían el header `X-Branch-Id` (BranchInterceptor) con la sucursal seleccionada.

## Dependencias principales

- **go_router** — Enrutamiento y redirección según estado de autenticación  
- **flutter_bloc** — Estado (AuthBloc, ProductsBloc, etc.)  
- **get_it** — Inyección de dependencias  
- **dio** — Cliente HTTP hacia la API  
- **flutter_secure_storage** — Almacenamiento seguro del token/sesión  
- **flutter_dotenv** — Carga de `.env`  
- **equatable** — Igualdad en entidades y estados  

## Tests

```bash
flutter test
```

## Recursos Flutter

- [Documentación Flutter](https://docs.flutter.dev/)
- [Lab: Primer app Flutter](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
