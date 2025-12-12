class LoanProduct {
  final String id;
  final String name;
  final String? nameEn;
  final String description;
  final double maxAmount;
  final double interestRate; // yearly percent
  final int maxMonths;
  final bool requireGuarantor;
  final List<String> conditions;
  final String? icon;

  const LoanProduct({
    required this.id,
    required this.name,
    this.nameEn,
    required this.description,
    required this.maxAmount,
    required this.interestRate,
    required this.maxMonths,
    required this.requireGuarantor,
    this.conditions = const [],
    this.icon,
  });

  factory LoanProduct.fromJson(Map<String, dynamic> json) {
    return LoanProduct(
      id: json['productid'] ?? json['id'],
      name: json['name'],
      nameEn: json['nameen'] ?? json['nameEn'],
      description: json['description'],
      maxAmount: (json['maxamount'] ?? json['maxAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestrate'] ?? json['interestRate'] as num?)?.toDouble() ?? 0.0,
      maxMonths: json['maxmonths'] ?? json['maxMonths'] ?? 12,
      requireGuarantor: json['requireguarantor'] ?? json['requireGuarantor'] ?? false,
      conditions: (json['conditions'] is List) 
          ? (json['conditions'] as List<dynamic>).map((e) => e.toString()).toList() 
          : [],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productid': id,
      'name': name,
      'nameen': nameEn,
      'description': description,
      'maxamount': maxAmount,
      'interestrate': interestRate,
      'maxmonths': maxMonths,
      'requireguarantor': requireGuarantor,
      'conditions': conditions,
      'icon': icon,
    };
  }

  // Deprecated: Use repository to fetch data
  static const List<LoanProduct> mockProducts = [];
}
