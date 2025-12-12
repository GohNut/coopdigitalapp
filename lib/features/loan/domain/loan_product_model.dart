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
      id: json['id'],
      name: json['name'],
      nameEn: json['nameEn'],
      description: json['description'],
      maxAmount: (json['maxAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      maxMonths: json['maxMonths'],
      requireGuarantor: json['requireGuarantor'] ?? false,
      conditions: (json['conditions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      icon: json['icon'],
    );
  }

  // Deprecated: Use repository to fetch data
  static const List<LoanProduct> mockProducts = [];
}
