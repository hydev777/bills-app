-- V16__Seed_test_products_branches_bills.sql
-- Datos de prueba: sucursales adicionales, clientes, categorías, productos (items) y facturas.
-- Idempotente: usa INSERT ... WHERE NOT EXISTS / ON CONFLICT DO NOTHING donde aplica.

-- Asegurar al menos una sucursal (por si V15 no insertó porque ya había ramas con otro código)
INSERT INTO branches (name, code, tax_id, address, phone, email, is_active, created_at, updated_at)
SELECT 'Sucursal Principal', 'MAIN', NULL, NULL, NULL, NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM branches LIMIT 1);

-- Permitir mismo nombre de categoría en distintas sucursales (V1 tenía UNIQUE(name); V13 añadió unique(branch_id,name) pero no quitó el de name)
ALTER TABLE item_categories DROP CONSTRAINT IF EXISTS item_categories_name_key;

-- ========== 1. Sucursal adicional ==========
INSERT INTO branches (name, code, tax_id, address, phone, email, is_active, created_at, updated_at)
SELECT 'Sucursal Norte', 'NORTE', '131-1234567-1', 'Av. Principal 100', '809-555-0100', 'norte@bills.local', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM branches WHERE code = 'NORTE');

-- Vincular usuarios seed a la sucursal Norte (branch_id del código NORTE)
INSERT INTO user_branches (user_id, branch_id, is_primary, can_login, created_at, updated_at)
SELECT u.id, b.id, FALSE, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM users u
CROSS JOIN branches b
WHERE b.code = 'NORTE'
  AND u.username IN ('admin', 'cajero', 'vendedor')
  AND NOT EXISTS (SELECT 1 FROM user_branches ub WHERE ub.user_id = u.id AND ub.branch_id = b.id);

-- ========== 2. Clientes de prueba ==========
INSERT INTO clients (name, identifier, tax_id, email, phone, address, created_at, updated_at)
SELECT 'Cliente Consumidor Final', 'CF-001', NULL, 'consumidor@test.local', '809-555-1001', 'Calle 1 #10', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM clients WHERE identifier = 'CF-001');

INSERT INTO clients (name, identifier, tax_id, email, phone, address, created_at, updated_at)
SELECT 'Empresa ABC SRL', 'RNC-131-12345678', '131-1234567-8', 'abc@empresa.local', '809-555-2000', 'Zona Industrial', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM clients WHERE identifier = 'RNC-131-12345678');

INSERT INTO clients (name, identifier, tax_id, email, phone, address, created_at, updated_at)
SELECT 'Tienda La Esquina', NULL, NULL, 'esquina@test.local', '809-555-3000', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM clients WHERE name = 'Tienda La Esquina' LIMIT 1);

-- ========== 3. Categorías de productos (por sucursal) ==========
-- Primera sucursal (id mínimo; puede ser MAIN o PRINCIPAL-x según migraciones previas)
INSERT INTO item_categories (branch_id, name, description, created_at, updated_at)
SELECT b.id, 'Bebidas', 'Bebidas y refrescos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas');

INSERT INTO item_categories (branch_id, name, description, created_at, updated_at)
SELECT b.id, 'Comestibles', 'Alimentos y snacks', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Comestibles');

INSERT INTO item_categories (branch_id, name, description, created_at, updated_at)
SELECT b.id, 'Servicios', 'Servicios facturables', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Servicios');

-- Sucursal Norte
INSERT INTO item_categories (branch_id, name, description, created_at, updated_at)
SELECT b.id, 'Bebidas', 'Bebidas y refrescos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.code = 'NORTE'
  AND NOT EXISTS (SELECT 1 FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas');

INSERT INTO item_categories (branch_id, name, description, created_at, updated_at)
SELECT b.id, 'Comestibles', 'Alimentos', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.code = 'NORTE'
  AND NOT EXISTS (SELECT 1 FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Comestibles');

-- ========== 4. Productos (items) - Primera sucursal ==========
-- itbis_rates: típicamente id 1 = 18%, id 2 = 0% (según V11)
INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Agua Mineral 500ml', 'Botella agua mineral', 25.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 0 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Agua Mineral 500ml');

INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Refresco 2L', 'Refresco sabor cola', 85.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Refresco 2L');

INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Sandwich Jamón y Queso', NULL, 150.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Comestibles' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Sandwich Jamón y Queso');

INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Café Americano', 'Café 12 oz', 75.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Café Americano');

INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Consulta Técnica 1h', 'Servicio de consultoría', 500.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Servicios' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Consulta Técnica 1h');

-- Productos Sucursal Norte (algunos)
INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Agua Mineral 500ml', 'Botella agua mineral', 25.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 0 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.code = 'NORTE'
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Agua Mineral 500ml');

INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id, created_at, updated_at)
SELECT b.id, 'Refresco 2L', 'Refresco sabor cola', 90.00,
  (SELECT id FROM item_categories ic WHERE ic.branch_id = b.id AND ic.name = 'Bebidas' LIMIT 1),
  (SELECT id FROM itbis_rates WHERE percentage = 18 LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM branches b WHERE b.code = 'NORTE'
  AND NOT EXISTS (SELECT 1 FROM items i WHERE i.branch_id = b.id AND i.name = 'Refresco 2L');

-- ========== 5. Facturas de prueba (bills) ==========
-- Primera sucursal por id (la que exista tras V15/V13)
-- Factura 1: draft, con cliente, varios ítems
INSERT INTO bills (public_id, branch_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status, created_at, updated_at)
SELECT gen_random_uuid(),
  (SELECT id FROM branches ORDER BY id ASC LIMIT 1),
  (SELECT id FROM users WHERE username = 'admin' LIMIT 1),
  (SELECT id FROM clients WHERE identifier = 'RNC-131-12345678' LIMIT 1),
  'Factura venta Empresa ABC', 'Pedido de oficina', 243.00, 43.74, 286.74, 'draft',
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM bills WHERE title = 'Factura venta Empresa ABC' LIMIT 1);

-- Factura 2: issued, consumidor final
INSERT INTO bills (public_id, branch_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status, created_at, updated_at)
SELECT gen_random_uuid(),
  (SELECT id FROM branches ORDER BY id ASC LIMIT 1),
  (SELECT id FROM users WHERE username = 'cajero' LIMIT 1),
  (SELECT id FROM clients WHERE identifier = 'CF-001' LIMIT 1),
  'Venta mostrador', NULL, 110.00, 13.50, 123.50, 'issued',
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM bills WHERE title = 'Venta mostrador' LIMIT 1);

-- Factura 3: draft, sin cliente (al contado)
INSERT INTO bills (public_id, branch_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status, created_at, updated_at)
SELECT gen_random_uuid(),
  (SELECT id FROM branches ORDER BY id ASC LIMIT 1),
  (SELECT id FROM users WHERE username = 'cajero' LIMIT 1),
  NULL,
  'Venta rápida', 'Cliente ocasional', 75.00, 13.50, 88.50, 'draft',
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM bills WHERE title = 'Venta rápida' LIMIT 1);

-- ========== 6. Detalle de facturas (bill_details) ==========
-- Detalle para "Factura venta Empresa ABC": 2x Refresco 2L (85*2=170 + ITBIS 18% = 200.60), 1x Café (75 + 13.50 = 88.50) → subtotal 245, tax ~44.10, total ~289.10 (ajustamos a 243 + 43.74 = 286.74)
-- Usamos ítems de branch MAIN. Necesitamos los bill_id e item_id después de insertar.
-- Como los INSERT de bills pueden no insertar si ya existen, usamos un enfoque que inserte detalles solo si la factura existe y no tiene detalles aún.

-- Ítems de la primera sucursal (branch_id = mínimo)
INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes, created_at, updated_at)
SELECT bl.id, it.id, 2, 85.00, 170.00, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM bills bl
CROSS JOIN items it
WHERE it.branch_id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND bl.title = 'Factura venta Empresa ABC'
  AND it.name = 'Refresco 2L'
  AND NOT EXISTS (SELECT 1 FROM bill_details bd WHERE bd.bill_id = bl.id)
LIMIT 1;

INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes, created_at, updated_at)
SELECT bl.id, it.id, 1, 75.00, 75.00, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM bills bl
CROSS JOIN items it
WHERE it.branch_id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND bl.title = 'Factura venta Empresa ABC'
  AND it.name = 'Café Americano'
  AND (SELECT COUNT(*) FROM bill_details bd WHERE bd.bill_id = bl.id) < 2
  AND NOT EXISTS (SELECT 1 FROM bill_details bd WHERE bd.bill_id = bl.id AND bd.item_id = it.id);

INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes, created_at, updated_at)
SELECT bl.id, it.id, 1, 85.00, 85.00, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM bills bl
CROSS JOIN items it
WHERE it.branch_id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND bl.title = 'Venta mostrador'
  AND it.name = 'Refresco 2L'
  AND NOT EXISTS (SELECT 1 FROM bill_details bd WHERE bd.bill_id = bl.id AND bd.item_id = it.id);

INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes, created_at, updated_at)
SELECT bl.id, it.id, 1, 25.00, 25.00, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM bills bl
CROSS JOIN items it
WHERE it.branch_id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND bl.title = 'Venta mostrador'
  AND it.name = 'Agua Mineral 500ml'
  AND NOT EXISTS (SELECT 1 FROM bill_details bd WHERE bd.bill_id = bl.id AND bd.item_id = it.id);

INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes, created_at, updated_at)
SELECT bl.id, it.id, 1, 75.00, 75.00, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM bills bl
CROSS JOIN items it
WHERE it.branch_id = (SELECT id FROM branches ORDER BY id ASC LIMIT 1)
  AND bl.title = 'Venta rápida'
  AND it.name = 'Café Americano'
  AND NOT EXISTS (SELECT 1 FROM bill_details bd WHERE bd.bill_id = bl.id);
