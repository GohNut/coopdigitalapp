class ShareType {
  final String id;
  final String name;
  final double price;
  final String status;

  const ShareType({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
  });

  factory ShareType.fromJson(Map<String, dynamic> json) {
    return ShareType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'status': status,
    };
  }
}
