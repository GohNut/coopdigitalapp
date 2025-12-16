import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/dividend_repository_impl.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../../auth/presentation/screens/pin_verification_screen.dart';

class DividendRequestScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const DividendRequestScreen({super.key, required this.args});

  @override
  ConsumerState<DividendRequestScreen> createState() => _DividendRequestScreenState();
}

class _DividendRequestScreenState extends ConsumerState<DividendRequestScreen> {
  final _repository = DividendRepositoryImpl();
  String _selectedMethod = 'account'; // account or share
  String? _selectedAccountId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final year = widget.args['year'] as int? ?? DateTime.now().year;
    final amount = (widget.args['amount'] as double?) ?? 0;
    final rate = (widget.args['rate'] as double?) ?? 0;
    final accounts = ref.watch(depositAccountsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ขอรับเงินปันผล'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('เงินปันผลปี', style: TextStyle(color: Colors.white70)),
                  Text('$year', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${currencyFormat.format(amount)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('อัตรา $rate%', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('เลือกวิธีรับเงินปันผล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // Option 1: Transfer to Account
            _buildMethodOption(
              'account',
              'โอนเข้าบัญชีออมทรัพย์',
              LucideIcons.building,
              subtitle: 'รับเงินเข้าบัญชีสหกรณ์ของคุณ',
            ),
            
            // Account Selection (if account method selected)
            if (_selectedMethod == 'account') ...[
              const SizedBox(height: 16),
              _buildAccountsList(accounts),
            ],
            
            const SizedBox(height: 12),
            
            // Option 2: Buy More Shares
            _buildMethodOption(
              'share',
              'ซื้อหุ้นเพิ่ม',
              LucideIcons.trendingUp,
              subtitle: 'นำเงินปันผลไปซื้อหุ้นเพิ่ม',
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _canProceed() ? () => _handleSubmit(year, amount, rate) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ยืนยันรับเงินปันผล', 
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption(String id, String label, IconData icon, {String? subtitle}) {
    final isSelected = _selectedMethod == id;
    
    return InkWell(
      onTap: () => setState(() {
        _selectedMethod = id;
        if (id == 'share') _selectedAccountId = null;
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle, color: AppColors.primary)
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<DepositAccount> accounts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกบัญชีรับเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...accounts.map((account) {
            final isSelected = _selectedAccountId == account.id;
            final cardColor = Color(account.accountType.colorCode);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedAccountId = account.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.piggyBank, color: cardColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.accountName, 
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(account.maskedAccountNumber, 
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_selectedMethod == 'share') return true;
    return _selectedAccountId != null;
  }

  Future<void> _handleSubmit(int year, double amount, double rate) async {
    // PIN Verification
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PinVerificationScreen()),
    );

    if (result != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _repository.requestPayment(
        year: year,
        amount: amount,
        rate: rate,
        paymentMethod: _selectedMethod,
        depositAccountId: _selectedAccountId,
      );

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('ดำเนินการสำเร็จ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _selectedMethod == 'share' 
                  ? 'เงินปันผลถูกนำไปซื้อหุ้นเพิ่มเรียบร้อยแล้ว'
                  : 'เงินปันผลถูกโอนเข้าบัญชีเรียบร้อยแล้ว',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/share');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('กลับหน้าหลัก', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
