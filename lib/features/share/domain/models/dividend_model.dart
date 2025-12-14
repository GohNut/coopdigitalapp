/// Model สำหรับสรุปเงินปันผลของสมาชิก
class DividendSummary {
  final double rate;            // อัตราปันผล (เช่น 5.5%)
  final double totalAmount;     // ยอดปันผลที่ได้รับ
  final int year;               // ปีบัญชี
  final String status;          // pending, paid
  final double averageShares;   // หุ้นเฉลี่ยตลอดปี

  const DividendSummary({
    required this.rate,
    required this.totalAmount,
    required this.year,
    required this.status,
    required this.averageShares,
  });

  factory DividendSummary.fromJson(Map<String, dynamic> json) {
    return DividendSummary(
      rate: (json['rate'] ?? 0.0).toDouble(),
      totalAmount: (json['totalamount'] ?? 0.0).toDouble(),
      year: json['year'] ?? DateTime.now().year,
      status: json['status'] ?? 'pending',
      averageShares: (json['averageshares'] ?? 0.0).toDouble(),
    );
  }

  /// สร้าง default summary เมื่อยังไม่มีข้อมูล
  factory DividendSummary.empty(int year) {
    return DividendSummary(
      rate: 5.5,  // อัตราปันผลเริ่มต้น
      totalAmount: 0,
      year: year,
      status: 'pending',
      averageShares: 0,
    );
  }
}

/// Model สำหรับประวัติการรับปันผล
class DividendHistory {
  final String id;
  final DateTime paymentDate;
  final double amount;
  final int year;
  final double rate;
  final String paymentMethod;   // account, share

  const DividendHistory({
    required this.id,
    required this.paymentDate,
    required this.amount,
    required this.year,
    required this.rate,
    required this.paymentMethod,
  });

  factory DividendHistory.fromJson(Map<String, dynamic> json) {
    return DividendHistory(
      id: json['_id'] ?? json['id'] ?? '',
      paymentDate: json['paymentdate'] != null 
          ? DateTime.parse(json['paymentdate']) 
          : DateTime.now(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      year: json['year'] ?? DateTime.now().year,
      rate: (json['rate'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentmethod'] ?? 'account',
    );
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'share':
        return 'ซื้อหุ้นเพิ่ม';
      case 'account':
      default:
        return 'โอนเข้าบัญชี';
    }
  }
}

/// อัตราปันผลประจำปี (ประกาศโดยสหกรณ์)
class DividendRate {
  final int year;
  final double rate;
  final DateTime announcedDate;

  const DividendRate({
    required this.year,
    required this.rate,
    required this.announcedDate,
  });

  factory DividendRate.fromJson(Map<String, dynamic> json) {
    return DividendRate(
      year: json['year'] ?? DateTime.now().year,
      rate: (json['rate'] ?? 0.0).toDouble(),
      announcedDate: json['announceddate'] != null 
          ? DateTime.parse(json['announceddate']) 
          : DateTime.now(),
    );
  }
}
