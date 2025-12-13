import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';

class TransferInputScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> account; // Destination Account

  const TransferInputScreen({super.key, required this.account});

  @override
  ConsumerState<TransferInputScreen> createState() => _TransferInputScreenState();
}

class _TransferInputScreenState extends ConsumerState<TransferInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedSourceAccountId;
  
  @override
  void initState() {
    super.initState();
    // Pre-select first account
    ref.read(depositAccountsAsyncProvider.future).then((accounts) {
      if (accounts.isNotEmpty && mounted && _selectedSourceAccountId == null) {
        setState(() {
          _selectedSourceAccountId = accounts.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onReview() {
    if (_selectedSourceAccountId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกบัญชีต้นทาง')));
       return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดโอนขั้นต่ำ 1.00 บาท')));
      return;
    }

    // Check Balance
    final accounts = ref.read(depositAccountsProvider);
    final sourceAccount = accounts.firstWhere((a) => a.id == _selectedSourceAccountId, orElse: () => _emptyAccount());
    
    if (sourceAccount.balance < amount) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดเงินในบัญชีไม่เพียงพอ')));
       return;
    }

    // Show Confirmation Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConfirmationSheet(amount, sourceAccount),
    );
  }

  DepositAccount _emptyAccount() {
      // Helper to return empty account safely
      return DepositAccount(id: '', accountNumber: '', accountName: '', accountType: AccountType.savings, balance: 0, interestRate: 0, accruedInterest: 0, openedDate: DateTime.now());
  }

  Widget _buildConfirmationSheet(double amount, DepositAccount sourceAccount) {
    // Destination name
    final destName = widget.account['accountname'] ?? 'ไม่ระบุชื่อ';
    final destNo = widget.account['accountnumber'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ตรวจสอบข้อมูล',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow('จาก', '${sourceAccount.accountName}\n${sourceAccount.accountNumber}'),
          const SizedBox(height: 12),
          _buildDetailRow('ไปยัง', '$destName\n$destNo'),
          const SizedBox(height: 12),
          _buildDetailRow('จำนวนเงิน', '฿ ${NumberFormat('#,##0.00').format(amount)}', isBold: true),
          if (_noteController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('บันทึกช่วยจำ', _noteController.text),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processTransfer(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ยืนยันการโอน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processTransfer(double amount) async {
    // 1. PIN Check (Assuming mock pass for now or separate pin flow)
    // final pinSuccess = await context.push<bool>('/pin');
    // if (pinSuccess != true) return;

    try {
      await ref.read(depositActionProvider.notifier).transfer(
        sourceAccountId: _selectedSourceAccountId!,
        destinationAccountId: widget.account['accountid'],
        amount: amount,
        description: _noteController.text.isEmpty ? 'โอนเงินสมาชิก' : _noteController.text,
      );

      if (mounted) {
        // Go to Success Screen
        context.go('/transfer/success', extra: {
          'transaction_id': 'TRF-${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'target_name': widget.account['accountname'],
          'note': _noteController.text,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(depositAccountsAsyncProvider);
    final isProcessing = ref.watch(depositActionProvider).isLoading;

    if (isProcessing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destName = widget.account['accountname'] ?? 'ไม่ระบุชื่อ';
    final destNo = widget.account['accountnumber'] ?? '';
    final destId = widget.account['accountid'] ?? '';

    // Calculate source balance to show
    String sourceBalanceStr = '0.00';
    if (_selectedSourceAccountId != null && accountsAsync.hasValue) {
       final account = accountsAsync.value!.firstWhere((a) => a.id == _selectedSourceAccountId, orElse: () => _emptyAccount());
       sourceBalanceStr = NumberFormat('#,##0.00').format(account.balance);
    }


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ระบุจำนวนเงิน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Source Account Selection
            Align(alignment: Alignment.centerLeft, child: Text('จากบัญชี', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary))),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const SizedBox();
                 if (_selectedSourceAccountId == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedSourceAccountId = accounts.first.id);
                    });
                }
                return DropdownButtonFormField<String>(
                  value: _selectedSourceAccountId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text('${account.accountName} (${account.accountNumber})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSourceAccountId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error loading accounts'),
            ),
            
            const SizedBox(height: 24),

            // Target Member Card
            Align(alignment: Alignment.centerLeft, child: Text('ไปยัง', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   Container(
                     width: 48,
                     height: 48,
                     decoration: BoxDecoration(
                       color: AppColors.primary.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(LucideIcons.user, color: AppColors.primary),
                   ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$destNo ($destId)', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    )
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                prefixText: '฿ ',
                prefixStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            Text('ยอดเงินในบัญชี: ฿ $sourceBalanceStr', style: const TextStyle(color: AppColors.textSecondary)),
            
            const SizedBox(height: 32),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'บันทึกช่วยจำ (ถ้ามี)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ถัดไป', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
