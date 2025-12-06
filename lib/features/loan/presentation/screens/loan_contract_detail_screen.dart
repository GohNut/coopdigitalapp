import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class LoanContractDetailScreen extends StatelessWidget {
  final String contractId;

  const LoanContractDetailScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('รายละเอียดสัญญา'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
          children: [
            // Header Section - ยอดคงเหลือ + Progress
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  Text('ยอดคงเหลือ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '฿ 35,000.00',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar พร้อมตัวเลขงวด
                  Row(
                    children: [
                      // งวดที่ชำระแล้ว
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '2/12 งวด',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Progress Bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: 2/12, // 2 งวดจาก 12
                            minHeight: 10,
                            backgroundColor: AppColors.background,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // ข้อมูลสรุป
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('ชำระแล้ว', '฿15,000'),
                      Container(width: 1, height: 24, color: AppColors.background),
                      _buildMiniStat('คงเหลือ', '฿35,000'),
                      Container(width: 1, height: 24, color: AppColors.background),
                      _buildMiniStat('วงเงินกู้', '฿50,000'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Loan Details Section - รายละเอียดสินเชื่อ (Grid กระชับ)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เงินกู้สามัญ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LN-2024-001234',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid 2 คอลัมน์ - ไม่ซ้ำซ้อน
                  Row(
                    children: [
                      Expanded(child: _buildCompactInfo('ดอกเบี้ย', '6% ต่อปี')),
                      Expanded(child: _buildCompactInfo('ผ่อน/งวด', '฿4,416')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCompactInfo('วันที่กู้', '25 ม.ค. 67')),
                      Expanded(child: _buildCompactInfo('ครบกำหนด', '25 ธ.ค. 67')),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // งวดถัดไป Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.bell, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'งวดถัดไป',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'งวดที่ 3 • 25 มี.ค. 2567',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '฿4,396',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'งวดรอชำระ'),
                  Tab(text: 'ประวัติการชำระ'),
                ],
              ),
            ),

            // Tab View - ใช้ SizedBox แทน Expanded เพราะอยู่ใน SingleChildScrollView
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  _buildScheduleList(context, isHistory: false),
                  _buildScheduleList(context, isHistory: true),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }

  // Helper method สำหรับแสดง stat ขนาดเล็ก
  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper method สำหรับแสดงข้อมูลแบบกระชับ (Grid)
  Widget _buildCompactInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper method สำหรับแสดงแถวรายละเอียด
  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.primary.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(BuildContext context, {required bool isHistory}) {
    // Mock Data
    final List<Map<String, dynamic>> items = isHistory 
    ? [
        {'no': 1, 'date': '25 Jan 2024', 'principal': 4166, 'interest': 250, 'total': 4416, 'status': 'Paid'},
        {'no': 2, 'date': '25 Feb 2024', 'principal': 4166, 'interest': 240, 'total': 4406, 'status': 'Paid'},
      ] 
    : [
         {'no': 3, 'date': '25 Mar 2024', 'principal': 4166, 'interest': 230, 'total': 4396, 'status': 'Pending'},
         {'no': 4, 'date': '25 Apr 2024', 'principal': 4166, 'interest': 220, 'total': 4386, 'status': 'Pending'},
         {'no': 5, 'date': '25 May 2024', 'principal': 4166, 'interest': 210, 'total': 4376, 'status': 'Pending'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isHistory ? AppColors.success.withOpacity(0.1) : AppColors.background,
              child: Text('${item['no']}', style: TextStyle(color: isHistory ? AppColors.success : AppColors.textPrimary)),
            ),
            title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Text('ต้น ${item['principal']}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text('ดอก ${item['interest']}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('฿${NumberFormat('#,##0').format(item['total'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if(isHistory)
                  const Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
              ],
            ),
          ),
        );
      },
    );
  }
}
