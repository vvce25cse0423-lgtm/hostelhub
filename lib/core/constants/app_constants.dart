class AppConstants {
  AppConstants._();

  static const String appName = 'HostelHub';
  static const String appVersion = '1.0.0';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wsvzkjovyxbipnmrmhwb.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_BQmuYlbmIwSDv8HRV8UsXQ_cnmb0MPI',
  );

  static const String usersTable = 'users';
  static const String roomsTable = 'rooms';
  static const String allocationsTable = 'allocations';
  static const String complaintsTable = 'complaints';
  static const String attendanceTable = 'attendance';
  static const String feesTable = 'fees';
  static const String notificationsTable = 'notifications';

  static const String complaintImagesBucket = 'complaint-images';
  static const String profileImagesBucket = 'profile-images';

  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleWarden = 'warden';

  static const String complaintPending = 'pending';
  static const String complaintInProgress = 'in_progress';
  static const String complaintResolved = 'resolved';

  static const String feePaid = 'paid';
  static const String feePending = 'pending';
  static const String feeOverdue = 'overdue';

  static const int pageSize = 20;
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
