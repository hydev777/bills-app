#!/bin/bash

# Privilege System Test Runner
# This script runs all privilege-related tests

echo "🧪 Running Privilege System Tests..."
echo "=================================="

# Set environment variables for testing
export NODE_ENV=test
export JWT_SECRET=test-secret-key
export DATABASE_URL=postgresql://test:test@localhost:5432/test_db

# Run privilege service tests
echo "📋 Running PrivilegeService tests..."
npm test -- tests/services/PrivilegeService.test.js

# Run privilege middleware tests
echo "🛡️  Running privilege middleware tests..."
npm test -- tests/middleware/auth.test.js

# Run privilege route tests
echo "🛣️  Running privilege route tests..."
npm test -- tests/routes/privileges.test.js

# Run branch route tests (with privilege authorization)
echo "🏢 Running branch route tests (with privileges)..."
npm test -- tests/routes/branches.test.js

# Run integration tests
echo "🔗 Running privilege system integration tests..."
npm test -- tests/integration/privilege-system.test.js

echo ""
echo "✅ All privilege system tests completed!"
echo ""
echo "📊 Test Summary:"
echo "- PrivilegeService: Unit tests for privilege management"
echo "- Auth Middleware: Tests for privilege-based authorization"
echo "- Privilege Routes: API endpoint tests"
echo "- Branch Routes: Tests for privilege-protected branch operations"
echo "- Integration: End-to-end privilege workflow tests"
echo ""
echo "🎯 Key Test Scenarios Covered:"
echo "- ✅ Privilege creation, reading, updating, deletion"
echo "- ✅ User privilege granting and revoking"
echo "- ✅ Privilege-based route protection"
echo "- ✅ Expired privilege handling"
echo "- ✅ Multiple privilege management"
echo "- ✅ Error handling and edge cases"
echo "- ✅ Complete admin workflow"
echo ""
echo "🚀 To run all tests: npm test"
echo "🔍 To run specific test: npm test -- tests/path/to/test.js"
