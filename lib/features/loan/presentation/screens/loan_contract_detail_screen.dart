import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/loan_repository_impl.dart';
import '../../domain/loan_application_model.dart';

class LoanContractDetailScreen extends StatelessWidget {
  final String contractId;

  const LoanContractDetailScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context) {
    final repository = LoanRepositoryImpl();
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'th');

    return FutureBuilder<List<LoanApplication>>(
      future: repository.getLoanApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('รายละเอียดสัญญา')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('รายละเอียดสัญญา')),
            body: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
          );
        }

        final applications = snapshot.data ?? [];
        final loan = applications.firstWhere(
          (app) => app.applicationId == contractId,
          orElse: () => applications.first,
        );

        final loanDetails = loan.loanDetails;
        final progress = loanDetails.requestAmount > 0 
            ? loanDetails.paidAmount / loanDetails.requestAmount 
            : 0.0;

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
                        Text(
                          'ยอดคงเหลือ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(loanDetails.remainingAmount),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Progress Bar พร้อมตัวเลขงวด
                        Row(
                          children: [
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
                                    '${loanDetails.paidInstallments}/${loanDetails.requestTerm} งวด',
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
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: loanDetails.requestTerm > 0 
                                      ? loanDetails.paidInstallments / loanDetails.requestTerm 
                                      : 0,
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
                            _buildMiniStat('ชำระแล้ว', currencyFormat.format(loanDetails.paidAmount)),
                            Container(width: 1, height: 24, color: AppColors.background),
                            _buildMiniStat('คงเหลือ', currencyFormat.format(loanDetails.remainingAmount)),
                            Container(width: 1, height: 24, color: AppColors.background),
                            _buildMiniStat('วงเงินกู้', currencyFormat.format(loanDetails.requestAmount)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Loan Details Section
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loanDetails.productName,
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
                                loan.applicationId,
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
                        
                        Row(
                          children: [
                            Expanded(child: _buildCompactInfo('ดอกเบี้ย', '${loanDetails.interestRate}% ต่อปี')),
                            Expanded(child: _buildCompactInfo('ผ่อน/งวด', currencyFormat.format(loanDetails.installmentAmount))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildCompactInfo('วันที่กู้', dateFormat.format(loan.requestDate))),
                            Expanded(child: _buildCompactInfo(
                              'ครบกำหนด', 
                              loanDetails.nextPaymentDate != null 
                                  ? dateFormat.format(loanDetails.nextPaymentDate!)
                                  : '-',
                            )),
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
                                'งวดที่ ${loanDetails.paidInstallments + 1} • ${loanDetails.nextPaymentDate != null ? dateFormat.format(loanDetails.nextPaymentDate!) : '-'}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(loanDetails.installmentAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // ปุ่มชำระค่างวด
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/loan/payment/${loan.applicationId}'),
                      icon: const Icon(LucideIcons.creditCard, size: 20),
                      label: const Text(
                        'ชำระค่างวด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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

                  // Tab View
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildScheduleList(context, loan: loan, isHistory: false),
                        _buildScheduleList(context, loan: loan, isHistory: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildScheduleList(BuildContext context, {required LoanApplication loan, required bool isHistory}) {
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'th');
    final loanDetails = loan.loanDetails;
    final monthlyPrincipal = loanDetails.requestAmount / loanDetails.requestTerm;
    final monthlyInterest = (loanDetails.requestAmount * loanDetails.interestRate / 100) / 12;
    
    // Check if loan is closed
    final isClosed = loan.status.name == 'closed' || loanDetails.paidInstallments >= loanDetails.requestTerm;
    
    if (isHistory) {
      // Use actual paymentHistory from JSON
      final payments = loan.paymentHistory;
      
      if (payments.isEmpty) {
        return const Center(
          child: Text(
            'ยังไม่มีประวัติการชำระ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final payment = payments[index];
          
          // Determine badge and title based on payment type
          String title;
          Widget? badge;
          
          if (payment.paymentType == 'payoff') {
            // Full payoff: Show range
            title = payment.installmentEnd != null 
                ? 'งวดที่ ${payment.installmentNo}-${payment.installmentEnd}'
                : 'ปิดยอดกู้ทั้งหมด';
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ปิดยอดกู้',
                style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
              ),
            );
          } else if (payment.paymentType == 'advance') {
            title = 'งวดที่ ${payment.installmentNo}';
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ล่วงหน้า',
                style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            title = 'งวดที่ ${payment.installmentNo}';
            badge = null;
          }
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withOpacity(0.1),
                child: payment.paymentType == 'payoff'
                    ? const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 20)
                    : Text('${payment.installmentNo}', style: const TextStyle(color: AppColors.success)),
              ),
              title: Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(payment.paidDate ?? payment.dueDate),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (payment.note != null) 
                    Text(payment.note!, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFormat.format(payment.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // PENDING INSTALLMENTS
      
      // If loan is closed, show success message
      if (isClosed) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              const Text(
                'สินเชื่อปิดยอดเรียบร้อยแล้ว',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ไม่มีงวดที่ต้องชำระ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      
      // Generate pending installments based on paidInstallments
      List<Map<String, dynamic>> items = [];
      for (int i = loanDetails.paidInstallments + 1; i <= loanDetails.requestTerm && i <= loanDetails.paidInstallments + 5; i++) {
        items.add({
          'no': i,
          'date': '25 ${_getMonthName(i)} 2567',
          'principal': monthlyPrincipal.round(),
          'interest': monthlyInterest.round(),
          'total': loanDetails.installmentAmount.round(),
        });
      }

      if (items.isEmpty) {
        return const Center(
          child: Text(
            'ไม่มีงวดที่ต้องชำระ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

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
                backgroundColor: AppColors.background,
                child: Text('${item['no']}', style: const TextStyle(color: AppColors.textPrimary)),
              ),
              title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  Text('ต้น ${currencyFormat.format(item['principal'])}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('ดอก ${currencyFormat.format(item['interest'])}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                ],
              ),
              trailing: Text(currencyFormat.format(item['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      );
    }
  }

  String _getMonthName(int monthIndex) {
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return months[(monthIndex - 1) % 12];
  }
}
