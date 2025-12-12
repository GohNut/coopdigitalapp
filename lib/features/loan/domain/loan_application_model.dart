enum LoanApplicationStatus {
  pending,
  approved,
  rejected;

  static LoanApplicationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LoanApplicationStatus.approved;
      case 'rejected':
        return LoanApplicationStatus.rejected;
      default:
        return LoanApplicationStatus.pending;
    }
  }

  String toDisplayString() {
    switch (this) {
      case LoanApplicationStatus.pending: return 'รอพิจารณา';
      case LoanApplicationStatus.approved: return 'อนุมัติ';
      case LoanApplicationStatus.rejected: return 'ปฏิเสธ';
    }
  }
}

class Applicant {
  final String memberId;
  final String prefix;
  final String firstName;
  final String lastName;
  final String idCard;
  final DateTime? dateOfBirth;
  final String? address;
  final String? mobile;
  final String? email;
  final double salary;
  final double otherIncome;
  final double currentDebt;

  String get fullName => '$prefix$firstName $lastName';

  Applicant({
    required this.memberId,
    this.prefix = '',
    required this.firstName,
    required this.lastName,
    required this.idCard,
    this.dateOfBirth,
    this.address,
    this.mobile,
    this.email,
    required this.salary,
    this.otherIncome = 0,
    required this.currentDebt,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      memberId: json['memberId'],
      prefix: json['prefix'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      idCard: json['idCard'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      address: json['address'],
      mobile: json['mobile'],
      email: json['email'],
      salary: (json['salary'] as num).toDouble(),
      otherIncome: (json['otherIncome'] as num?)?.toDouble() ?? 0,
      currentDebt: (json['currentDebt'] as num).toDouble(),
    );
  }
}

class LoanDetails {
  final String productId;
  final String productName;
  final double requestAmount;
  final double? approvedAmount;
  final int requestTerm;
  final double interestRate;
  final String purpose;
  final double installmentAmount;
  final double totalPayment;
  final double paidAmount;
  final double remainingAmount;
  final int paidInstallments;
  final DateTime? nextPaymentDate;

  LoanDetails({
    required this.productId,
    required this.productName,
    required this.requestAmount,
    this.approvedAmount,
    required this.requestTerm,
    required this.interestRate,
    required this.purpose,
    required this.installmentAmount,
    required this.totalPayment,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paidInstallments,
    this.nextPaymentDate,
  });

  factory LoanDetails.fromJson(Map<String, dynamic> json) {
    return LoanDetails(
      productId: json['productId'],
      productName: json['productName'],
      requestAmount: (json['requestAmount'] as num).toDouble(),
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      requestTerm: json['requestTerm'],
      interestRate: (json['interestRate'] as num).toDouble(),
      purpose: json['purpose'],
      installmentAmount: (json['installmentAmount'] as num).toDouble(),
      totalPayment: (json['totalPayment'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      paidInstallments: json['paidInstallments'] ?? 0,
      nextPaymentDate: json['nextPaymentDate'] != null 
          ? DateTime.parse(json['nextPaymentDate']) 
          : null,
    );
  }
}

class Guarantor {
  final String memberId;
  final String name;
  final String relationship;
  final double? salary;

  Guarantor({
    required this.memberId,
    required this.name,
    required this.relationship,
    this.salary,
  });

  factory Guarantor.fromJson(Map<String, dynamic> json) {
    return Guarantor(
      memberId: json['memberId'],
      name: json['name'],
      relationship: json['relationship'],
      salary: (json['salary'] as num?)?.toDouble(),
    );
  }
}

class Collateral {
  final String type;
  final String description;
  final double value;
  final String? owner;

  Collateral({
    required this.type,
    required this.description,
    required this.value,
    this.owner,
  });

  factory Collateral.fromJson(Map<String, dynamic> json) {
    return Collateral(
      type: json['type'],
      description: json['description'],
      value: (json['value'] as num).toDouble(),
      owner: json['owner'],
    );
  }
}

class Security {
  final List<Collateral> collaterals;
  final List<Guarantor> guarantors;

  Security({
    this.collaterals = const [],
    this.guarantors = const [],
  });

  factory Security.fromJson(Map<String, dynamic> json) {
    return Security(
      collaterals: (json['collaterals'] as List<dynamic>?)
              ?.map((e) => Collateral.fromJson(e))
              .toList() ??
          [],
      guarantors: (json['guarantors'] as List<dynamic>?)
              ?.map((e) => Guarantor.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LoanDocument {
  final String type;
  final String name;
  final String status;
  final String? url;

  LoanDocument({
    required this.type,
    required this.name,
    required this.status,
    this.url,
  });

  factory LoanDocument.fromJson(Map<String, dynamic> json) {
    return LoanDocument(
      type: json['type'],
      name: json['name'],
      status: json['status'],
      url: json['url'],
    );
  }
}

class PaymentRecord {
  final int installmentNo;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? receiptNo;

  PaymentRecord({
    required this.installmentNo,
    required this.dueDate,
    this.paidDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.receiptNo,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      installmentNo: json['installmentNo'],
      dueDate: DateTime.parse(json['dueDate']),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestAmount: (json['interestAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      receiptNo: json['receiptNo'],
    );
  }
}

class LoanApplication {
  final String applicationId;
  final DateTime requestDate;
  final LoanApplicationStatus status;
  final Applicant applicant;
  final LoanDetails loanDetails;
  final Security security;
  final List<LoanDocument> documents;
  final List<PaymentRecord> paymentHistory;

  // Helpers for backward compatibility or easy access
  String get id => applicationId;
  String get applicantName => applicant.fullName;
  String get applicantId => applicant.idCard;
  String get memberId => applicant.memberId;
  double get amount => loanDetails.requestAmount;
  String get productName => loanDetails.productName;
  double get monthlySalary => applicant.salary;
  double get currentDebt => applicant.currentDebt;
  int get requestTerm => loanDetails.requestTerm;
  
  LoanApplication({
    required this.applicationId,
    required this.requestDate,
    required this.status,
    required this.applicant,
    required this.loanDetails,
    required this.security,
    required this.documents,
    this.paymentHistory = const [],
  });

  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      applicationId: json['applicationId'],
      requestDate: DateTime.parse(json['requestDate']),
      status: LoanApplicationStatus.fromString(json['status']),
      applicant: Applicant.fromJson(json['applicant']),
      loanDetails: LoanDetails.fromJson(json['loanDetails']),
      security: Security.fromJson(json['security']),
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => LoanDocument.fromJson(e))
              .toList() ??
          [],
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Legacy mock data compatible getter (optional, but keeping it empty for now as we want to use the repository)
  static List<LoanApplication> get mockApplications => []; 
}

