import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/loan_overview_card.dart';
import '../../data/loan_repository_impl.dart';
import '../../domain/loan_application_model.dart';
import 'package:intl/intl.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = LoanRepositoryImpl();
  late Future<List<LoanApplication>> _loansFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loansFuture = _repository.getLoanApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter helpers
  List<LoanApplication> _filterLoans(List<LoanApplication> loans, String statusFilter) {
    switch (statusFilter) {
      case 'Active':
        return loans.where((l) => l.status == LoanApplicationStatus.approved && l.loanDetails.remainingAmount > 0).toList();
      case 'Closed':
        return loans.where((l) => l.status == LoanApplicationStatus.approved && l.loanDetails.remainingAmount <= 0).toList();
      case 'Pending':
        return loans.where((l) => l.status == LoanApplicationStatus.pending).toList();
      case 'Rejected':
        return loans.where((l) => l.status == LoanApplicationStatus.rejected).toList();
      default: // 'All'
        return loans;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<LoanApplication>>(
        future: _loansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('สินเชื่อของฉัน')),
              body: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
            );
          }

          final applications = snapshot.data ?? [];
          final approvedLoans = applications.where((app) => app.status == LoanApplicationStatus.approved).toList();
          
          // Calculate totals
          double totalOutstanding = 0;
          double totalLimit = 0;
          for (var loan in approvedLoans) {
            totalOutstanding += loan.loanDetails.remainingAmount;
            totalLimit += loan.loanDetails.requestAmount;
          }
          
          // Get counts for tabs
          final allCount = applications.length;
          final activeCount = _filterLoans(applications, 'Active').length;
          final closedCount = _filterLoans(applications, 'Closed').length;
          final pendingCount = _filterLoans(applications, 'Pending').length;
          final rejectedCount = _filterLoans(applications, 'Rejected').length;
          
          // Get next payment info from first active loan
          final activeLoans = _filterLoans(applications, 'Active');
          final nextPaymentLoan = activeLoans.isNotEmpty ? activeLoans.first : null;
          final dateFormat = DateFormat('dd MMM yyyy', 'th');

          return Column(
            children: [
              // AppBar - Fixed
              AppBar(
                title: const Text('สินเชื่อของฉัน', style: TextStyle(color: Colors.white)),
                centerTitle: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.filePlus, color: Colors.white),
                    tooltip: 'สมัครสินเชื่อใหม่',
                    onPressed: () => context.go('/loan/products'),
                  ),
                ],
              ),
              // Fixed Header Section (Loan Overview + Next Payment + Tabs)
              Container(
                color: AppColors.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loan Overview Card
                    LoanOverviewCard(
                      totalOutstanding: totalOutstanding,
                      totalLimit: totalLimit,
                    ),
                    // Next Payment Info Section
                    if (activeLoans.isNotEmpty)
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 0,
                                child: Text(
                                  currencyFormat.format(nextPaymentLoan?.loanDetails.installmentAmount ?? 0),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // TabBar - Fixed
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: 'ทั้งหมด ($allCount)'),
                          Tab(text: 'กำลังชำระ ($activeCount)'),
                          Tab(text: 'ชำระครบ ($closedCount)'),
                          Tab(text: 'รออนุมัติ ($pendingCount)'),
                          Tab(text: 'ไม่อนุมัติ ($rejectedCount)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable TabBarView - Takes remaining space
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoanList(context, applications, 'All'),
                    _buildLoanList(context, applications, 'Active'),
                    _buildLoanList(context, applications, 'Closed'),
                    _buildLoanList(context, applications, 'Pending'),
                    _buildLoanList(context, applications, 'Rejected'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoanList(BuildContext context, List<LoanApplication> allLoans, String statusFilter) {
    final filteredLoans = _filterLoans(allLoans, statusFilter);

    if (filteredLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(statusFilter),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredLoans.length + 1, // +1 for add card
      itemBuilder: (context, index) {
        // Last item is "Add Loan" card
        if (index == filteredLoans.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _AddLoanCard(
              onTap: () => context.go('/loan/products'),
            ),
          );
        }
        // Loan cards
        final loan = filteredLoans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LoanStatusCard(loan: loan),
        );
      },
    );
  }

  String _getEmptyMessage(String statusFilter) {
    switch (statusFilter) {
      case 'Active':
        return 'ไม่มีสินเชื่อที่กำลังชำระ';
      case 'Closed':
        return 'ไม่มีสินเชื่อที่ชำระครบ';
      case 'Pending':
        return 'ไม่มีคำขอรออนุมัติ';
      case 'Rejected':
        return 'ไม่มีคำขอที่ถูกปฏิเสธ';
      default:
        return 'ไม่มีรายการสินเชื่อ';
    }
  }
}

