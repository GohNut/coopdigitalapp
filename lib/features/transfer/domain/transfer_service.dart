class TransferService {
  Future<Map<String, dynamic>> searchMember(String key) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock Data
    if (key == '123456' || key == '0891234567') {
      return {
        'member_id': '123456',
        'display_name': 'นายสมชาย ใจดี',
        'avatar_url': 'https://i.pravatar.cc/150?u=123456',
      };
    } else if (key == '987654') {
       return {
        'member_id': '987654',
        'display_name': 'นางสาวสมหญิง จริงใจ',
        'avatar_url': 'https://i.pravatar.cc/150?u=987654',
      };
    } else {
      throw Exception('ไม่พบสมาชิก');
    }
  }

  Future<Map<String, dynamic>> transfer({
    required String targetMemberId,
    required double amount,
    String? note,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (amount < 1.0) {
      throw Exception('ยอดโอนขั้นต่ำ 1.00 บาท');
    }

    return {
      'transaction_id': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'amount': amount,
      'target_member_id': targetMemberId,
      'status': 'SUCCESS'
    };
  }
}

final transferServiceProvider = TransferService();
