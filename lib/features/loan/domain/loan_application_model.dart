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

  factory Applicant.fromJson(Map<String, dynamic> json, {String? memberId}) {
    return Applicant(
      memberId: memberId ?? json['memberid'] ?? json['memberId'] ?? '',
      prefix: json['prefix'] ?? '',
      firstName: json['firstname'] ?? json['firstName'] ?? '',
      lastName: json['lastname'] ?? json['lastName'] ?? '',
      idCard: json['idcard'] ?? json['idCard'] ?? '',
      dateOfBirth: json['dateofbirth'] != null 
          ? DateTime.parse(json['dateofbirth']) 
          : (json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null),
      address: json['address'],
      mobile: json['mobile'],
      email: json['email'],
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      otherIncome: (json['otherincome'] ?? json['otherIncome'] as num?)?.toDouble() ?? 0.0,
      currentDebt: (json['currentdebt'] ?? json['currentDebt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberid': memberId,
      'prefix': prefix,
      'firstname': firstName,
      'lastname': lastName,
      'idcard': idCard,
      'dateofbirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'mobile': mobile,
      'email': email,
      'salary': salary,
      'otherincome': otherIncome,
      'currentdebt': currentDebt,
    };
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
    // Check if calculation object exists
    final calc = json['calculation'] ?? {};
    
    // Parse amounts first
    final requestAmount = (json['requestamount'] ?? json['requestAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (json['paidamount'] ?? json['paidAmount'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate remaining amount: use from JSON if exists, otherwise calculate
    double remainingAmount;
    if (json['remainingamount'] != null) {
      remainingAmount = (json['remainingamount'] as num).toDouble();
    } else if (json['remainingAmount'] != null) {
      remainingAmount = (json['remainingAmount'] as num).toDouble();
    } else {
      // Default: requestAmount - paidAmount (if not paid yet, remaining = full amount)
      remainingAmount = requestAmount - paidAmount;
    }

    return LoanDetails(
      productId: json['productid'] ?? json['productId'] ?? '',
      productName: json['productname'] ?? json['productName'] ?? '',
      requestAmount: requestAmount,
      approvedAmount: (json['approvedamount'] ?? json['approvedAmount'] as num?)?.toDouble(),
      requestTerm: json['requestterm'] ?? json['requestTerm'] ?? 0,
      interestRate: (json['interestrate'] ?? json['interestRate'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] ?? '',
      installmentAmount: (calc['installment_amount'] ?? json['installmentamount'] ?? json['installmentAmount'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (calc['total_payment'] ?? json['totalpayment'] ?? json['totalPayment'] as num?)?.toDouble() ?? 0.0,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      paidInstallments: json['paidinstallments'] ?? json['paidInstallments'] ?? 0,
      nextPaymentDate: json['nextpaymentdate'] != null 
          ? DateTime.parse(json['nextpaymentdate']) 
          : (json['nextPaymentDate'] != null ? DateTime.parse(json['nextPaymentDate']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productid': productId,
      'productname': productName,
      'requestamount': requestAmount,
      'approvedamount': approvedAmount,
      'requestterm': requestTerm,
      'interestrate': interestRate,
      'purpose': purpose,
      'installmentamount': installmentAmount,
      'totalpayment': totalPayment,
      'paidamount': paidAmount,
      'remainingamount': remainingAmount,
      'paidinstallments': paidInstallments,
      'nextpaymentdate': nextPaymentDate?.toIso8601String(),
    };
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
      memberId: json['memberid'] ?? json['memberId'],
      name: json['name'],
      relationship: json['relationship'],
      salary: (json['salary'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberid': memberId,
      'name': name,
      'relationship': relationship,
      'salary': salary,
    };
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
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      owner: json['owner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'value': value,
      'owner': owner,
    };
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
      collaterals: (json['collaterals'] is List)
              ? (json['collaterals'] as List<dynamic>)
                  .map((e) => Collateral.fromJson(e))
                  .toList()
              : [],
      guarantors: (json['guarantors'] is List)
              ? (json['guarantors'] as List<dynamic>)
                  .map((e) => Guarantor.fromJson(e))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collaterals': collaterals.map((e) => e.toJson()).toList(),
      'guarantors': guarantors.map((e) => e.toJson()).toList(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'status': status,
      'url': url,
    };
  }
}

class PaymentRecord {
  final int installmentNo;
  final int? installmentEnd; // For full payoff: shows range like งวดที่ 68-96
  final DateTime dueDate;
  final DateTime? paidDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? receiptNo;
  final String? paymentType; // 'normal', 'advance', 'payoff'
  final String? note;

  PaymentRecord({
    required this.installmentNo,
    this.installmentEnd,
    required this.dueDate,
    this.paidDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.receiptNo,
    this.paymentType,
    this.note,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      installmentNo: json['installmentno'] ?? json['installmentNo'] ?? 0,
      installmentEnd: json['installmentend'] ?? json['installmentEnd'],
      dueDate: DateTime.parse(json['duedate'] ?? json['dueDate'] ?? DateTime.now().toIso8601String()),
      paidDate: json['paiddate'] != null 
          ? DateTime.parse(json['paiddate']) 
          : (json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null),
      principalAmount: (json['principalamount'] ?? json['principalAmount'] as num?)?.toDouble() ?? 0.0,
      interestAmount: (json['interestamount'] ?? json['interestAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalamount'] ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'paid',
      paymentMethod: json['paymentmethod'] ?? json['paymentMethod'],
      receiptNo: json['receiptno'] ?? json['receiptNo'],
      paymentType: json['paymenttype'] ?? json['paymentType'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installmentno': installmentNo,
      'installmentend': installmentEnd,
      'duedate': dueDate.toIso8601String(),
      'paiddate': paidDate?.toIso8601String(),
      'principalamount': principalAmount,
      'interestamount': interestAmount,
      'totalamount': totalAmount,
      'status': status,
      'paymentmethod': paymentMethod,
      'receiptno': receiptNo,
      'paymenttype': paymentType,
      'note': note,
    };
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
    // Parser documents
    List<LoanDocument> docs = [];
    
    // 1. Try to parse from 'documents' list if exists
    if (json['documents'] is List) {
      docs = (json['documents'] as List<dynamic>)
          .map((e) => LoanDocument.fromJson(e))
          .toList();
    } 
    
    // 2. If docs is empty, try to map from individual filename fields (MongoDB structure)
    if (docs.isEmpty) {
      if (json['idcardfilename'] != null) {
        docs.add(LoanDocument(
          type: 'id_card',
          name: json['idcardfilename'],
          status: 'pending',
          url: null, // You might construct full URL here if needed
        ));
      }
      if (json['salaryslipfilename'] != null) {
        docs.add(LoanDocument(
          type: 'salary_slip',
          name: json['salaryslipfilename'],
          status: 'pending',
          url: null,
        ));
      }
      if (json['otherfilename'] != null) {
        docs.add(LoanDocument(
          type: 'other',
          name: json['otherfilename'],
          status: 'pending',
          url: null,
        ));
      }
    }

    return LoanApplication(
      applicationId: json['applicationid'] ?? json['applicationId'] ?? '',
      requestDate: DateTime.parse(json['requestdate'] ?? json['requestDate'] ?? json['createdat'] ?? DateTime.now().toIso8601String()),
      status: LoanApplicationStatus.fromString(json['status'] ?? 'pending'),
      // Pass memberid from root to Applicant if needed
      applicant: Applicant.fromJson(json['applicantinfo'] ?? json['applicant'] ?? {}, memberId: json['memberid']),
      // LoanDetails fields are at root or in loanDetails
      loanDetails: LoanDetails.fromJson(json['loanDetails'] ?? json),
      security: Security.fromJson(json['securityinfo'] ?? json['security'] ?? {}),
      documents: docs,
      paymentHistory: (json['paymenthistory'] ?? json['paymentHistory']) is List
              ? ((json['paymenthistory'] ?? json['paymentHistory']) as List<dynamic>)
                  .map((e) => PaymentRecord.fromJson(e))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationid': applicationId,
      'memberid': applicant.memberId, // Important for indexing
      'requestdate': requestDate.toIso8601String(),
      'status': status.name, // or status.toString().split('.').last
      'applicantinfo': applicant.toJson(),
      // Flatten LoanDetails into root
      ...loanDetails.toJson(),
      'securityinfo': security.toJson(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'paymenthistory': paymentHistory.map((e) => e.toJson()).toList(),
    };
  }

  // Legacy mock data compatible getter (optional, but keeping it empty for now as we want to use the repository)
  static List<LoanApplication> get mockApplications => []; 
}

