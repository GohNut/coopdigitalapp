import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/deposit_providers.dart';
import '../../domain/deposit_account.dart';

/// หน้าจอสร้างบัญชีใหม่
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  AccountType? _selectedType;
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  int _fixedTermMonths = 12; // Default 12 months for fixed deposit
  bool _isCreating = false;

  // อัตราดอกเบี้ยตามประเภทบัญชี
  static const Map<AccountType, double> _interestRates = {
    AccountType.savings: 2.50,
    AccountType.fixed: 3.25, // ค่าเฉลี่ย จะเปลี่ยนตามระยะเวลา
    AccountType.special: 4.50,
  };

  // อัตราดอกเบี้ยตามระยะเวลาฝากประจำ
  double _getFixedInterestRate(int months) {
    switch (months) {
      case 6:
        return 2.75;
      case 12:
        return 3.25;
      case 24:
        return 3.75;
      default:
        return 3.25;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สร้างบัญชีใหม่'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'เลือกประเภทบัญชี',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Account Type Cards
            _buildAccountTypeCard(
              type: AccountType.savings,
              icon: LucideIcons.piggyBank,
              title: 'บัญชีเงินฝากออมทรัพย์',
              subtitle: 'ฝาก-ถอนได้ตลอด',
              interestRate: '2.50%',
              color: const Color(0xFF1A90CE),
            ),
            const SizedBox(height: 12),
            _buildAccountTypeCard(
              type: AccountType.fixed,
              icon: LucideIcons.lock,
              title: 'บัญชีเงินฝากประจำ',
              subtitle: 'ดอกเบี้ยสูง ตามระยะเวลา',
              interestRate: '2.75% - 3.75%',
              color: const Color(0xFFD4AF37),
            ),
            const SizedBox(height: 12),
            _buildAccountTypeCard(
              type: AccountType.special,
              icon: LucideIcons.star,
              title: 'บัญชีเงินฝากพิเศษ',
              subtitle: 'โปรแกรมการออมพิเศษ',
              interestRate: 'สูงถึง 4.50%',
              color: const Color(0xFFE53935),
            ),

            // Fixed Term Selection (only for fixed deposit)
            if (_selectedType == AccountType.fixed) ...[
              const SizedBox(height: 24),
              Text(
                'เลือกระยะเวลาฝาก',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTermSelector(),
            ],

            // Account Name Input
            if (_selectedType != null) ...[
              const SizedBox(height: 24),
              Text(
                'ตั้งชื่อบัญชี (ไม่บังคับ)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: InputDecoration(
                  hintText: _nameFocusNode.hasFocus ? null : 'เช่น ออมเพื่ออนาคต, ฝากประจำ 12 เดือน',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              // Summary Card
              const SizedBox(height: 24),
              _buildSummaryCard(),

              // Create Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'สร้างบัญชี',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required AccountType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String interestRate,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected ? color.withOpacity(0.3) : Colors.black12,
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Interest Rate
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    interestRate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'ต่อปี',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Radio circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSelector() {
    const terms = [6, 12, 24];

    return Row(
      children: terms.map((months) {
        final isSelected = _fixedTermMonths == months;
        final rate = _getFixedInterestRate(months);
        final color = const Color(0xFFD4AF37);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: months != 24 ? 8 : 0,
            ),
            child: Material(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _fixedTermMonths = months),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$months',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : AppColors.textPrimary,
                        ),
                      ),
                      const Text('เดือน'),
                      const SizedBox(height: 4),
                      Text(
                        '$rate%',
                        style: TextStyle(
                          color: isSelected ? color : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final type = _selectedType!;
    final color = Color(type.colorCode);
    final interestRate = type == AccountType.fixed
        ? _getFixedInterestRate(_fixedTermMonths)
        : _interestRates[type]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'สรุปข้อมูลบัญชี',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('ประเภทบัญชี', type.displayName),
          if (type == AccountType.fixed)
            _buildSummaryRow('ระยะเวลาฝาก', '$_fixedTermMonths เดือน'),
          _buildSummaryRow('อัตราดอกเบี้ย', '$interestRate% ต่อปี'),
          _buildSummaryRow('ยอดเปิดบัญชี', '0.00'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    setState(() => _isCreating = true);

    final type = _selectedType!;
    final interestRate = type == AccountType.fixed
        ? _getFixedInterestRate(_fixedTermMonths)
        : _interestRates[type]!;

    // Generate account name
    String accountName = _nameController.text.trim();
    if (accountName.isEmpty) {
      switch (type) {
        case AccountType.savings:
          accountName = 'เงินฝากออมทรัพย์';
          break;
        case AccountType.fixed:
          accountName = 'เงินฝากประจำ $_fixedTermMonths เดือน';
          break;
        case AccountType.special:
          accountName = 'เงินฝากออมทรัพย์พิเศษ';
          break;
        case AccountType.loan:
          accountName = 'เงินกู้สหกรณ์';
          break;
      }
    }

    try {
      // Call API to create account
      await ref.read(createAccountProvider.notifier).createAccount(
        accountName: accountName,
        accountType: type,
        interestRate: interestRate,
        fixedTermMonths: type == AccountType.fixed ? _fixedTermMonths : null,
      );

      // Refresh the accounts list
      ref.invalidate(depositAccountsAsyncProvider);

      setState(() => _isCreating = false);

      // Show success dialog
      if (mounted) {
        // Generate account number for display
        final now = DateTime.now();
        final accountNumber = '${type == AccountType.savings ? "101" : type == AccountType.fixed ? "102" : "103"}-${now.month}-${now.microsecond.toString().padLeft(5, '0')}-${(now.second % 10)}';

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _SuccessDialog(
            accountName: accountName,
            accountNumber: accountNumber,
            accountType: type,
          ),
        );
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Success Dialog
class _SuccessDialog extends StatelessWidget {
  final String accountName;
  final String accountNumber;
  final AccountType accountType;

  const _SuccessDialog({
    required this.accountName,
    required this.accountNumber,
    required this.accountType,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(accountType.colorCode);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'สร้างบัญชีสำเร็จ!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Account Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          accountType.displayName,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    accountName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accountNumber,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
