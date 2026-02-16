# Sistema de facturación básico – Estado actual

Este documento describe qué tiene hoy el proyecto y qué suele considerarse parte de un **sistema de facturación básico**, para que puedas ver si te basta o qué te falta.

**Alcance actual:** alcance por **sucursal (branch)**; no hay tabla de organizaciones. Usuarios y sucursales son globales; facturas, ítems y categorías pertenecen a una sucursal.

---

## Lo que ya tienes implementado

| Funcionalidad | Estado | Detalle |
|---------------|--------|---------|
| **Usuarios y autenticación** | ✅ | Registro, login, JWT. Login por sucursal (`login-branch`). |
| **Facturas (bills)** | ✅ | Crear, editar, listar, eliminar. Título, descripción. Por sucursal (header `X-Branch-Id`). |
| **Usuario creador** | ✅ | Cada factura guarda quién la creó (`user_id`). |
| **ID único por factura** | ✅ | `publicId` (UUID) para identificar la factura sin exponer el ID interno. |
| **Cliente / destinatario** | ✅ | Tabla `clients` (global). Factura tiene `client_id` opcional; si es null = factura “al contado”. |
| **Estado de la factura** | ✅ | Estados: `draft`, `issued`, `paid`, `cancelled`. Por defecto `draft`. |
| **Catálogo de productos/servicios** | ✅ | Items por sucursal, con nombre, precio unitario, categorías e **ITBIS** (tasa por ítem). |
| **Líneas de factura** | ✅ | Añadir ítems a una factura con cantidad, precio unitario y total por línea. |
| **Total de la factura = líneas** | ✅ | `subtotal`, `tax_amount` (ITBIS) y `amount` (total) se **recalculan automáticamente** al añadir, editar o quitar líneas. No se envían a mano. |
| **Desglose de impuestos** | ✅ | A nivel factura: `subtotal`, `tax_amount`, `amount`. El ITBIS se calcula por línea según la tasa del ítem. |
| **Datos fiscales emisor** | ✅ | Sucursal (branch) tiene **`tax_id`** opcional (RNC/CIF/NIF) para imprimir en la factura. |
| **Datos fiscales cliente** | ✅ | Cliente tiene **`tax_id`** opcional (identificador fiscal del comprador). |
| **Sucursales y permisos** | ✅ | Branches, privilegios por recurso, privilegio `all` (acceso a cualquier sucursal). |
| **Estadísticas** | ✅ | Resúmenes de facturas, ítems, categorías. |

Con esto puedes:
- Dar de alta usuarios y sucursales.
- Crear facturas por sucursal, asignar cliente (opcional) e ítems con cantidades y precios.
- Ver totales y desglose (subtotal, impuesto, total) siempre alineados con las líneas.
- Usar datos fiscales (tax_id) de sucursal y cliente para la factura.

---

## Lo que aún falta para un “básico completo” o uso real

| Funcionalidad | Estado actual | Comentario |
|---------------|----------------|------------|
| **Número de factura legible** | ⚠️ Parcial | Existe `publicId` (UUID), pero no un número secuencial por sucursal (ej. `FAC-2025-0001`) para referencia humana y legal. |
| **Fecha de factura / vencimiento** | ⚠️ Parcial | Solo `created_at` / `updated_at`; no hay campo “fecha de factura” ni “fecha de vencimiento”. |
| **Comprobante imprimible / PDF** | ❌ No existe | No hay endpoint ni servicio para generar la factura en PDF o vista para imprimir. |
| **Frontend** | ❌ No existe | La app Flutter es plantilla por defecto; no hay pantallas de facturas, clientes ni flujo de caja. |

---

## Conclusión

- **Para uso interno o pruebas:** lo implementado es suficiente (facturas, líneas, total desde líneas, desglose de impuestos, cliente, estados, datos fiscales emisor y cliente).
- **Para facturación “de verdad” (referencia legal, plazos, entrega al cliente):** faltan número de factura secuencial, fechas de factura/vencimiento, generación de PDF (o impresión) y, para uso sin API, un frontend.

Si quieres, el siguiente paso puede ser: número de factura secuencial por sucursal, fechas en la factura y generación de PDF.
