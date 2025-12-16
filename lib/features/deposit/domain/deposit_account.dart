/// ประเภทบัญชีเงินฝาก
enum AccountType {
  savings,   // ออมทรัพย์
  fixed,     // ประจำ
  special,   // พิเศษ
  loan,      // เงินกู้สหกรณ์
}

/// Extension สำหรับ AccountType
extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.savings:
        return 'ออมทรัพย์';
      case AccountType.fixed:
        return 'ประจำ';
      case AccountType.special:
        return 'พิเศษ';
      case AccountType.loan:
        return 'เงินกู้สหกรณ์';
    }
  }

  /// สีประจำประเภทบัญชี (hex code)
  int get colorCode {
    switch (this) {
      case AccountType.savings:
        return 0xFF1A90CE; // ฟ้า
      case AccountType.fixed:
        return 0xFFD4AF37; // ทอง
      case AccountType.special:
        return 0xFFE53935; // แดง
      case AccountType.loan:
        return 0xFF9C27B0; // ม่วง
    }
  }
}

/// Model สำหรับบัญชีเงินฝาก
class DepositAccount {
  final String id;
  final String accountNumber;
  final String accountName;
  final AccountType accountType;
  final double balance;
  final double interestRate; // % ต่อปี
  final double accruedInterest; // ดอกเบี้ยสะสมปีนี้
  final DateTime openedDate;

  const DepositAccount({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.accountType,
    required this.balance,
    required this.interestRate,
    required this.accruedInterest,
    required this.openedDate,
  });

  /// Mask เลขที่บัญชี เช่น xxx-x-12345-x
  String get maskedAccountNumber {
    if (accountNumber.length < 10) return accountNumber;
    final parts = accountNumber.replaceAll('-', '');
    return 'xxx-x-${parts.substring(4, 9)}-x';
  }

  /// เลขที่บัญชีแบบเต็ม (สำหรับ Copy)
  String get fullAccountNumber => accountNumber;
}
