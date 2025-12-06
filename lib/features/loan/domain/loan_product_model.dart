class LoanProduct {
  final String id;
  final String name;
  final String description;
  final double maxAmount;
  final double interestRate; // yearly percent
  final int maxMonths;
  final String collateral;
  final bool requireGuarantor;

  const LoanProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.maxAmount,
    required this.interestRate,
    required this.maxMonths,
    required this.requireGuarantor,
    required this.collateral,
  });

  // Mock Data
  static const List<LoanProduct> mockProducts = [
    LoanProduct(
      id: 'ordinary',
      name: 'เงินกู้สามัญ (Ordinary Loan)',
      description: 'วงเงินสูง (หลักแสน-ล้าน) เหมาะสำหรับการลงทุนหรือค่าใช้จ่ายทั่วไป',
      maxAmount: 2000000,
      interestRate: 5.75,
      maxMonths: 120,
      requireGuarantor: true,
      collateral: 'บุคคลค้ำ/หลักทรัพย์',
    ),
    LoanProduct(
      id: 'emergency',
      name: 'เงินกู้ฉุกเฉิน (Emergency Loan)',
      description: 'วงเงิน 1-2 เท่าของเงินเดือน อนุมัติด่วน',
      maxAmount: 50000,
      interestRate: 6.0,
      maxMonths: 24,
      requireGuarantor: false,
      collateral: 'ใช้หุ้นค้ำประกัน (ไม่ต้องมีบุคคลค้ำ)',
    ),
    LoanProduct(
      id: 'special',
      name: 'เงินกู้พิเศษ (Special Loan)',
      description: 'เพื่อวัตถุประสงค์เฉพาะ เช่น ซื้อคอมพิวเตอร์ หรือการศึกษา',
      maxAmount: 500000,
      interestRate: 4.5,
      maxMonths: 60,
      requireGuarantor: true,
      collateral: 'บุคคลค้ำประกัน',
    ),
    LoanProduct(
      id: 'housing',
      name: 'เงินกู้เพื่อที่อยู่อาศัย (Housing Loan)',
      description: 'วงเงินสูงมาก ผ่อนยาว 20-30 ปี สำหรับซื้อ/สร้างบ้าน',
      maxAmount: 10000000,
      interestRate: 3.5,
      maxMonths: 360,
      requireGuarantor: false,
      collateral: 'จำนองโฉนดที่ดิน',
    ),
  ];
}
