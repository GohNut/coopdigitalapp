enum UserRole {
  member,
  officer,
  approver,
}

class CurrentUser {
  // For demo/development purposes, we can toggle this to test different views
  static UserRole role = UserRole.officer;
  
  static String get name => 'สมาชิก ใจดี (จนท.)';
  static String get id => 'MEM001';
  
  static bool get isOfficerOrApprover => 
      role == UserRole.officer || role == UserRole.approver;
      
  static bool get isApprover => role == UserRole.approver;
}
