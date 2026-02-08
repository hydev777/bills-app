# Sistema de facturación básico – Estado actual

Este documento describe qué tiene hoy el proyecto y qué suele considerarse parte de un **sistema de facturación básico**, para que puedas ver si te basta o qué te falta.

---

## Lo que ya tienes (y es suficiente para algo muy básico)

| Funcionalidad | Estado | Detalle |
|---------------|--------|---------|
| **Organizaciones** | ✅ | Varios negocios (tenancy) en la misma app. |
| **Usuarios y autenticación** | ✅ | Registro, login, JWT. |
| **Facturas (bills)** | ✅ | Crear, editar, listar, eliminar. Título, descripción, monto. |
| **Usuario creador** | ✅ | Cada factura guarda quién la creó (`user_id`). |
| **ID único por factura** | ✅ | `publicId` (UUID) para identificar la factura sin exponer el ID interno. |
| **Catálogo de productos/servicios** | ✅ | Items con nombre, precio unitario, categorías. |
| **Líneas de factura** | ✅ | Añadir ítems a una factura con cantidad, precio unitario y total por línea. |
| **Totales por factura** | ✅ | Se puede obtener el total calculado desde las líneas (`/api/bill-items/bill/:bill_id` devuelve `calculated_total`). |
| **Sucursales y permisos** | ✅ | Branches y privilegios por recurso. |
| **Estadísticas** | ✅ | Resúmenes de facturas, ítems, etc. |

Con esto puedes:
- Dar de alta usuarios y organizaciones.
- Crear facturas y asignarles ítems con cantidades y precios.
- Saber quién creó cada factura y tener un identificador único.
- Consultar totales a partir de las líneas.

---

## Lo que suele faltar para un “sistema de facturación básico” completo

En muchos entornos, un sistema de facturación básico incluye además:

| Funcionalidad | Estado actual | Comentario |
|---------------|----------------|------------|
| **Cliente / destinatario** | ❌ No existe | No hay entidad “cliente” (nombre, NIF/RFC, dirección). La factura solo tiene título/descripción y usuario creador. |
| **Número de factura legible** | ⚠️ Parcial | Existe `publicId` (UUID), pero no un número secuencial tipo `FAC-2025-0001` por organización. |
| **Estado de la factura** | ✅ Implementado | Estados: `draft`, `issued`, `paid`, `cancelled`. Por defecto `draft`. |
| **Fecha de factura / vencimiento** | ⚠️ Parcial | Solo `created_at`; no hay “fecha de factura” ni “fecha de vencimiento” explícitas. |
| **Impuestos (IVA, etc.)** | ❌ No existe | No hay campo de IVA ni desglose subtotal / impuestos / total. |
| **Datos del emisor** | ⚠️ Parcial | La organización solo tiene `name`. No hay dirección fiscal, RFC/CIF, etc. para imprimir en la factura. |
| **Total de la factura vs. líneas** | ⚠️ A revisar | El `amount` de la factura se envía manualmente al crear/actualizar; no se recalcula solo con las líneas. Puede haber diferencia con la suma de `bill_items`. |

---

## Conclusión

- **Para uso interno o pruebas**: lo que hay puede ser suficiente (facturas, ítems, líneas, total calculado, usuario creador, ID único).
- **Para facturación “de verdad” (clientes, numeración, estados, impuestos, impresión/PDF)**: faltan clientes, número de factura, estado, y opcionalmente fechas, IVA y datos fiscales del emisor.

Si quieres, el siguiente paso puede ser diseñar e implementar solo lo mínimo que te falte (por ejemplo: clientes, número de factura y estado).
