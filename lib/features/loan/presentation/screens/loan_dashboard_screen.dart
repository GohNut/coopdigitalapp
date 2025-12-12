import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/loan_overview_card.dart';
import '../widgets/active_loan_card.dart';
import '../../data/loan_repository_impl.dart';
import '../../domain/loan_application_model.dart';
import 'package:intl/intl.dart';

class LoanDashboardScreen extends StatelessWidget {
  const LoanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LoanRepositoryImpl();
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สินเชื่อของฉัน', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.home, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: FutureBuilder<List<LoanApplication>>(
        future: repository.getLoanApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final applications = snapshot.data ?? [];
          final approvedLoans = applications.where((app) => app.status == LoanApplicationStatus.approved).toList();
          
          // Calculate totals from JSON data
          double totalOutstanding = 0;
          double totalLimit = 0;
          for (var loan in approvedLoans) {
            totalOutstanding += loan.loanDetails.remainingAmount;
            totalLimit += loan.loanDetails.requestAmount;
          }
          
          // Get next payment info from first approved loan
          final nextPaymentLoan = approvedLoans.isNotEmpty ? approvedLoans.first : null;
          final dateFormat = DateFormat('dd MMM yyyy', 'th');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loan Overview Card with real data
                LoanOverviewCard(
                  totalOutstanding: totalOutstanding,
                  totalLimit: totalLimit,
                ),
                
                // Next Payment Info Section
                if (approvedLoans.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.calendarClock, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ยอดที่ต้องชำระถัดไป',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      const TextSpan(text: 'ครบกำหนด '),
                                      TextSpan(
                                        text: nextPaymentLoan?.loanDetails.nextPaymentDate != null
                                            ? dateFormat.format(nextPaymentLoan!.loanDetails.nextPaymentDate!)
                                            : '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            approvedLoans.isNotEmpty 
                                ? currencyFormat.format(approvedLoans.first.loanDetails.installmentAmount)
                                : '฿ 0',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                
                // Active Loan Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'สินเชื่อปัจจุบัน',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/loan/tracking');
                        },
                        child: const Text('ดูทั้งหมด'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Display approved loans
                if (approvedLoans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีสินเชื่อที่อนุมัติ',
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: approvedLoans.length,
                      itemBuilder: (context, index) {
                        final loan = approvedLoans[index];
                        return ActiveLoanCard(
                          loanType: loan.productName,
                          contractNumber: loan.applicationId,
                          principal: loan.loanDetails.requestAmount,
                          paid: loan.loanDetails.paidAmount,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 100), // Spacing for bottom button
              ],
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: FloatingActionButton.extended(
            onPressed: () {
              context.go('/loan/products');
            },
            backgroundColor: AppColors.primary,
            label: const Text('สมัครสินเชื่อใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
            elevation: 4,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
