import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../../auth/presentation/screens/pin_verification_screen.dart';
import '../../../../core/utils/currency_input_formatter.dart';

class TransferOwnAccountsScreen extends ConsumerStatefulWidget {
  const TransferOwnAccountsScreen({super.key});

  @override
  ConsumerState<TransferOwnAccountsScreen> createState() => _TransferOwnAccountsScreenState();
}

class _TransferOwnAccountsScreenState extends ConsumerState<TransferOwnAccountsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isAmountFocused = false;
  String? _selectedSourceAccountId;
  String? _selectedDestAccountId;

  @override
  void initState() {
    super.initState();
    _noteFocusNode.addListener(() => setState(() {}));
    // Pre-select first two accounts
    ref.read(depositAccountsAsyncProvider.future).then((accounts) {
      if (accounts.isNotEmpty && mounted && _selectedSourceAccountId == null) {
        setState(() {
          _selectedSourceAccountId = accounts.first.id;
          // Select second account as destination if available
          if (accounts.length > 1) {
            _selectedDestAccountId = accounts[1].id;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onReview() {
    if (_selectedSourceAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกบัญชีต้นทาง')));
      return;
    }

    if (_selectedDestAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกบัญชีปลายทาง')));
      return;
    }

    if (_selectedSourceAccountId == _selectedDestAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บัญชีต้นทางและปลายทางต้องไม่เหมือนกัน')));
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
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
    return DepositAccount(
      id: '',
      accountNumber: '',
      accountName: '',
      accountType: AccountType.savings,
      balance: 0,
      interestRate: 0,
      accruedInterest: 0,
      openedDate: DateTime.now(),
    );
  }

  Widget _buildConfirmationSheet(double amount, DepositAccount sourceAccount) {
    final accounts = ref.read(depositAccountsProvider);
    final destAccount = accounts.firstWhere(
      (a) => a.id == _selectedDestAccountId,
      orElse: () => _emptyAccount(),
    );

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
          _buildDetailRow('ไปยัง', '${destAccount.accountName}\n${destAccount.accountNumber}'),
          const SizedBox(height: 12),
          _buildDetailRow('จำนวนเงิน', NumberFormat('#,##0.00').format(amount), isBold: true),
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _processTransfer(double amount) async {
    // 1. PIN Check
    final pinSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (c) => const PinVerificationScreen()),
    );
    if (pinSuccess != true) return;

    try {
      await ref.read(depositActionProvider.notifier).transfer(
        sourceAccountId: _selectedSourceAccountId!,
        destinationAccountId: _selectedDestAccountId!,
        amount: amount,
        description: _noteController.text.isEmpty ? 'โอนเงินระหว่างบัญชี' : _noteController.text,
      );

      // Invalidate providers to refresh data immediately
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(depositAccountByIdAsyncProvider(_selectedSourceAccountId!));
      ref.invalidate(depositAccountByIdAsyncProvider(_selectedDestAccountId!));
      ref.invalidate(totalDepositBalanceAsyncProvider);

      if (mounted) {
        // Get account info for success screen
        final accounts = ref.read(depositAccountsProvider);
        final sourceAccount = accounts.firstWhere(
          (a) => a.id == _selectedSourceAccountId,
          orElse: () => _emptyAccount(),
        );
        final destAccount = accounts.firstWhere(
          (a) => a.id == _selectedDestAccountId,
          orElse: () => _emptyAccount(),
        );

        // Go to Success Screen
        context.go('/transfer/success', extra: {
          'transaction_id': 'TRF-OWN-${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'from_name': '${sourceAccount.accountName}\n${sourceAccount.accountNumber}',
          'target_name': '${destAccount.accountName}\n${destAccount.accountNumber}',
          'note': _noteController.text,
          'timestamp': DateTime.now().toIso8601String(),
          'repeat_text': 'โอนเงินอีกครั้ง',
          'repeat_route': '/transfer/own',
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

    // Calculate source balance to show
    String sourceBalanceStr = '0.00';
    if (_selectedSourceAccountId != null && accountsAsync.hasValue) {
      final account = accountsAsync.value!.firstWhere((a) => a.id == _selectedSourceAccountId, orElse: () => _emptyAccount());
      sourceBalanceStr = NumberFormat('#,##0.00').format(account.balance);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('โอนเงินระหว่างบัญชี'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Source Account Selection
            Align(
              alignment: Alignment.centerLeft,
              child: Text('จากบัญชี', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('ไม่มีบัญชี');
                }
                
                // Ensure valid source selection
                String? validSourceId = _selectedSourceAccountId;
                if (validSourceId == null || !accounts.any((a) => a.id == validSourceId)) {
                  validSourceId = accounts.first.id;
                  if (_selectedSourceAccountId != validSourceId) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedSourceAccountId = validSourceId);
                    });
                  }
                }
                
                return DropdownButtonFormField<String>(
                  value: validSourceId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        '${account.accountName} (${account.accountNumber})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSourceAccountId = val;
                      // If dest is same as source, clear it
                      if (_selectedDestAccountId == val) {
                        _selectedDestAccountId = null;
                      }
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error loading accounts'),
            ),

            const SizedBox(height: 24),

            // Arrow Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.arrowDown, color: AppColors.primary),
            ),

            const SizedBox(height: 24),

            // Destination Account Selection
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ไปยังบัญชี', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty || accounts.length < 2) {
                  return const Text('ต้องมีอย่างน้อย 2 บัญชี');
                }
                
                // Filter out source account
                final availableDestAccounts = accounts.where((a) => a.id != _selectedSourceAccountId).toList();
                if (availableDestAccounts.isEmpty) {
                  return const Text('ไม่มีบัญชีปลายทางที่เลือกได้');
                }

                // Ensure valid destination selection
                String? validDestId = _selectedDestAccountId;
                if (validDestId == null || !availableDestAccounts.any((a) => a.id == validDestId)) {
                  validDestId = availableDestAccounts.first.id;
                  if (_selectedDestAccountId != validDestId) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedDestAccountId = validDestId);
                    });
                  }
                }

                return DropdownButtonFormField<String>(
                  value: validDestId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: availableDestAccounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        '${account.accountName} (${account.accountNumber})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDestAccountId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error loading accounts'),
            ),

            const SizedBox(height: 32),

            // Amount Input
            Focus(
              onFocusChange: (hasFocus) => setState(() => _isAmountFocused = hasFocus),
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  CurrencyInputFormatter(),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: _isAmountFocused ? null : '0.00',
                  hintStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
              ),
            ),
            Text('ยอดเงินในบัญชีต้นทาง: $sourceBalanceStr', style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),

            const SizedBox(height: 32),
            TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: InputDecoration(
                hintText: _noteFocusNode.hasFocus ? null : 'บันทึกช่วยจำ (ถ้ามี)',
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
