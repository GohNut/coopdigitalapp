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
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
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

        return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('รายละเอียดสัญญา'),
              centerTitle: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // ยอดคงเหลือ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currencyFormat.format(loanDetails.remainingAmount),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('บาท', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('ยอดคงเหลือ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 12),
                        
                        // Progress Bar
                        Row(
                          children: [
                            Text(
                              '${loanDetails.paidInstallments}/${loanDetails.requestTerm} งวด',
                              style: TextStyle(fontSize: 14, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: loanDetails.requestTerm > 0 
                                      ? loanDetails.paidInstallments / loanDetails.requestTerm 
                                      : 0,
                                  minHeight: 8,
                                  backgroundColor: AppColors.background,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Officer Comment Section (Visible if exists)
                  if (loan.officerComment != null && loan.officerComment!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.messageSquare, size: 18, color: AppColors.info),
                              const SizedBox(width: 8),
                              Text(
                                'ความเห็นเจ้าหน้าที่',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loan.officerComment!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 12),

                  // Loan Details Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name + ID
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loanDetails.productName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                loan.applicationId,
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Info Grid
                        Row(
                          children: [
                            _buildInfoChip('ดอกเบี้ย', '${loanDetails.interestRate}% ต่อปี'),
                            const SizedBox(width: 10),
                            _buildInfoChip('งวดละ', '${currencyFormat.format(loanDetails.installmentAmount)} บ.'),
                            const SizedBox(width: 10),
                            _buildInfoChip('ระยะเวลา', '${loanDetails.requestTerm} เดือน'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // งวดถัดไป Card
                  if (loanDetails.paidInstallments < loanDetails.requestTerm)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('งวดถัดไป', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text(
                                    'งวดที่ ${loanDetails.paidInstallments + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('ครบกำหนด', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text(
                                    loanDetails.nextPaymentDate != null ? dateFormat.format(loanDetails.nextPaymentDate!) : '-',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Breakdown row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('เงินต้น ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text(
                                        currencyFormat.format(loanDetails.requestAmount / loanDetails.requestTerm),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 20, color: Colors.white30),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('ดอกเบี้ย ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text(
                                        currencyFormat.format((loanDetails.requestAmount * loanDetails.interestRate / 100) / 12),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 20, color: Colors.white30),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('รวม ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text(
                                        currencyFormat.format(loanDetails.installmentAmount),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // ปุ่มชำระค่างวด (กดได้เฉพาะสถานะ approved)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: loan.status == LoanApplicationStatus.approved
                          ? () => context.push('/loan/payment/${loan.applicationId}')
                          : null,
                      icon: const Icon(LucideIcons.creditCard, size: 20),
                      label: Text(
                        loan.status == LoanApplicationStatus.approved
                            ? 'ชำระค่างวด'
                            : 'ชำระค่างวด (${loan.status.toDisplayString()})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: loan.status == LoanApplicationStatus.approved
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // ประวัติการชำระ Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(LucideIcons.history, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'ประวัติการชำระ',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (loan.paymentHistory.isNotEmpty)
                                TextButton(
                                  onPressed: () => context.push('/loan/payment-history/${loan.applicationId}'),
                                  child: const Text('ดูทั้งหมด'),
                                ),
                            ],
                          ),
                        ),
                        if (loan.paymentHistory.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(LucideIcons.fileText, size: 40, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ยังไม่มีประวัติการชำระ',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // แสดง 3 รายการล่าสุด
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: loan.paymentHistory.length > 3 ? 3 : loan.paymentHistory.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final payment = loan.paymentHistory[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.success.withOpacity(0.1),
                                  radius: 18,
                                  child: Text(
                                    '${payment.installmentNo}',
                                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  'งวดที่ ${payment.installmentNo}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  dateFormat.format(payment.paidDate ?? payment.dueDate),
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currencyFormat.format(payment.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
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
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdownItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value บาท',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
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
