// Simple test script to verify JWT authentication is working
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testAuthFlow() {
  console.log('🧪 Testing JWT Authentication Flow...\n');

  try {
    // Test 1: Try to access protected route without token
    console.log('1. Testing access to protected route without token...');
    try {
      await axios.get(`${BASE_URL}/bills`);
      console.log('❌ FAIL: Should have been denied access');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ PASS: Access denied without token');
      } else {
        console.log('❌ FAIL: Unexpected error:', error.message);
      }
    }

    // Test 2: Register a new user
    console.log('\n2. Testing user registration...');
    const registerData = {
      username: 'testuser' + Date.now(),
      email: `test${Date.now()}@example.com`,
      password: 'testpass123'
    };

    const registerResponse = await axios.post(`${BASE_URL}/users/register`, registerData);
    
    if (registerResponse.status === 201 && registerResponse.data.token) {
      console.log('✅ PASS: User registered successfully');
      console.log('   Token received:', registerResponse.data.token.substring(0, 20) + '...');
    } else {
      console.log('❌ FAIL: Registration failed');
      return;
    }

    const token = registerResponse.data.token;

    // Test 3: Access protected route with valid token
    console.log('\n3. Testing access to protected route with valid token...');
    try {
      const response = await axios.get(`${BASE_URL}/bills`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (response.status === 200) {
        console.log('✅ PASS: Access granted with valid token');
        console.log('   Response:', JSON.stringify(response.data, null, 2));
      } else {
        console.log('❌ FAIL: Unexpected response status:', response.status);
      }
    } catch (error) {
      console.log('❌ FAIL: Error accessing protected route:', error.message);
    }

    // Test 4: Test user profile endpoint
    console.log('\n4. Testing user profile endpoint...');
    try {
      const profileResponse = await axios.get(`${BASE_URL}/users/profile`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (profileResponse.status === 200) {
        console.log('✅ PASS: Profile endpoint working');
        console.log('   User:', profileResponse.data.username);
      } else {
        console.log('❌ FAIL: Profile endpoint failed');
      }
    } catch (error) {
      console.log('❌ FAIL: Profile endpoint error:', error.message);
    }

    // Test 5: Test with invalid token
    console.log('\n5. Testing with invalid token...');
    try {
      await axios.get(`${BASE_URL}/bills`, {
        headers: {
          'Authorization': 'Bearer invalid-token-here'
        }
      });
      console.log('❌ FAIL: Should have been denied access with invalid token');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ PASS: Access denied with invalid token');
      } else {
        console.log('❌ FAIL: Unexpected error with invalid token:', error.message);
      }
    }

    console.log('\n🎉 Authentication tests completed!');

  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
    if (error.response?.data) {
      console.error('   Response data:', error.response.data);
    }
  }
}

// Only run if this file is executed directly
if (require.main === module) {
  testAuthFlow();
}

module.exports = { testAuthFlow };
