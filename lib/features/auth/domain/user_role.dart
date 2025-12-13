enum UserRole {
  member,
  officer,
  approver,
}

class CurrentUser {
  // For demo/development purposes, we can toggle this to test different views
  static UserRole role = UserRole.officer; // Default to officer for dev, but will be set by login
  static String name = 'สมาชิก ใจดี (จนท.)';
  static String id = 'MEM001';
  
  // Set to true if the user has successfully registered as a coop member
  static bool isMember = true; 

  static String? pin; // Added PIN field

  static bool get isOfficerOrApprover => 
      role == UserRole.officer || role == UserRole.approver;
      
  static bool get isApprover => role == UserRole.approver;

  // Helper to reset/set user (Simulate Login)
  static void setUser({
    required String newName, 
    required String newId, 
    required UserRole newRole,
    required bool newIsMember,
    String? newPin, // Added PIN parameter
  }) {
    name = newName;
    id = newId;
    role = newRole;
    isMember = newIsMember;
    pin = newPin;
  }
}
