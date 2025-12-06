enum LoanApplicationStatus {
  pending,
  approved,
  rejected,
}

class LoanApplication {
  final String id;
  final String applicantName;
  final String applicantId;
  final String memberId;
  final double amount;
  final String productName;
  final DateTime requestDate;
  final LoanApplicationStatus status;
  final String? officerNote;
  final double monthlySalary;
  final double currentDebt;
  final int requestTerm; // months

  LoanApplication({
    required this.id,
    required this.applicantName,
    required this.applicantId,
    required this.memberId,
    required this.amount,
    required this.productName,
    required this.requestDate,
    required this.status,
    this.officerNote,
    required this.monthlySalary,
    required this.currentDebt,
    required this.requestTerm,
  });

  // Mock Data
  static List<LoanApplication> get mockApplications => [
    LoanApplication(
      id: 'REQ-2024-001',
      applicantName: 'สมใจ รักดี',
      applicantId: '1100200333444',
      memberId: 'M00123',
      amount: 50000,
      productName: 'เงินกู้ฉุกเฉิน',
      requestDate: DateTime.now().subtract(const Duration(days: 1)),
      status: LoanApplicationStatus.pending,
      monthlySalary: 25000,
      currentDebt: 5000,
      requestTerm: 24,
    ),
    LoanApplication(
      id: 'REQ-2024-002',
      applicantName: 'วิชัย ใจมั่น',
      applicantId: '1100200333555',
      memberId: 'M00124',
      amount: 1500000,
      productName: 'เงินกู้สามัญ',
      requestDate: DateTime.now().subtract(const Duration(days: 2)),
      status: LoanApplicationStatus.pending,
      monthlySalary: 60000,
      currentDebt: 1200000,
      requestTerm: 120,
    ),
    LoanApplication(
      id: 'REQ-2024-003',
      applicantName: 'มานี มีตา',
      applicantId: '1100200333666',
      memberId: 'M00125',
      amount: 200000,
      productName: 'เงินกู้พิเศษ',
      requestDate: DateTime.now().subtract(const Duration(days: 5)),
      status: LoanApplicationStatus.approved,
      officerNote: 'เอกสารครบถ้วน เครดิตดี',
      monthlySalary: 45000,
      currentDebt: 10000,
      requestTerm: 60,
    ),
    LoanApplication(
      id: 'REQ-2024-004',
      applicantName: 'ปิติ พอใจ',
      applicantId: '1100200333777',
      memberId: 'M00126',
      amount: 3000000,
      productName: 'เงินกู้เพื่อที่อยู่อาศัย',
      requestDate: DateTime.now().subtract(const Duration(days: 10)),
      status: LoanApplicationStatus.rejected,
      officerNote: 'ภาระหนี้สินเกินเกณฑ์ที่กำหนด',
      monthlySalary: 35000,
      currentDebt: 20000,
      requestTerm: 360,
    ),
  ];
}