class _LoanStatusCard extends StatelessWidget {
  final LoanApplication loan;

  const _LoanStatusCard({required this.loan});

  Color _getStatusColor() {
    switch (loan.status) {
      case LoanApplicationStatus.approved:
        return loan.loanDetails.remainingAmount <= 0 ? AppColors.success : AppColors.primary;
      case LoanApplicationStatus.pending:
        return AppColors.warning;
      case LoanApplicationStatus.waitingForDocs:
        return Colors.orange;
      case LoanApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (loan.status) {
      case LoanApplicationStatus.approved:
        return loan.loanDetails.remainingAmount <= 0 ? LucideIcons.checkCircle : LucideIcons.banknote;
      case LoanApplicationStatus.pending:
        return LucideIcons.clock;
      case LoanApplicationStatus.waitingForDocs:
        return LucideIcons.fileQuestion;
      case LoanApplicationStatus.rejected:
        return LucideIcons.xCircle;
    }
  }

  String _getStatusLabel() {
    switch (loan.status) {
      case LoanApplicationStatus.approved:
        return loan.loanDetails.remainingAmount <= 0 ? 'ชำระครบแล้ว' : 'กำลังชำระ';
      case LoanApplicationStatus.pending:
        return 'รออนุมัติ';
      case LoanApplicationStatus.waitingForDocs:
        return 'รอเอกสารเพิ่ม';
      case LoanApplicationStatus.rejected:
        return 'ไม่อนุมัติ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'th');
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final progress = loan.loanDetails.requestAmount > 0 
        ? loan.loanDetails.paidAmount / loan.loanDetails.requestAmount 
        : 0.0;
    final remaining = loan.loanDetails.remainingAmount;
    final isActive = loan.status == LoanApplicationStatus.approved && remaining > 0;

    return InkWell(
      onTap: () {
        context.push('/loan/contract/${loan.applicationId}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loan.applicationId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดสินเชื่อ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${currencyFormat.format(loan.loanDetails.requestAmount)} บาท',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'วันที่ขอ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dateFormat.format(loan.requestDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Progress bar for active loans
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'คงเหลือ: ${currencyFormat.format(remaining)} บาท',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'ชำระแล้ว ${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.background,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ],
            // Extra info for pending/rejected
            if (loan.status == LoanApplicationStatus.pending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'คำขอของท่านอยู่ระหว่างการพิจารณา',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (loan.status == LoanApplicationStatus.rejected && loan.officerComment != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.messageCircle, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'หมายเหตุ: ${loan.officerComment}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Add Loan Card with dashed border
class _AddLoanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddLoanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primary.withOpacity(0.4),
            strokeWidth: 2,
            dashWidth: 8,
            dashSpace: 6,
            radius: 16,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'สมัครสินเชื่อใหม่',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path);

    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashPath = Path();
    for (final pathMetric in source.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        dashPath.addPath(
          pathMetric.extractPath(distance, nextDistance),
          Offset.zero,
        );
        distance = nextDistance + dashSpace;
      }
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
