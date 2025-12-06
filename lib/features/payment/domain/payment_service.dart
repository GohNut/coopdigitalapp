class PaymentService {
  Future<Map<String, dynamic>> resolveQr(String qrData) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock parsing QR
    return {
      'merchant_id': 'M-778899',
      'merchant_name': 'ร้านสวัสดิการสหกรณ์',
      'merchant_img': 'https://illustrations.popsy.co/amber/shoppping.svg',
      // Dynamic QR might have amount
      'amount': null, 
    };
  }

  Future<Map<String, dynamic>> pay({
    required String merchantId,
    required double amount,
    required String sourceType, // CASH, CREDIT
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock Validation
    if (sourceType == 'CASH') {
      if (amount > 10000) { // Mock Balance
        throw Exception('ยอดเงินในกระเป๋าไม่พอ');
      }
    } else if (sourceType == 'CREDIT') {
      if (amount > 5000) { // Mock Credit Limit
        throw Exception('วงเงินคงเหลือไม่พอ');
      }
    }

    return {
      'transaction_id': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'SUCCESS',
      'amount': amount,
      'source_type': sourceType,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

final paymentServiceProvider = PaymentService();
