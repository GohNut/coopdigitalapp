import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';

class SharePaymentMethodScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args; // Passed from Step 1

  const SharePaymentMethodScreen({super.key, required this.args});

  @override
  ConsumerState<SharePaymentMethodScreen> createState() => _SharePaymentMethodScreenState();
}

class _SharePaymentMethodScreenState extends ConsumerState<SharePaymentMethodScreen> {
  String _selectedMethod = 'account'; // account หรือ qr
  String? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final netTotal = widget.args['netTotal'] as double;
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final accounts = ref.watch(depositAccountsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('เลือกช่องทางชำระเงิน (2/4)'),
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
            // Header: Amount to Pay
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('ยอดชำระสุทธิ', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('฿${currencyFormat.format(netTotal)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text("เลือกช่องทาง", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ตัวเลือก 1: จากสมุดบัญชี
            _buildMethodOption(
              'account',
              'จากสมุดบัญชี',
              LucideIcons.book,
              subtitle: 'ตัดจากบัญชีออมทรัพย์',
            ),
            
            // แสดงรายการบัญชีถ้าเลือก account
            if (_selectedMethod == 'account') ...[
              const SizedBox(height: 16),
              _buildAccountsList(accounts, netTotal, currencyFormat),
            ],

            const SizedBox(height: 12),

            // ตัวเลือก 2: QR PromptPay
            _buildMethodOption(
              'qr',
              'QR PromptPay',
              LucideIcons.qrCode,
              subtitle: 'สแกน QR เพื่อโอนเงิน',
            ),

            const SizedBox(height: 48),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _canProceed(netTotal, accounts) ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('ถัดไป', 
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
        if (id == 'qr') {
          _selectedAccountId = null; // Clear account selection
        }
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

  Widget _buildAccountsList(List<DepositAccount> accounts, double netTotal, NumberFormat currencyFormat) {
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
          const Text('เลือกบัญชีที่ต้องการใช้', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...accounts.map((account) {
            final canUse = account.balance >= netTotal;
            final isSelected = _selectedAccountId == account.id;
            final cardColor = Color(account.accountType.colorCode);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: canUse ? () => setState(() => _selectedAccountId = account.id) : null,
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
                  child: Opacity(
                    opacity: canUse ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getAccountIcon(account.accountType), color: cardColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.accountName, 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(account.maskedAccountNumber, 
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('฿${currencyFormat.format(account.balance)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (!canUse)
                              const Text('ไม่เพียงพอ', 
                                style: TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return LucideIcons.piggyBank;
      case AccountType.fixed:
        return LucideIcons.lock;
      case AccountType.special:
        return LucideIcons.star;
    }
  }

  bool _canProceed(double netTotal, List<DepositAccount> accounts) {
    if (_selectedMethod == 'qr') {
      return true; // QR สามารถไปต่อได้เสมอ
    }
    
    // ถ้าเลือก account ต้องเลือกบัญชีและมียอดเงินเพียงพอ
    if (_selectedAccountId != null) {
      final account = accounts.firstWhere((a) => a.id == _selectedAccountId);
      return account.balance >= netTotal;
    }
    
    return false;
  }

  void _handleNext() {
    if (_selectedMethod == 'qr') {
      // ไปหน้า QR Screen
      context.push('/share/buy/qr', extra: widget.args);
    } else {
      // ไปหน้ายืนยัน พร้อมข้อมูลบัญชี
      final nextArgs = Map<String, dynamic>.from(widget.args);
      nextArgs['paymentMethod'] = 'account';
      nextArgs['paymentSourceId'] = _selectedAccountId;
      context.push('/share/buy/confirm', extra: nextArgs);
    }
  }
}
