enum UserRole {
  member,
  officer,
  approver,
}

class CurrentUser {
  // For demo/development purposes, we can toggle this to test different views
  static UserRole role = UserRole.approver;
  
  static String get name => 'เจ้าหน้าที่ สมชาย';
  static String get id => 'OFF001';
  
  static bool get isOfficerOrApprover => 
      role == UserRole.officer || role == UserRole.approver;
      
  static bool get isApprover => role == UserRole.approver;
}
