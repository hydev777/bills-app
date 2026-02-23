# Bills — Facturación

Sistema de facturación multi-sucursal: aplicación Flutter (cliente) y API Node.js con PostgreSQL.

## Estructura del proyecto

```
bills/
├── app/          # Cliente Flutter (Facturación)
├── backend/      # API Node.js + Express, PostgreSQL, migraciones Flyway
└── README.md     # Este archivo
```

| Parte      | Descripción |
|-----------|-------------|
| **app**   | App Flutter: login con selección de sucursal, menú (Facturas, Clientes, Productos, Categorías, Sucursales), integración con la API. Ver [app/README.md](app/README.md). |
| **backend** | API REST para facturas, ítems, clientes, sucursales, usuarios y privilegios. Ver [backend/README.md](backend/README.md). |

## Requisitos

- **Cliente**: [Flutter](https://flutter.dev) (SDK ^3.10.0)
- **Backend**: [Docker](https://www.docker.com/) y Docker Compose (recomendado), o Node.js 18+ y PostgreSQL 15

## Inicio rápido

### 1. Backend (API + base de datos)

```bash
cd backend
cp api/.env.example api/.env
# Ajustar .env si es necesario (JWT_SECRET, contraseña DB, etc.)
docker-compose up -d
```

- API: http://localhost:3000  
- Health: http://localhost:3000/health  

### 2. App Flutter

```bash
cd app
cp .env.example .env
# En .env: ENV=dev, BASE_URL_DEV=http://localhost:3000 (o la URL de tu API)
flutter pub get
flutter run
```

Por defecto la app usa `http://localhost:3000` en desarrollo. Para Android emulator usa `BASE_URL_DEV=http://10.0.2.2:3000`.

## Documentación

- [App Flutter](app/README.md) — configuración, estructura y ejecución del cliente.
- [Backend](backend/README.md) — API, modelos, migraciones, Docker y comandos de desarrollo.

## Licencia

MIT.
