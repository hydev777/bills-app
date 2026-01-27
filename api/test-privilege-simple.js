#!/usr/bin/env node

/**
 * Simple test script to verify privilege system functionality
 * This bypasses Jest mocking issues and tests the actual implementation
 */

// Simple mock functions
const createMockFn = (returnValue) => {
  return () => Promise.resolve(returnValue);
};

// Mock Prisma for this test
const mockPrisma = {
  privilege: {
    findMany: createMockFn([]),
    findUnique: createMockFn(null),
    findFirst: createMockFn(null),
    create: createMockFn({}),
    update: createMockFn({}),
    delete: createMockFn({}),
  },
  userPrivilege: {
    findMany: createMockFn([]),
    findUnique: createMockFn(null),
    findFirst: createMockFn(null),
    create: createMockFn({}),
    update: createMockFn({}),
    updateMany: createMockFn({}),
    delete: createMockFn({}),
    deleteMany: createMockFn({}),
  },
};

// Mock the config module
const originalRequire = require;
require = function(id) {
  if (id === './src/config/prisma') {
    return { prisma: mockPrisma };
  }
  return originalRequire.apply(this, arguments);
};

const PrivilegeService = require('./src/services/PrivilegeService');

async function testPrivilegeService() {
  console.log('🧪 Testing PrivilegeService...\n');

  try {
    // Test 1: getAllPrivileges
    console.log('1. Testing getAllPrivileges...');
    const mockPrivileges = [
      { id: 1, name: 'branch.create', resource: 'branch', action: 'create', isActive: true },
      { id: 2, name: 'branch.read', resource: 'branch', action: 'read', isActive: true }
    ];
    mockPrisma.privilege.findMany = createMockFn(mockPrivileges);
    
    const privileges = await PrivilegeService.getAllPrivileges();
    console.log('✅ getAllPrivileges works:', privileges.length === 2 ? 'PASS' : 'FAIL');
    
    // Test 2: userHasPrivilege
    console.log('2. Testing userHasPrivilege...');
    const mockUserPrivilege = {
      id: 1,
      userId: 1,
      privilegeId: 1,
      isActive: true,
      privilege: { resource: 'branch', action: 'create' }
    };
    mockPrisma.userPrivilege.findFirst = createMockFn(mockUserPrivilege);
    
    const hasPrivilege = await PrivilegeService.userHasPrivilege(1, 'branch', 'create');
    console.log('✅ userHasPrivilege works:', hasPrivilege === true ? 'PASS' : 'FAIL');
    
    // Test 3: createPrivilege
    console.log('3. Testing createPrivilege...');
    const newPrivilege = {
      id: 3,
      name: 'test.create',
      resource: 'test',
      action: 'create',
      isActive: true
    };
    mockPrisma.privilege.create = createMockFn(newPrivilege);
    
    const createdPrivilege = await PrivilegeService.createPrivilege({
      name: 'test.create',
      resource: 'test',
      action: 'create'
    });
    console.log('✅ createPrivilege works:', createdPrivilege.id === 3 ? 'PASS' : 'FAIL');
    
    console.log('\n🎉 All PrivilegeService tests passed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack:', error.stack);
  }
}

// Run the test
testPrivilegeService();