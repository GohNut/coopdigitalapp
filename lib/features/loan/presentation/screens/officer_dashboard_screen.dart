import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_application_model.dart';
import '../../data/loan_repository_impl.dart';
import '../../../auth/domain/user_role.dart';
import 'officer_loan_detail_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _navigateToDetail(LoanApplication app) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => OfficerLoanDetailScreen(application: app)),
    );
    
    if (result == true) {
      // In a real app, refresh data here
      setState(() {
        // Just trigger rebuild to pretend we refreshed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!CurrentUser.isOfficerOrApprover) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('อนุมัติสินเชื่อ', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'รอพิจารณา'),
            Tab(text: 'รอแก้ไขเอกสาร'),
            Tab(text: 'อนุมัติแล้ว'),
            Tab(text: 'ปฏิเสธ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoanList(LoanApplicationStatus.pending),
          _buildLoanList(LoanApplicationStatus.waitingForDocs),
          _buildLoanList(LoanApplicationStatus.approved),
          _buildLoanList(LoanApplicationStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildLoanList(LoanApplicationStatus status) {
    // Ideally use a provider or service locator, but instantiating directly for now as per minimal setup
    final repository = LoanRepositoryImpl();
    
    return FutureBuilder<List<LoanApplication>>(
      future: repository.getLoanApplications(forOfficerReview: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // ตรวจสอบ type และ null safety
        final allApplications = (snapshot.data != null && snapshot.data is List<LoanApplication>)
            ? snapshot.data!
            : <LoanApplication>[];
        final applications = allApplications
            .where((app) => app.status == status)
            .toList();

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'ไม่มีรายการ',
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _navigateToDetail(app),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                         dateFormat.format(app.requestDate),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(app.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(app.status),
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(app.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('โดย ${app.applicantName}', style: const TextStyle(color: Colors.grey)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('วงเงินที่ขอ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            currencyFormat.format(app.amount),
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: AppColors.primary
                            ),
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.chevronRight, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  Color _getStatusColor(LoanApplicationStatus status) {
    switch (status) {
      case LoanApplicationStatus.pending: return AppColors.warning;
      case LoanApplicationStatus.waitingForDocs: return Colors.orange;
      case LoanApplicationStatus.approved: return AppColors.success;
      case LoanApplicationStatus.rejected: return AppColors.error;
    }
  }

  String _getStatusText(LoanApplicationStatus status) {
    switch (status) {
      case LoanApplicationStatus.pending: return 'รอพิจารณา';
      case LoanApplicationStatus.waitingForDocs: return 'รอเอกสารเพิ่ม';
      case LoanApplicationStatus.approved: return 'อนุมัติ';
      case LoanApplicationStatus.rejected: return 'ปฏิเสธ';
    }
  }
}
