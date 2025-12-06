enum ShareTransactionType {
  monthlyBuy, // ซื้อรายเดือน
  extraBuy,   // ซื้อพิเศษ
  dividend,   // ปันผล
}

class ShareTransaction {
  final String id;
  final DateTime date;
  final ShareTransactionType type;
  final double amount; // จำนวนเงิน
  final int units;     // จำนวนหุ้น

  const ShareTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.units,
  });

  String get typeLabel {
    switch (type) {
      case ShareTransactionType.monthlyBuy:
        return 'ซื้อรายเดือน';
      case ShareTransactionType.extraBuy:
        return 'ซื้อพิเศษ';
      case ShareTransactionType.dividend:
        return 'ปันผล';
    }
  }
}
