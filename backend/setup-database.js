// Script completo para configurar banco MySQL
"use strict";
Object.defineProperty(exports, "__esModule", {
    value: true
});
const _client = require("@prisma/client");
const _bcrypt = /*#__PURE__*/ _interop_require_wildcard(require("bcrypt"));
function _getRequireWildcardCache(nodeInterop) {
    if (typeof WeakMap !== "function") return null;
    var cacheBabelInterop = new WeakMap();
    var cacheNodeInterop = new WeakMap();
    return (_getRequireWildcardCache = function(nodeInterop) {
        return nodeInterop ? cacheNodeInterop : cacheBabelInterop;
    })(nodeInterop);
}
function _interop_require_wildcard(obj, nodeInterop) {
    if (!nodeInterop && obj && obj.__esModule) {
        return obj;
    }
    if (obj === null || typeof obj !== "object" && typeof obj !== "function") {
        return {
            default: obj
        };
    }
    var cache = _getRequireWildcardCache(nodeInterop);
    if (cache && cache.has(obj)) {
        return cache.get(obj);
    }
    var newObj = {
        __proto__: null
    };
    var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for(var key in obj){
        if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) {
            var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null;
            if (desc && (desc.get || desc.set)) {
                Object.defineProperty(newObj, key, desc);
            } else {
                newObj[key] = obj[key];
            }
        }
    }
    newObj.default = obj;
    if (cache) {
        cache.set(obj, newObj);
    }
    return newObj;
}
const prisma = new _client.PrismaClient();
async function main() {
    console.log('🔍 Verificando conexão com banco...');
    try {
        // Testar conexão
        await prisma.$connect();
        console.log('✅ Conectado ao banco MySQL');
        // Verificar se as tabelas existem (tentar query simples)
        await prisma.$queryRaw`SELECT 1`;
        console.log('✅ Tabelas verificadas');
        console.log('🔐 Criando/atualizando admin...');
        const adminEmail = 'contato@agroisync.com';
        const adminPassword = 'Th@ys15221008';
        const adminPasswordHash = await _bcrypt.hash(adminPassword, 10);
        // Verificar se admin existe
        const existingAdmin = await prisma.user.findUnique({
            where: {
                email: adminEmail
            }
        });
        if (existingAdmin) {
            // Atualizar senha
            await prisma.user.update({
                where: {
                    email: adminEmail
                },
                data: {
                    passwordHash: adminPasswordHash
                }
            });
            console.log('✅ Admin atualizado:', adminEmail);
        } else {
            // Verificar se tenant existe
            let adminTenant = await prisma.tenant.findFirst({
                where: {
                    email: adminEmail
                }
            });
            if (!adminTenant) {
                adminTenant = await prisma.tenant.create({
                    data: {
                        name: 'Agroisync Admin',
                        legalName: 'Agroisync Admin',
                        document: '00000000000000',
                        email: adminEmail,
                        isActive: true
                    }
                });
                console.log('✅ Tenant criado para admin');
            }
            // Criar admin
            await prisma.user.create({
                data: {
                    email: adminEmail,
                    name: 'Administrador',
                    passwordHash: adminPasswordHash,
                    tenantId: adminTenant.id,
                    role: _client.Role.SUPERADMIN,
                    isActive: true
                }
            });
            console.log('✅ Admin criado:', adminEmail);
        }
        // Verificar quantos usuários existem
        const userCount = await prisma.user.count();
        console.log(`📊 Total de usuários no banco: ${userCount}`);
        // Verificar quantos tenants existem
        const tenantCount = await prisma.tenant.count();
        console.log(`📊 Total de tenants no banco: ${tenantCount}`);
        console.log('✅ Banco configurado com sucesso!');
    } catch (error) {
        console.error('❌ Erro:', error.message);
        if (error.message.includes('P1001') || error.message.includes('connect')) {
            console.error('❌ Não foi possível conectar ao banco MySQL');
            console.error('❌ Verifique se o MySQL está rodando e se DATABASE_URL está correto');
            console.error('❌ DATABASE_URL atual:', process.env.DATABASE_URL || 'não configurado');
        } else if (error.message.includes('P1003') || error.message.includes('does not exist')) {
            console.error('❌ Tabelas não existem. Execute: npx prisma migrate deploy');
        } else {
            console.error('❌ Erro desconhecido:', error);
        }
        process.exit(1);
    } finally{
        await prisma.$disconnect();
    }
}
main();
