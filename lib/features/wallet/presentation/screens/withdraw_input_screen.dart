import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';

class WithdrawInputScreen extends ConsumerStatefulWidget {
  const WithdrawInputScreen({super.key});

  @override
  ConsumerState<WithdrawInputScreen> createState() => _WithdrawInputScreenState();
}

class _WithdrawInputScreenState extends ConsumerState<WithdrawInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController(); // Target bank account
  
  String? _selectedBank;
  final List<Map<String, String>> _banks = [
    {'id': 'KBANK', 'name': 'ธนาคารกสิกรไทย', 'icon': 'assets/images/kbank.png'}, // Placeholder icons
    {'id': 'SCB', 'name': 'ธนาคารไทยพาณิชย์', 'icon': 'assets/images/scb.png'},
    {'id': 'BBL', 'name': 'ธนาคารกรุงเทพ', 'icon': 'assets/images/bbl.png'},
    {'id': 'KTB', 'name': 'ธนาคารกรุงไทย', 'icon': 'assets/images/ktb.png'},
  ];

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
    _accountController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    // Basic validation
    if (_selectedSourceAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกบัญชีต้นทาง')));
      return;
    }
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกธนาคารปลายทาง')));
      return;
    }
    if (_accountController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุเลขบัญชีปลายทาง')));
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 100) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดถอนขั้นต่ำ 100 บาท')));
      return;
    }

    // Check Balance logic (Optional here, can also rely on API/Notifier check)
    final accounts = ref.read(depositAccountsProvider);
    final sourceAccount = accounts.firstWhere((a) => a.id == _selectedSourceAccountId, orElse: () => DepositAccount(id: '', accountNumber: '', accountName: '', accountType: AccountType.savings, balance: 0, interestRate: 0, accruedInterest: 0, openedDate: DateTime.now()));
    
    if (sourceAccount.balance < amount) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('ยอดเงินไม่เพียงพอ (มี ฿${NumberFormat('#,##0.00').format(sourceAccount.balance)})'))
       );
       return;
    }

    // Perform withdrawal logic directly here to mock review step or navigate to confirm
    _performRealWithdrawal(amount);
  }

  Future<void> _performRealWithdrawal(double amount) async {
    try {
      await ref.read(depositActionProvider.notifier).withdraw(
        accountId: _selectedSourceAccountId!,
        amount: amount,
        description: 'ถอนเงินเข้าบัญชี ${_banks.firstWhere((b) => b['id'] == _selectedBank)['name']} (${_accountController.text})',
      );

      if (mounted) {
        // Go to Success Screen
        context.go('/transfer/success', extra: {
          'transaction_id': 'WTD-${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'target_name': '${_banks.firstWhere((b) => b['id'] == _selectedBank)['name']}\n${_accountController.text}',
          'note': 'ถอนเงินสำเร็จ',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ถอนเงิน'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source Account Selection
             Text(
              'เลือกบัญชีต้นทาง (ถอนจาก)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const SizedBox();
                // Ensure selection
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('${account.accountName} (${account.accountNumber})', overflow: TextOverflow.ellipsis)),
                          Text(
                            '฿${NumberFormat('#,##0.00').format(account.balance)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSourceAccountId = val),
                  isExpanded: true,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading accounts: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            const Text('เลือกบัญชีธนาคารปลายทาง', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: _banks.map((bank) {
                  final isSelected = _selectedBank == bank['id'];
                  return RadioListTile<String>(
                    value: bank['id']!,
                    groupValue: _selectedBank,
                    onChanged: (val) => setState(() => _selectedBank = val),
                    title: Text(bank['name']!),
                    secondary: Container(
                      width: 40, 
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      // child: Image.asset(bank['icon']!), // Placeholder
                      child: const Icon(Icons.account_balance, color: Colors.grey),
                    ),
                    activeColor: AppColors.primary,
                    selected: isSelected,
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('เลขที่บัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'xxx-x-xxxxx-x',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('จำนวนเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              decoration: InputDecoration(
                prefixText: '฿ ',
                hintText: '0.00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
                suffixText: 'บาท'
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('ขั้นต่ำ 100.00 บาท', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isProcessing 
                 ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                 : const Text('ยืนยันการถอนเงิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
