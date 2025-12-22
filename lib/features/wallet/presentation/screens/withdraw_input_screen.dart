import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../../auth/presentation/screens/pin_verification_screen.dart'; // Import PIN screen
import '../../../../core/utils/currency_input_formatter.dart';

class WithdrawInputScreen extends ConsumerStatefulWidget {
  const WithdrawInputScreen({super.key});

  @override
  ConsumerState<WithdrawInputScreen> createState() => _WithdrawInputScreenState();
}

class _WithdrawInputScreenState extends ConsumerState<WithdrawInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  
  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  
  String? _selectedBank;
  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = true;

  String? _selectedSourceAccountId;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _accountFocusNode.addListener(() => setState(() {}));
    _amountFocusNode.addListener(() => setState(() {}));
    // Pre-select first account
    ref.read(depositAccountsAsyncProvider.future).then((accounts) {
      if (accounts.isNotEmpty && mounted && _selectedSourceAccountId == null) {
        setState(() {
          _selectedSourceAccountId = accounts.first.id;
        });
      }
    });
  }

  Future<void> _loadBanks() async {
    try {
      final jsonString = await rootBundle.loadString('assets/bank_logos/banks-logo.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<Map<String, dynamic>> loadedBanks = [];
      jsonData.forEach((key, value) {
        // Skip PromptPay and TrueMoney for bank transfer
        if (key != 'PromptPay' && key != 'TrueMoney') {
          loadedBanks.add({
            'id': key,
            'name': value['name'] ?? key,
            'icon': 'assets/bank_logos/$key.png',
          });
        }
      });
      // Sort: KTB first, then alphabetically by id
      loadedBanks.sort((a, b) {
        if (a['id'] == 'KTB') return -1;
        if (b['id'] == 'KTB') return 1;
        return (a['id'] as String).compareTo(b['id'] as String);
      });
      if (mounted) {
        setState(() {
          _banks = loadedBanks;
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading banks: $e');
      if (mounted) {
        setState(() => _isLoadingBanks = false);
      }
    }
  }

  void _showBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankSelectorSheet(
        banks: _banks,
        selectedBank: _selectedBank,
        onSelect: (bankId) {
          setState(() => _selectedBank = bankId);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _accountFocusNode.dispose();
    _amountFocusNode.dispose();
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
    
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount < 100) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดถอนขั้นต่ำ 100 บาท')));
      return;
    }

    // Check Balance logic (Optional here, can also rely on API/Notifier check)
    final accounts = ref.read(depositAccountsProvider);
    final sourceAccount = accounts.firstWhere((a) => a.id == _selectedSourceAccountId, orElse: () => DepositAccount(id: '', accountNumber: '', accountName: '', accountType: AccountType.savings, balance: 0, interestRate: 0, accruedInterest: 0, openedDate: DateTime.now()));
    
    if (sourceAccount.balance < amount) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('ยอดเงินไม่เพียงพอ (มี ${NumberFormat('#,##0.00').format(sourceAccount.balance)})'))
       );
       return;
    }

    // Navigate to review directly (PIN check is on the next screen)
    _performRealWithdrawal(amount);
  }

  Future<void> _performRealWithdrawal(double amount) async {
    // Navigate to Review Screen
    final bankName = _banks.firstWhere((b) => b['id'] == _selectedBank)['name'];
    final accountNo = _accountController.text;

    context.push('/wallet/withdraw/confirm', extra: {
      'accountId': _selectedSourceAccountId,
      'amount': amount,
      'bankName': bankName,
      'accountNo': accountNo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(depositAccountsAsyncProvider);
    final isProcessing = ref.watch(depositActionProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
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
                            '${NumberFormat('#,##0.00').format(account.balance)}',
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

            const Text('ธนาคาร', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _isLoadingBanks
                ? const Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: () => _showBankSelector(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          if (_selectedBank != null) ...[
                            Image.asset(
                              'assets/bank_logos/$_selectedBank.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance, color: Colors.grey, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _banks.firstWhere((b) => b['id'] == _selectedBank, orElse: () => {'name': ''})['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    _selectedBank!,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Icon(Icons.account_balance, color: Colors.grey),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('เลือกธนาคาร', style: TextStyle(color: Colors.grey))),
                          ],
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
            
            const SizedBox(height: 24),
            const Text('เลขที่บัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             TextField(
              controller: _accountController,
              focusNode: _accountFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: _accountFocusNode.hasFocus ? null : 'xxx-x-xxxxx-x',
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
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                prefixText: '',
                hintText: _amountFocusNode.hasFocus ? null : '0.00',
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

/// Fullscreen bank selector modal with search
class _BankSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  final String? selectedBank;
  final Function(String) onSelect;

  const _BankSelectorSheet({
    required this.banks,
    required this.selectedBank,
    required this.onSelect,
  });

  @override
  State<_BankSelectorSheet> createState() => _BankSelectorSheetState();
}

class _BankSelectorSheetState extends State<_BankSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = widget.banks;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredBanks = widget.banks.where((bank) {
          final name = (bank['name'] as String).toLowerCase();
          final id = (bank['id'] as String).toLowerCase();
          return name.contains(lowerQuery) || id.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ธนาคาร',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterBanks,
              decoration: InputDecoration(
                hintText: _searchFocusNode.hasFocus ? null : 'ค้นหาธนาคาร...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Bank List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBanks.length,
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                final isSelected = widget.selectedBank == bank['id'];
                return ListTile(
                  leading: Image.asset(
                    bank['icon'] as String,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.grey, size: 20),
                    ),
                  ),
                  title: Text(bank['name'] as String),
                  subtitle: Text(bank['id'] as String, style: TextStyle(color: Colors.grey[600])),
                  trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () => widget.onSelect(bank['id'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

