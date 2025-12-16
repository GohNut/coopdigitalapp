import 'package:flutter/material.dart';

/// ประเภทแหล่งเงินสำหรับการจ่าย
enum PaymentSourceType {
  deposit,  // บัญชีเงินฝาก
  loan,     // วงเงินสินเชื่อ
}

/// Extension สำหรับ PaymentSourceType
extension PaymentSourceTypeExtension on PaymentSourceType {
  String get displayName {
    switch (this) {
      case PaymentSourceType.deposit:
        return 'บัญชีเงินฝาก';
      case PaymentSourceType.loan:
        return 'วงเงินสินเชื่อ';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentSourceType.deposit:
        return Icons.account_balance_wallet;
      case PaymentSourceType.loan:
        return Icons.credit_card;
    }
  }

  Color get color {
    switch (this) {
      case PaymentSourceType.deposit:
        return const Color(0xFF1A90CE); // ฟ้า
      case PaymentSourceType.loan:
        return const Color(0xFFFF9800); // ส้ม
    }
  }
}

/// Model สำหรับแหล่งเงินที่ใช้ในการจ่าย
class PaymentSource {
  final PaymentSourceType type;
  final String sourceId;
  final String sourceName;
  final String? accountNumber;
  final double balance;
  final String? additionalInfo;

  const PaymentSource({
    required this.type,
    required this.sourceId,
    required this.sourceName,
    this.accountNumber,
    required this.balance,
    this.additionalInfo,
  });

  /// สำหรับแสดงผล
  String get displayBalance {
    final formatted = balance.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return formatted;
  }

  /// สำหรับแสดงชื่อย่อ
  String get shortName {
    if (type == PaymentSourceType.deposit) {
      return accountNumber ?? sourceName;
    }
    return sourceName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentSource &&
        other.type == type &&
        other.sourceId == sourceId;
  }

  @override
  int get hashCode => type.hashCode ^ sourceId.hashCode;
}
