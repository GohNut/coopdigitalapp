import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/loan_repository_impl.dart';
import '../../domain/loan_application_model.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../../deposit/data/deposit_providers.dart';

class LoanPaymentScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const LoanPaymentScreen({super.key, required this.applicationId});

  @override
  ConsumerState<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends ConsumerState<LoanPaymentScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy', 'th');
  
  String _paymentMethod = 'account_book'; // account_book, qr_promptpay
  String _paymentType = 'normal'; // normal, advance, full_payoff
  int _advanceInstallments = 1;
  bool _isLoading = false;
  bool _isSubmitting = false;
  

  
  LoanApplication? _loan;
  Map<String, dynamic>? _sourceAccount;
  bool _isLoadingAccount = false;


  @override
  void initState() {
    super.initState();
    _loadLoanData();
  }

  Future<void> _loadLoanData() async {
    setState(() => _isLoading = true);
    try {
      final repository = LoanRepositoryImpl();
      final loans = await repository.getLoanApplications();
      final loan = loans.firstWhere(
        (l) => l.applicationId == widget.applicationId,
        orElse: () => loans.first,
      );
      setState(() {
        _loan = loan;
        _isLoading = false;
      });
      
      // Load account info
      if (loan.applicant.memberId.isNotEmpty) {
        _loadSourceAccount(loan.applicant.memberId);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  double get _totalAmount {
    if (_loan == null) return 0;
    final installment = _loan!.loanDetails.installmentAmount;
    
    switch (_paymentType) {
      case 'advance':
        return installment * _advanceInstallments;
      case 'full_payoff':
        return _loan!.loanDetails.remainingAmount;
      default:
        return installment;
    }
  }

  int get _nextInstallmentNo {
    if (_loan == null) return 1;
    return _loan!.loanDetails.paidInstallments + 1;
  }


  Future<void> _loadSourceAccount(String memberId) async {
    setState(() => _isLoadingAccount = true);
    try {
      final accounts = await DynamicDepositApiService.getAccounts(memberId);
      // Find savings account
      final savings = accounts.firstWhere(
        (a) => a['accounttype'] == 'loan',
        orElse: () => accounts.isNotEmpty ? accounts.first : {},
      );
      
      if (savings.isNotEmpty) {
        setState(() => _sourceAccount = savings);
      }
    } catch (e) {
      print('Error loading account: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAccount = false);
    }
  }


  Future<void> _processPayment() async {
    if (_loan == null) return;



    // Navigate to PIN verification
    final pinSuccess = await context.push<bool>('/pin');
    if (pinSuccess != true) return;

    setState(() => _isSubmitting = true);


    try {
      final repository = LoanRepositoryImpl();
      await repository.makePayment(
        applicationId: widget.applicationId,
        installmentNo: _nextInstallmentNo,
        amount: _totalAmount,
        paymentMethod: _paymentMethod,
        paymentType: _paymentType,
        installmentCount: _paymentType == 'advance' ? _advanceInstallments : 1,
        sourceAccountId: _sourceAccount?['accountid'],
      );

      // Invalidate providers to refresh data immediately
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(depositAccountByIdAsyncProvider(_sourceAccount?['accountid'] ?? ''));
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(loanAccountBalanceAsyncProvider);

      if (mounted) {
        context.push('/loan/payment/success', extra: {
          'applicationId': widget.applicationId,
          'amount': _totalAmount,
          'paymentMethod': _paymentMethod,
          'paymentType': _paymentType,
          'installmentNo': _nextInstallmentNo,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ชำระค่างวด', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loan == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ชำระค่างวด', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('ไม่พบข้อมูลสินเชื่อ')),
      );
    }

    final loanDetails = _loan!.loanDetails;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ชำระค่างวด', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Info Card
            Container(
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
                          widget.applicationId,
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
                  _buildInfoRow('ยอดคงเหลือ', currencyFormat.format(loanDetails.remainingAmount)),
                  _buildInfoRow('งวดถัดไป', 'งวดที่ $_nextInstallmentNo'),
                  _buildInfoRow('ยอดต่องวด', currencyFormat.format(loanDetails.installmentAmount)),
                  _buildInfoRow('วันครบกำหนด', loanDetails.nextPaymentDate != null 
                      ? dateFormat.format(loanDetails.nextPaymentDate!) 
                      : '-'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Type Section
            Text(
              'ประเภทการชำระ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPaymentTypeOption(
              value: 'normal',
              title: 'ชำระงวดปกติ',
              subtitle: '1 งวด • ${currencyFormat.format(loanDetails.installmentAmount)}',
              icon: LucideIcons.calendar,
            ),
            const SizedBox(height: 8),
            _buildPaymentTypeOption(
              value: 'advance',
              title: 'ชำระล่วงหน้าหลายงวด',
              subtitle: 'เลือกจำนวนงวดที่ต้องการ',
              icon: LucideIcons.fastForward,
            ),
            
            // Advance Installments Selector
            if (_paymentType == 'advance') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('จำนวนงวด: $_advanceInstallments งวด'),
                    Slider(
                      value: _advanceInstallments.toDouble(),
                      min: 1,
                      max: (loanDetails.requestTerm - loanDetails.paidInstallments).toDouble().clamp(1, 12),
                      divisions: 11,
                      label: '$_advanceInstallments งวด',
                      onChanged: (value) {
                        setState(() => _advanceInstallments = value.toInt());
                      },
                    ),
                    Text(
                      'รวม ${currencyFormat.format(loanDetails.installmentAmount * _advanceInstallments)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            _buildPaymentTypeOption(
              value: 'full_payoff',
              title: 'ปิดยอดกู้ทั้งหมด',
              subtitle: currencyFormat.format(loanDetails.remainingAmount),
              icon: LucideIcons.checkCircle,
            ),

            const SizedBox(height: 24),

            // Payment Method Section
            Text(
              'แหล่งเงินสำหรับชำระ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildPaymentMethodOption(
              value: 'account_book',
              title: 'ชำระจากสมุดเงินกู้',
              subtitle: _sourceAccount != null 
                  ? '${_sourceAccount!['accountname']}\n${_sourceAccount!['accountnumber']}\nยอดเงินคงเหลือ: ${currencyFormat.format(_sourceAccount!['balance'])}'
                  : 'กำลังโหลด...',
              icon: LucideIcons.wallet,
              isError: _sourceAccount != null && (_sourceAccount!['balance'] ?? 0) < _totalAmount,
            ),
            
            const SizedBox(height: 32),


            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ยอดชำระรวม',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        currencyFormat.format(_totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_paymentType == 'advance') ...[
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('จำนวนงวด', style: TextStyle(color: Colors.white70)),
                        Text('$_advanceInstallments งวด', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSubmitting || (_sourceAccount != null && (_sourceAccount!['balance'] ?? 0) < _totalAmount)) 
                    ? null 
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.creditCard),
                          SizedBox(width: 8),
                          Text(
                            'ยืนยันชำระเงิน',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _paymentType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.1) 
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentType,
              onChanged: (v) => setState(() => _paymentType = v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isEnabled = true,
    String? badge,
    bool isError = false,
  }) {
    final isSelected = _paymentMethod == value && isEnabled;
    
    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _paymentMethod = value) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError ? Colors.red : (isSelected ? AppColors.success : Colors.transparent),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.success.withOpacity(0.1) 
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.success : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isError)
                      Text(
                        'ยอดเงินไม่เพียงพอ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              if (isEnabled)
                Radio<String>(
                  value: value,
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  activeColor: AppColors.success,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
