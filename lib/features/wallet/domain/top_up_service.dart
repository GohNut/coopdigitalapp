import 'dart:async';

class TopUpService {
  Future<Map<String, dynamic>> generateQr(double amount) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (amount < 1.0) {
      throw Exception('Top-up amount must be at least 1.00 THB');
    }

    // Mock Response
    return {
      'qr_image_base64': 'mock_base64_string', // In real app this would be a real image string
      'ref_no': 'REF-${DateTime.now().millisecondsSinceEpoch}',
      'expiry_time': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      'amount': amount,
    };
  }
}

final topUpServiceProvider = TopUpService();
