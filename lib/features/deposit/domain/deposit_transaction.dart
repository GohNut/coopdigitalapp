/// ประเภทรายการเดินบัญชี
enum TransactionType {
  deposit,      // ฝากเงิน
  withdrawal,   // ถอนเงิน
  payment,      // จ่ายเงิน (Scan & Pay)
  transferIn,   // รับโอน
  transferOut,  // โอนออก
  interest,     // ดอกเบี้ย
  fee,          // ค่าธรรมเนียม
}

/// Extension สำหรับ TransactionType
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.deposit:
        return 'ฝากเงิน';
      case TransactionType.withdrawal:
        return 'ถอนเงิน';
      case TransactionType.payment:
        return 'จ่ายเงิน';
      case TransactionType.transferIn:
        return 'รับโอน';
      case TransactionType.transferOut:
        return 'โอนออก';
      case TransactionType.interest:
        return 'ดอกเบี้ย';
      case TransactionType.fee:
        return 'ค่าธรรมเนียม';
    }
  }

  /// รายการนี้เป็นรายรับหรือไม่
  bool get isCredit {
    switch (this) {
      case TransactionType.deposit:
      case TransactionType.transferIn:
      case TransactionType.interest:
        return true;
      case TransactionType.withdrawal:
      case TransactionType.payment:
      case TransactionType.transferOut:
      case TransactionType.fee:
        return false;
    }
  }
}

/// สถานะรายการเดินบัญชี
enum TransactionStatus {
  pending,      // รอดำเนินการ
  completed,    // สำเร็จ
  rejected,     // ปฏิเสธ/ยกเลิก
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'รอดำเนินการ';
      case TransactionStatus.completed:
        return 'สำเร็จ';
      case TransactionStatus.rejected:
        return 'ยกเลิก';
    }
  }
}

/// Model สำหรับรายการเดินบัญชี
class DepositTransaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final double balanceAfter; // ยอดคงเหลือหลังทำรายการ
  final DateTime dateTime;
  final String? description;
  final String? referenceNo;
  final TransactionStatus status;

  const DepositTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.dateTime,
    this.description,
    this.referenceNo,
    this.status = TransactionStatus.completed, // Default to completed for backward compatibility
  });
}
