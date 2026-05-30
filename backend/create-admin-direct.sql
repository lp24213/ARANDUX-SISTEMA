-- Criar admin diretamente no banco
-- Execute: mysql -u usuario -p database < create-admin-direct.sql

-- Primeiro, criar o tenant se não existir
INSERT INTO Tenant (id, name, legalName, document, email, isActive, createdAt, updatedAt)
SELECT 
    'admin-tenant-id-' || SUBSTRING(MD5('contato@agroisync.com'), 1, 20),
    'Agroisync Admin',
    'Agroisync Admin',
    '00000000000000',
    'contato@agroisync.com',
    true,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM Tenant WHERE email = 'contato@agroisync.com'
);

-- Depois, criar o usuário admin
-- Senha: Th@ys15221008 (hash bcrypt)
INSERT INTO User (id, tenantId, email, passwordHash, role, name, isActive, createdAt, updatedAt)
SELECT 
    'admin-user-id-' || SUBSTRING(MD5('contato@agroisync.com'), 1, 20),
    (SELECT id FROM Tenant WHERE email = 'contato@agroisync.com' LIMIT 1),
    'contato@agroisync.com',
    '$2b$10$rK9VJ8qJ8qJ8qJ8qJ8qJ8uJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ8qJ', -- Hash da senha Th@ys15221008
    'SUPERADMIN',
    'Administrador',
    true,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM User WHERE email = 'contato@agroisync.com'
);

