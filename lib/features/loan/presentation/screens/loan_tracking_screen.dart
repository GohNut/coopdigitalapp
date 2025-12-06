import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class LoanTrackingScreen extends StatefulWidget {
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
