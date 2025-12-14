import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../domain/models/share_model.dart';
import '../../presentation/widgets/wealth_calculator.dart';
import 'package:intl/intl.dart';
import '../../domain/models/share_transaction.dart';
import '../../domain/models/dividend_model.dart';
import '../../data/repositories/dividend_repository_impl.dart';

class ShareDashboardScreen extends StatefulWidget {
  const ShareDashboardScreen({super.key});

  @override
  State<ShareDashboardScreen> createState() => _ShareDashboardScreenState();
}

class _ShareDashboardScreenState extends State<ShareDashboardScreen> with WidgetsBindingObserver {
  final _repository = ShareRepositoryImpl();
  final _dividendRepository = DividendRepositoryImpl();
  ShareModel? _shareData;
  List<ShareTransaction> _recentTransactions = [];
  DividendSummary? _dividendSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); // Refresh when app comes to foreground
    }
  }

  // Note: ไม่ต้องใช้ didChangeDependencies เพราะ go_router จะสร้าง widget ใหม่เมื่อ navigate ด้วย go()

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _repository.getShareInfo();
      final transactions = await _repository.getShareHistory();
      final dividend = await _dividendRepository.calculateDividend(DateTime.now().year);
      
      if (mounted) {
        setState(() {
          _shareData = data;
          _recentTransactions = transactions;
          _dividendSummary = dividend;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _shareData!;
    final currencyFormat = NumberFormat("#,##0", "th_TH");
    final unitsFormat = NumberFormat("#,##0", "th_TH");

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('หุ้นสหกรณ์', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
             if (context.canPop()) {
               context.pop();
             } else {
               context.go('/home');
             }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Portfolio Pie Chart & Summary
             _buildPortfolioSummary(data, currencyFormat, unitsFormat),
             const SizedBox(height: 24),

            // 2. Share Info Card (Price)
            _buildShareInfoRow(currencyFormat, data),
            const SizedBox(height: 24),

            // 3. Dividend Card
            _buildDividendCard(currencyFormat),
            const SizedBox(height: 24),

            // 4. User Actions (Buy/Sell/History)
            _buildActionButtons(context),
            const SizedBox(height: 24),
            
            // 4. History Button Bar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.history),
                label: const Text("ดูประวัติทั้งหมด"),
                onPressed: () => context.go('/share/history'),
                style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
             const SizedBox(height: 24),
             
             // Bonus: Wealth Calc Entry
             Center(
               child: TextButton.icon(
                 icon: const Icon(LucideIcons.calculator, size: 16, color: Colors.grey),
                 label: const Text('เครื่องคำนวณความมั่งคั่ง', style: TextStyle(color: Colors.grey)),
                 onPressed: () {
                     showDialog(
                       context: context,
                       builder: (context) => const WealthCalculatorDialog(),
                     );
                 },
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary(ShareModel data, NumberFormat currency, NumberFormat units) {
     // คำนวณข้อมูลกราฟจาก transactions จริง (12 เดือนล่าสุด)
     final months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
     
     // คำนวณมูลค่าสะสมจาก transactions จริงเท่านั้น
     List<double> values = List.filled(12, 0.0);
     
     if (_recentTransactions.isNotEmpty) {
       // เรียงข้อมูล transactions ตามวันที่
       final sortedTransactions = List<ShareTransaction>.from(_recentTransactions)
         ..sort((a, b) => a.date.compareTo(b.date));
       
       double cumulativeValue = 0;
       final now = DateTime.now();
       
       // วนลูปทุก transaction และ update ค่าสะสม
       for (var transaction in sortedTransactions) {
         cumulativeValue += transaction.amount;
         
         // หาว่า transaction นี้อยู่เดือนไหนใน 12 เดือนย้อนหลัง
         final monthsAgo = (now.year - transaction.date.year) * 12 + 
                          (now.month - transaction.date.month);
         
         if (monthsAgo >= 0 && monthsAgo < 12) {
           final index = 11 - monthsAgo; // เดือนปัจจุบันอยู่ที่ index 11
           values[index] = cumulativeValue;
         }
       }
       
       // กรอกค่าที่ว่างด้วยค่าจากเดือนก่อนหน้า (carry forward)
       for (int i = 1; i < 12; i++) {
         if (values[i] == 0.0 && values[i - 1] > 0.0) {
           values[i] = values[i - 1];
         }
       }
     }
     
     // คำนวณ minY/maxY จากข้อมูลจริง
     final nonZeroValues = values.where((v) => v > 0).toList();
     double chartMinY = 0;
     double chartMaxY = 10000; // default
     
     if (nonZeroValues.isNotEmpty) {
       final maxValue = nonZeroValues.reduce((a, b) => a > b ? a : b);
       final minValue = nonZeroValues.reduce((a, b) => a < b ? a : b);
       final range = maxValue - minValue;
       chartMinY = range > 0 ? (minValue - range * 0.2).clamp(0.0, double.infinity) : 0;
       chartMaxY = maxValue + (range > 0 ? range * 0.2 : maxValue * 0.2);
     }

     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Value Header
            const Text('มูลค่าหุ้นรวม', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
           Row(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text('฿${currency.format(data.totalValue)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
               const SizedBox(width: 8),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trendingUp, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('+5.9%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
             ],
           ),
           Text('${units.format(data.totalUnits)} หุ้น', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
           const SizedBox(height: 20),
           
           // Chart Title
           const Text('การเติบโตของเงินออม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
           const SizedBox(height: 16),

           // Area Line Chart (ใช้ ClipRect เพื่อป้องกันจุดทะลุขอบ)
           ClipRect(
             child: SizedBox(
              height: 160,
              child: LineChart(
               LineChartData(
                 gridData: FlGridData(
                   show: true,
                   drawVerticalLine: false,
                   horizontalInterval: 25000,
                   getDrawingHorizontalLine: (value) => FlLine(
                     color: Colors.grey.shade200,
                     strokeWidth: 1,
                   ),
                 ),
                 titlesData: FlTitlesData(
                   leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   bottomTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: 28,
                       interval: 1, // Force 1 interval to prevent double labels
                       getTitlesWidget: (value, meta) {
                         final index = value.toInt();
                         if (index >= 0 && index < months.length && index == value) {
                           return Padding(
                             padding: const EdgeInsets.only(top: 6),
                             child: Text(months[index], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                           );
                         }
                         return const SizedBox.shrink();
                       },
                     ),
                   ),
                 ),
                 borderData: FlBorderData(show: false),
                 minX: 0,
                 maxX: (months.length - 1).toDouble(),
                 minY: chartMinY,
                 maxY: chartMaxY,
                 lineBarsData: [
                   LineChartBarData(
                     spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                     isCurved: true,
                     color: Colors.pink, // Pink line
                     barWidth: 3,
                     isStrokeCapRound: true,
                     dotData: FlDotData(
                       show: true,
                       getDotPainter: (spot, percent, barData, index) {
                         return FlDotCirclePainter(
                           radius: index == values.length - 1 ? 6 : 4,
                           color: Colors.pink, // Pink dot
                           strokeWidth: 2,
                           strokeColor: Colors.white,
                         );
                       },
                     ),
                     belowBarData: BarAreaData(
                       show: true,
                       gradient: LinearGradient(
                         colors: [
                           Colors.pink.withOpacity(0.3),
                           Colors.pink.withOpacity(0.05),
                         ],
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                       ),
                     ),
                   ),
                 ],
                 lineTouchData: LineTouchData(
                   touchTooltipData: LineTouchTooltipData(
                     getTooltipItems: (touchedSpots) {
                       return touchedSpots.map((spot) {
                         return LineTooltipItem(
                           '฿${currency.format(spot.y)}',
                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                         );
                       }).toList();
                     },
                   ),
                 ),
               ),
             ),
           ),
           ),
         ],
       ),
     );
  }

  Widget _buildShareInfoRow(NumberFormat currency, ShareModel data) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard('ราคาต่อหุ้น', '${currency.format(data.shareParValue)} บาท', LucideIcons.tag, Colors.blue),
        ),
      ],
    );
  }

    Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 8,
             offset: const Offset(0, 4),
           )
         ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: color, size: 20),
           const SizedBox(height: 12),
           Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
           const SizedBox(height: 4),
           Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDividendCard(NumberFormat currency) {
    final dividend = _dividendSummary;
    if (dividend == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => context.push('/share/dividend'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4EFF), Color(0xFF9747FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.gift, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เงินปันผลโดยประมาณ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('฿${currency.format(dividend.totalAmount)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${dividend.rate}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: Colors.white),
          ],
        ),
      ),
    );
  }

   Widget _buildActionButtons(BuildContext context) {
     return SizedBox(
       width: double.infinity,
       child: ElevatedButton.icon(
         icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
         label: const Text('ซื้อหุ้น', style: TextStyle(color: Colors.white)),
         onPressed: () => context.go('/share/buy'),
         style: ElevatedButton.styleFrom(
           backgroundColor: const Color(0xFF10B981), // Green
           padding: const EdgeInsets.symmetric(vertical: 16),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         ),
       ),
     );
   }
}
