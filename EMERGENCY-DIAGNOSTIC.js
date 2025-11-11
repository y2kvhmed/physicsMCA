// EMERGENCY DIAGNOSTIC SCRIPT
// Run this in browser console to diagnose the issue

console.log('🔍 SUPABASE DIAGNOSTIC STARTING...');

// 1. Check environment variables
console.log('📋 Environment Check:');
console.log('Supabase URL:', process.env.EXPO_PUBLIC_SUPABASE_URL);
console.log('Has Anon Key:', !!process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY);
console.log('Anon Key Length:', process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY?.length);

// 2. Test basic connection
async function testConnection() {
  try {
    console.log('🔌 Testing Supabase Connection...');
    
    // Import supabase (adjust path if needed)
    const { supabase } = await import('./lib/supabase.js');
    
    // Test basic query
    const { data, error } = await supabase
      .from('schools')
      .select('count')
      .limit(1);
    
    if (error) {
      console.error('❌ Connection Error:', error);
      return false;
    }
    
    console.log('✅ Connection Success:', data);
    return true;
  } catch (err) {
    console.error('❌ Connection Failed:', err);
    return false;
  }
}

// 3. Check authentication
async function checkAuth() {
  try {
    console.log('🔐 Checking Authentication...');
    
    const { supabase } = await import('./lib/supabase.js');
    
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error) {
      console.error('❌ Auth Error:', error);
      return null;
    }
    
    if (session) {
      console.log('✅ User Logged In:', session.user.email);
      console.log('User Role:', session.user.user_metadata?.role);
      return session;
    } else {
      console.log('⚠️ No Active Session - User needs to login');
      return null;
    }
  } catch (err) {
    console.error('❌ Auth Check Failed:', err);
    return null;
  }
}

// 4. Test data queries
async function testDataQueries() {
  try {
    console.log('📊 Testing Data Queries...');
    
    const { supabase } = await import('./lib/supabase.js');
    
    // Test each table
    const tables = ['schools', 'app_users', 'assignments', 'study_materials'];
    
    for (const table of tables) {
      try {
        const { data, error, count } = await supabase
          .from(table)
          .select('*', { count: 'exact' })
          .limit(1);
        
        if (error) {
          console.error(`❌ ${table} Error:`, error.message);
        } else {
          console.log(`✅ ${table}: ${count} records`);
        }
      } catch (err) {
        console.error(`❌ ${table} Failed:`, err.message);
      }
    }
  } catch (err) {
    console.error('❌ Data Query Test Failed:', err);
  }
}

// 5. Run all diagnostics
async function runDiagnostics() {
  console.log('🚀 Running Full Diagnostic...');
  
  const connected = await testConnection();
  const session = await checkAuth();
  
  if (connected) {
    await testDataQueries();
  }
  
  console.log('📋 DIAGNOSTIC SUMMARY:');
  console.log('Connection:', connected ? '✅ Working' : '❌ Failed');
  console.log('Authentication:', session ? '✅ Logged In' : '⚠️ Not Logged In');
  
  if (!connected) {
    console.log('🔧 RECOMMENDED ACTIONS:');
    console.log('1. Check if Supabase project is active');
    console.log('2. Verify environment variables');
    console.log('3. Check browser network tab for failed requests');
    console.log('4. Try logging out and back in');
  }
  
  if (!session) {
    console.log('🔧 AUTH ISSUE:');
    console.log('User needs to login again');
    console.log('This could explain why no data is showing');
  }
}

// Auto-run diagnostics
runDiagnostics();

// Export for manual use
window.supabaseDiagnostic = {
  testConnection,
  checkAuth,
  testDataQueries,
  runDiagnostics
};

console.log('💡 You can also run individual tests:');
console.log('- window.supabaseDiagnostic.testConnection()');
console.log('- window.supabaseDiagnostic.checkAuth()');
console.log('- window.supabaseDiagnostic.testDataQueries()');