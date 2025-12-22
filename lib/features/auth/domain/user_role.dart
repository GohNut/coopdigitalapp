import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  member,
  officer,
  approver,
}

class CurrentUser {
  // Default state: Not logged in (or guest)
  // Was: static UserRole role = UserRole.officer;
  static UserRole role = UserRole.member; 
  static String name = '';
  static String id = '';
  
  // Set to true if the user has successfully registered as a coop member
  static bool isMember = false; 

  static String? pin; // Added PIN field
  static String? profileImageUrl; // Added profile image URL field
  static String? kycStatus; // Added KYC status field

  static bool get isOfficerOrApprover => 
      role == UserRole.officer || role == UserRole.approver;
      
  static bool get isApprover => role == UserRole.approver;

  // Helper to reset/set user (Simulate Login)
  static Future<void> setUser({
    required String newName, 
    required String newId, 
    required UserRole newRole,
    required bool newIsMember,
    String? newPin, // Added PIN parameter
    String? newProfileImageUrl, // Added profile image URL parameter
    String? newKycStatus, // Added KYC status parameter
  }) async {
    name = newName;
    id = newId;
    role = newRole;
    isMember = newIsMember;
    pin = newPin;
    profileImageUrl = newProfileImageUrl;
    kycStatus = newKycStatus;
    
    await saveUser(); // Auto-save when setting user
  }

  // Save current user state to SharedPreferences
  static Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_id', id);
    await prefs.setString('user_role', role.name); // Store enum as string
    await prefs.setBool('user_is_member', isMember);
    if (pin != null) {
      await prefs.setString('user_pin', pin!);
    } else {
      await prefs.remove('user_pin');
    }
    if (profileImageUrl != null) {
      await prefs.setString('user_profile_image_url', profileImageUrl!);
    } else {
      await prefs.remove('user_profile_image_url');
    }
    if (kycStatus != null) {
      await prefs.setString('user_kyc_status', kycStatus!);
    } else {
      await prefs.remove('user_kyc_status');
    }
  }

  // Load user state from SharedPreferences
  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have a saved session
    if (!prefs.containsKey('user_id') || prefs.getString('user_id') == '') {
      return; // No saved user, keep defaults
    }

    name = prefs.getString('user_name') ?? '';
    id = prefs.getString('user_id') ?? '';
    
    final roleString = prefs.getString('user_role') ?? 'member';
    role = UserRole.values.firstWhere(
      (e) => e.name == roleString, 
      orElse: () => UserRole.member
    );
    
    isMember = prefs.getBool('user_is_member') ?? false;
    pin = prefs.getString('user_pin');
    profileImageUrl = prefs.getString('user_profile_image_url');
    kycStatus = prefs.getString('user_kyc_status');
  }

  // Clear user state (Logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Or remove specific keys if preferred
    
    // Reset to defaults
    name = '';
    id = '';
    role = UserRole.member;
    isMember = false;
    pin = null;
    profileImageUrl = null;
    kycStatus = null;
  }
}
