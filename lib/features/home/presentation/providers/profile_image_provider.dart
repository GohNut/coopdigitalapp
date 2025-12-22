import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for tracking profile image URL updates
class ProfileImageNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }
  
  void setImageUrl(String? url) {
    state = url;
  }
  
  void clear() {
    state = null;
  }
}

/// Provider for tracking profile image URL updates
/// This allows widgets to rebuild when the profile image changes
final profileImageUrlProvider = NotifierProvider<ProfileImageNotifier, String?>(ProfileImageNotifier.new);
