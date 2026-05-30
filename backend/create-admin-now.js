const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  const adminEmail = 'contato@agroisync.com';
  const adminPassword = 'Th@ys15221008';
  
  console.log('Criando admin...');
  
  try {
    // Verificar se já existe
    const existing = await prisma.user.findUnique({
      where: { email: adminEmail },
    });
    
    if (existing) {
      const hash = await bcrypt.hash(adminPassword, 10);
      await prisma.user.update({
        where: { email: adminEmail },
        data: { passwordHash: hash },
      });
      console.log('✅ Admin atualizado!');
    } else {
      // Criar tenant
      const tenant = await prisma.tenant.create({
        data: {
          name: 'Agroisync Admin',
          legalName: 'Agroisync Admin',
          document: '00000000000000',
          email: adminEmail,
          isActive: true,
        },
      });
      
      // Criar admin
      const hash = await bcrypt.hash(adminPassword, 10);
      await prisma.user.create({
        data: {
          email: adminEmail,
          name: 'Administrador',
          passwordHash: hash,
          tenantId: tenant.id,
          role: 'SUPERADMIN',
          isActive: true,
        },
      });
      console.log('✅ Admin criado!');
    }
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();

