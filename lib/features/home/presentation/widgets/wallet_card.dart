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
  final _currencyFormat = NumberFormat.currency(symbol: '฿ ', decimalDigits: 2);

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
    final totalDepositAsync = ref.watch(totalDepositBalanceAsyncProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.05),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            totalDepositAsync.when(
              data: (total) => _buildCompactBalanceRow(
                context,
                icon: LucideIcons.wallet,
                iconColor: AppColors.secondary,
                title: 'บัญชีออมทรัพย์ (รวมทุกบัญชี)',
                amount: _currencyFormat.format(total),
                isVisible: _isVisible,
                showVisibilityToggle: true,
              ),
              loading: () => _buildCompactBalanceRow(
                context,
                icon: LucideIcons.wallet,
                iconColor: AppColors.secondary,
                title: 'บัญชีออมทรัพย์',
                amount: 'กำลังโหลด...',
                isVisible: true,
                showVisibilityToggle: false,
              ),
              error: (error, stack) => _buildCompactBalanceRow(
                context,
                icon: LucideIcons.wallet,
                iconColor: AppColors.secondary,
                title: 'บัญชีออมทรัพย์',
                amount: 'เกิดข้อผิดพลาด',
                isVisible: true,
                showVisibilityToggle: false,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildCompactBalanceRow(
                    context,
                    icon: LucideIcons.pieChart,
                    iconColor: AppColors.success,
                    title: 'มูลค่าหุ้นรวม',
                    amount: _isShareLoading ? 'กำลังโหลด...' : _currencyFormat.format(_shareValue),
                    isVisible: _isVisible,
                    showVisibilityToggle: false,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildCompactBalanceRow(
                    context,
                    icon: LucideIcons.creditCard,
                    iconColor: AppColors.warning,
                    title: 'วงเงินกู้คงเหลือ',
                    amount: _isLoading ? 'กำลังโหลด...' : _currencyFormat.format(_loanRemainingAmount),
                    isVisible: _isVisible,
                    showVisibilityToggle: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCompactBalanceRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isVisible,
    required bool showVisibilityToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: iconColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isVisible ? amount : '••••••',
                style: showVisibilityToggle
                    ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        )
                    : Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
              ),
            ],
          ),
        ),
        if (showVisibilityToggle)
          IconButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
              color: AppColors.secondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
