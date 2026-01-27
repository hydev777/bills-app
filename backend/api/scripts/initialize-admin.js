const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function initializeAdminUser() {
  try {
    console.log('🚀 Initializing admin user and privileges...');

    // Check if admin user already exists
    const existingAdmin = await prisma.user.findFirst({
      where: {
        OR: [
          { email: 'admin@example.com' },
          { username: 'admin' }
        ]
      }
    });

    if (existingAdmin) {
      console.log('✅ Admin user already exists');
      return existingAdmin;
    }

    // Create admin user
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    const adminUser = await prisma.user.create({
      data: {
        username: 'admin',
        email: 'admin@example.com',
        passwordHash: hashedPassword
      }
    });

    console.log('✅ Admin user created:', adminUser.email);

    // Get all privileges
    const privileges = await prisma.privilege.findMany({
      where: { isActive: true }
    });

    console.log(`📋 Found ${privileges.length} privileges`);

    // Grant all privileges to admin user
    const userPrivileges = privileges.map(privilege => ({
      userId: adminUser.id,
      privilegeId: privilege.id,
      grantedBy: adminUser.id, // Self-granted
      isActive: true
    }));

    await prisma.userPrivilege.createMany({
      data: userPrivileges
    });

    console.log(`✅ Granted ${privileges.length} privileges to admin user`);

    // Display granted privileges
    const grantedPrivileges = await prisma.userPrivilege.findMany({
      where: { userId: adminUser.id },
      include: {
        privilege: {
          select: {
            name: true,
            resource: true,
            action: true
          }
        }
      }
    });

    console.log('\n📊 Admin user privileges:');
    grantedPrivileges.forEach(up => {
      console.log(`  - ${up.privilege.resource}.${up.privilege.action} (${up.privilege.name})`);
    });

    console.log('\n🎉 Admin user initialization complete!');
    console.log('📧 Email: admin@example.com');
    console.log('🔑 Password: admin123');
    console.log('⚠️  Please change the password after first login!');

    return adminUser;

  } catch (error) {
    console.error('❌ Error initializing admin user:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  initializeAdminUser()
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}

module.exports = { initializeAdminUser };
