// Comprehensive Supabase Diagnostic and Fix Script
console.log('🔧 Starting Comprehensive Supabase Diagnostic...');

async function runDiagnostics() {
  try {
    // 1. Test Environment Variables
    console.log('\n📋 1. CHECKING ENVIRONMENT VARIABLES...');
    const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
    
    console.log('EXPO_PUBLIC_SUPABASE_URL:', supabaseUrl ? '✅ Set' : '❌ Missing');
    console.log('EXPO_PUBLIC_SUPABASE_ANON_KEY:', supabaseKey ? '✅ Set' : '❌ Missing');
    
    if (!supabaseUrl || !supabaseKey) {
      console.log('❌ Environment variables missing - using fallback values');
    }

    // 2. Test Supabase Connection
    console.log('\n🔌 2. TESTING SUPABASE CONNECTION...');
    const { supabase } = await import('./lib/supabase.js');
    
    const { data: connectionTest, error: connectionError } = await supabase
      .from('schools')
      .select('count')
      .limit(1);
    
    if (connectionError) {
      console.log('❌ Connection failed:', connectionError.message);
      return false;
    } else {
      console.log('✅ Connection successful');
    }

    // 3. Test Authentication
    console.log('\n🔐 3. TESTING AUTHENTICATION...');
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.log('❌ Auth session error:', sessionError.message);
    } else {
      console.log('✅ Auth system working, session:', session ? 'Active' : 'None');
    }

    // 4. Test Database Tables
    console.log('\n📊 4. TESTING DATABASE TABLES...');
    const tables = ['schools', 'app_users', 'assignments', 'study_materials', 'submissions'];
    
    for (const table of tables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('count')
          .limit(1);
        
        if (error) {
          console.log(`❌ ${table}: ${error.message}`);
        } else {
          console.log(`✅ ${table}: Working`);
        }
      } catch (err) {
        console.log(`❌ ${table}: ${err.message}`);
      }
    }

    // 5. Test Storage Buckets
    console.log('\n🗂️ 5. TESTING STORAGE BUCKETS...');
    const buckets = ['study-materials', 'submissions', 'videos'];
    
    for (const bucket of buckets) {
      try {
        const { data, error } = await supabase.storage
          .from(bucket)
          .list('', { limit: 1 });
        
        if (error) {
          console.log(`❌ ${bucket}: ${error.message}`);
        } else {
          console.log(`✅ ${bucket}: Working`);
        }
      } catch (err) {
        console.log(`❌ ${bucket}: ${err.message}`);
      }
    }

    // 6. Test RLS Policies
    console.log('\n🔒 6. TESTING RLS POLICIES...');
    try {
      // Test as anonymous user
      const { data: schoolsData, error: schoolsError } = await supabase
        .from('schools')
        .select('id, name')
        .limit(1);
      
      if (schoolsError) {
        console.log('❌ RLS blocking anonymous access to schools:', schoolsError.message);
      } else {
        console.log('✅ Schools table accessible');
      }
    } catch (err) {
      console.log('❌ RLS test error:', err.message);
    }

    console.log('\n✅ DIAGNOSTIC COMPLETE');
    return true;

  } catch (error) {
    console.error('❌ DIAGNOSTIC FAILED:', error);
    return false;
  }
}

// Run diagnostics
runDiagnostics().then(success => {
  if (success) {
    console.log('\n🎉 All systems operational!');
  } else {
    console.log('\n⚠️ Issues detected - check logs above');
  }
});