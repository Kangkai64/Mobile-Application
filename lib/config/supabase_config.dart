class SupabaseConfig {
  // Supabase configuration
  static const String supabaseUrl = 'https://dzajfltnnwjaoalaimob.supabase.co';
  static const String anonKey = 'sb_secret_V-wmePWdJH9SggsJXDvZxg_d-rttjIG';
  
  // Service role key for admin operations (bypasses RLS)
  // This should be kept secure and not committed to version control in production
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6YWpmbHRubndqYW9hbGFpbW9iIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDQ5NzQwMCwiZXhwIjoyMDUwMDczNDAwfQ.d257ad0bb8240be00c71f3e9490828be';
  
  // S3 Storage configuration
  static const String s3AccessKey = 'd257ad0bb8240be00c71f3e9490828be';
  static const String s3SecretKey = 'a473682ac89fd55205c1e24a9f1c518272a63127a3a485df2f18560219c3f25a';
  static const String storageBucket = 'Work Order Photos';
  static const String profileBucket = 'Profile';
}
