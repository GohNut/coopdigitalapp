import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/loan_repository_impl.dart';
import '../../domain/loan_application_model.dart';

class LoanTrackingScreen extends StatefulWidget {
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen> {
  final _repository = LoanRepositoryImpl();
  late Future<List<LoanApplication>> _loansFuture;

  @override
  void initState() {
    super.initState();
    _loansFuture = _repository.getLoanApplications();
  }

  // Filter helpers
  List<LoanApplication> _filterLoans(List<LoanApplication> loans, String statusFilter) {
    switch (statusFilter) {
      case 'Active':
        // Assuming "Active" means Approved and Remaining Amount > 0
        return loans.where((l) => l.status == LoanApplicationStatus.approved && l.loanDetails.remainingAmount > 0).toList();
      case 'Closed':
         // Assuming "Closed" means Approved but Remaining Amount == 0, or explicitly Rejected history? 
         // For now let's say "Closed" implies paid off. But mock data might not have this state explicitly.
         // Let's simpler mapping: Approved + 0 remaining.
         return loans.where((l) => l.status == LoanApplicationStatus.approved && l.loanDetails.remainingAmount <= 0).toList();
      case 'Pending':
        return loans.where((l) => l.status == LoanApplicationStatus.pending).toList();
      default: // 'All'
        return loans;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LoanApplication>>(
      future: _loansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
           return Scaffold(
            appBar: AppBar(title: const Text('รายการคำขอ')),
            body: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
          );
        }

        final allLoans = snapshot.data ?? [];
        final activeCount = _filterLoans(allLoans, 'Active').length;
        final closedCount = _filterLoans(allLoans, 'Closed').length;
        final pendingCount = _filterLoans(allLoans, 'Pending').length;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('รายการคำขอ/สัญญา'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop(),
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'ทั้งหมด (${allLoans.length})'),
                  Tab(text: 'กำลังชำระ ($activeCount)'),
                  Tab(text: 'ชำระครบ ($closedCount)'),
                  Tab(text: 'รออนุมัติ ($pendingCount)'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildLoanList(context, allLoans, 'All'),
                _buildLoanList(context, allLoans, 'Active'),
                _buildLoanList(context, allLoans, 'Closed'),
                _buildLoanList(context, allLoans, 'Pending'),
              ],
            ),
          ),
        );
      },
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
            const Text('ไม่พบรายการ', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLoans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = filteredLoans[index];
        return _LoanTrackingCard(loan: loan);
      },
    );
  }
}

class _LoanTrackingCard extends StatelessWidget {
  final LoanApplication loan;

  const _LoanTrackingCard({required this.loan});

  Color _getStatusColor() {
    switch (loan.status) {
      case LoanApplicationStatus.approved:
        return loan.loanDetails.remainingAmount <= 0 ? AppColors.success : AppColors.primary;
      case LoanApplicationStatus.pending: return AppColors.warning;
      case LoanApplicationStatus.rejected: return Colors.red;
    }
  }

  String _getStatusLabel() {
    switch (loan.status) {
      case LoanApplicationStatus.approved:
         return loan.loanDetails.remainingAmount <= 0 ? 'ชำระครบแล้ว' : 'กำลังชำระ';
      case LoanApplicationStatus.pending: return 'รออนุมัติ';
      case LoanApplicationStatus.rejected: return 'ไม่อนุมัติ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'th');
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fileText, color: _getStatusColor()),
        ),
        title: Text(loan.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('วันที่: ${dateFormat.format(loan.requestDate)}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currencyFormat.format(loan.loanDetails.requestAmount), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusLabel(),
                style: TextStyle(color: _getStatusColor(), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: () {
          // Pass the real application ID to the details screen
          context.push('/loan/contract/${loan.applicationId}');
        },
      ),
    );
  }
}
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen> {
  // Mock Data - ย้ายมาไว้ที่ระดับ class เพื่อใช้นับจำนวน
  final List<Map<String, dynamic>> _loans = [
    {'id': '1', 'name': 'เงินกู้ฉุกเฉิน', 'amount': 20000, 'status': 'Active', 'date': '12/10/2023'},
    {'id': '2', 'name': 'เงินกู้สามัญ', 'amount': 150000, 'status': 'Pending', 'date': '05/12/2023'},
    {'id': '3', 'name': 'เงินกู้พิเศษ', 'amount': 500000, 'status': 'Closed', 'date': '01/01/2022'},
  ];

  // นับจำนวนของแต่ละ status
  int get _allCount => _loans.length;
  int get _activeCount => _loans.where((l) => l['status'] == 'Active').length;
  int get _closedCount => _loans.where((l) => l['status'] == 'Closed').length;
  int get _pendingCount => _loans.where((l) => l['status'] == 'Pending').length;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('รายการคำขอ/สัญญา'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'ทั้งหมด ($_allCount)'),
              Tab(text: 'กำลังชำระ ($_activeCount)'),
              Tab(text: 'ชำระครบ ($_closedCount)'),
              Tab(text: 'รออนุมัติ ($_pendingCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLoanList(context, 'All'),
            _buildLoanList(context, 'Active'),
            _buildLoanList(context, 'Closed'),
            _buildLoanList(context, 'Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanList(BuildContext context, String statusFilter) {
    // Filter Logic
    final filteredLoans = statusFilter == 'All' 
        ? _loans 
        : _loans.where((l) => l['status'] == statusFilter).toList();

    if (filteredLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('ไม่พบรายการ', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLoans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = filteredLoans[index];
        return _LoanTrackingCard(
          name: loan['name'] as String,
          amount: loan['amount'] as int,
          status: loan['status'] as String,
          date: loan['date'] as String,
        );
      },
    );
  }
}

class _LoanTrackingCard extends StatelessWidget {
  final String name;
  final int amount;
  final String status;
  final String date;

  const _LoanTrackingCard({
    required this.name,
    required this.amount,
    required this.status,
    required this.date,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Active': return AppColors.primary;
      case 'Pending': return AppColors.warning;
      case 'Closed': return AppColors.success;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel() {
     switch (status) {
      case 'Active': return 'กำลังชำระ';
      case 'Pending': return 'รออนุมัติ';
      case 'Closed': return 'ชำระครบแล้ว';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fileText, color: _getStatusColor()),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('วันที่: $date'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('฿$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusLabel(),
                style: TextStyle(color: _getStatusColor(), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to Contract Details (Phase 8)
          context.push('/loan/contract/mock-id');
        },
      ),
    );
  }
}
