# Bills - Facturacion

Sistema de facturacion multi-sucursal: aplicacion Flutter (cliente) y API Node.js con PostgreSQL.

## Estructura del proyecto

```text
bills/
|-- app/          # Cliente Flutter (Facturacion)
|-- backend/      # API Node.js + Express, PostgreSQL, migraciones Flyway
`-- README.md     # Este archivo
```

| Parte | Descripcion |
|------|-------------|
| **app** | App Flutter: integracion con la API y modo local branchless. Ver [app/README.md](app/README.md). |
| **backend** | API REST para facturas, items, clientes, sucursales, usuarios y privilegios. Ver [backend/README.md](backend/README.md). |

## Requisitos

- **Cliente**: [Flutter](https://flutter.dev) (SDK ^3.10.0)
- **Backend**: [Docker](https://www.docker.com/) y Docker Compose (recomendado), o Node.js 18+ y PostgreSQL 15

## Inicio rapido

### 1. Backend (API + base de datos)

```bash
cd backend
cp api/.env.example api/.env
# Ajustar .env si es necesario (JWT_SECRET, contrasena DB, etc.)
docker-compose up -d
```

- API: http://localhost:3000
- Health: http://localhost:3000/health

### 2. App Flutter con backend externo

```bash
cd app
cp .env.example .env
# En .env: ENV=dev, BASE_URL_DEV=http://localhost:3000
flutter pub get
flutter run
```

Por defecto la app usa `http://localhost:3000` en desarrollo. Para Android emulator usa `BASE_URL_DEV=http://10.0.2.2:3000`.

### 3. App Flutter en modo local

La app tambien puede ejecutarse sin backend externo usando una API local embebida con SQLite, sin sucursales:

```bash
cd app
cp .env.example .env
# En .env: ENV=local
flutter pub get
flutter run
```

Credenciales sembradas para el modo local:

- `admin@bills.local` / `Password123`
- `cajero@bills.local` / `Password123`
- `vendedor@bills.local` / `Password123`

## Documentacion

- [App Flutter](app/README.md) - configuracion, estructura y ejecucion del cliente.
- [Backend](backend/README.md) - API, modelos, migraciones, Docker y comandos de desarrollo.

## Licencia

MIT.
