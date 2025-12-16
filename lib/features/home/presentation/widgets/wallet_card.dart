import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../loan/data/loan_repository_impl.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../share/data/repositories/share_repository_impl.dart';

class WalletCard extends ConsumerStatefulWidget {
  const WalletCard({super.key});

  @override
  ConsumerState<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends ConsumerState<WalletCard> {
  bool _isVisible = true;
  bool _isLoading = true;
  double _loanRemainingAmount = 0;
  double _shareValue = 0;
  bool _isShareLoading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadLoanData();
    _loadShareData();
  }

  Future<void> _loadLoanData() async {
    try {
      final repository = LoanRepositoryImpl();
      final loans = await repository.getLoanApplications();
      
      // Calculate total remaining amount from all approved loans
      double totalRemaining = 0;
      for (final loan in loans) {
        if (loan.status.name == 'approved') {
          totalRemaining += loan.loanDetails.remainingAmount;
        }
      }
      
      if (mounted) {
        setState(() {
          _loanRemainingAmount = totalRemaining;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadShareData() async {
    try {
      final repository = ShareRepositoryImpl();
      final shareData = await repository.getShareInfo();
      
      if (mounted) {
        setState(() {
          _shareValue = shareData.totalValue;
          _isShareLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isShareLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDepositExcludingLoan = ref.watch(totalDepositExcludingLoanAsyncProvider);
    final loanAccountBalance = ref.watch(loanAccountBalanceAsyncProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFE3F2FD), // สีฟ้าอ่อนตรงกลาง (Blue 50)
            Colors.white,
          ],
          stops: [0.0, 0.5, 1.0], // ขาว → ฟ้าตรงกลาง → ขาว
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ปุ่มซ่อน/แสดงตัวเลขที่มุมขวาบน - Style 1: กรอบกลม + พื้นหลังชมพู
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
                icon: Icon(
                  _isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: AppColors.primary,
                  size: 18,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                tooltip: _isVisible ? 'ซ่อนตัวเลข' : 'แสดงตัวเลข',
              ),
            ),
          ),
          // เนื้อหาหลัก
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Row 1: เงินฝากรวม (ซ้าย) | บัญชีเงินกู้ (ขวา)
                Row(
                  children: [
                    Expanded(
                      child: totalDepositExcludingLoan.when(
                        data: (total) => _buildBalanceBox(
                          context,
                          icon: LucideIcons.wallet,
                          iconColor: AppColors.secondary,
                          title: 'เงินฝากรวม',
                          amount: _currencyFormat.format(total),
                          isVisible: _isVisible,
                        ),
                        loading: () => _buildBalanceBox(
                          context,
                          icon: LucideIcons.wallet,
                          iconColor: AppColors.secondary,
                          title: 'เงินฝากรวม',
                          amount: 'กำลังโหลด...',
                          isVisible: true,
                        ),
                        error: (error, stack) => _buildBalanceBox(
                          context,
                          icon: LucideIcons.wallet,
                          iconColor: AppColors.secondary,
                          title: 'เงินฝากรวม',
                          amount: 'ผิดพลาด',
                          isVisible: true,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: AppColors.divider,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: loanAccountBalance.when(
                        data: (balance) => _buildBalanceBox(
                          context,
                          icon: LucideIcons.banknote,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'บัญชีเงินกู้',
                          amount: _currencyFormat.format(balance),
                          isVisible: _isVisible,
                        ),
                        loading: () => _buildBalanceBox(
                          context,
                          icon: LucideIcons.banknote,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'บัญชีเงินกู้',
                          amount: 'กำลังโหลด...',
                          isVisible: true,
                        ),
                        error: (error, stack) => _buildBalanceBox(
                          context,
                          icon: LucideIcons.banknote,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'บัญชีเงินกู้',
                          amount: 'ผิดพลาด',
                          isVisible: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                // Row 2: หุ้น (ซ้าย) | วงเงินกู้คงเหลือ (ขวา)
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceBox(
                        context,
                        icon: LucideIcons.pieChart,
                        iconColor: AppColors.success,
                        title: 'มูลค่าหุ้นรวม',
                        amount: _isShareLoading ? 'กำลังโหลด...' : _currencyFormat.format(_shareValue),
                        isVisible: _isVisible,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildBalanceBox(
                        context,
                        icon: LucideIcons.creditCard,
                        iconColor: AppColors.warning,
                        title: 'วงเงินกู้คงเหลือ',
                        amount: _isLoading ? 'กำลังโหลด...' : _currencyFormat.format(_loanRemainingAmount),
                        isVisible: _isVisible,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Style: ไอคอนกรอบกลม (Style 1) + สีเข้ม (Style 3)
  Widget _buildBalanceBox(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isVisible,
  }) {
    return Row(
      children: [
        // ไอคอนกรอบกลม (Style 1)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title สีเข้ม (Style 3)
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Amount สีเข้ม (Style 3)
              Text(
                isVisible ? amount : '••••••',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
