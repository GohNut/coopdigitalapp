import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../../auth/presentation/screens/pin_verification_screen.dart'; // Import PIN screen
import '../../../../core/utils/currency_input_formatter.dart';

class TopUpAmountScreen extends ConsumerStatefulWidget {
  const TopUpAmountScreen({super.key});

  @override
  ConsumerState<TopUpAmountScreen> createState() => _TopUpAmountScreenState();
}

class _TopUpAmountScreenState extends ConsumerState<TopUpAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final List<double> _chips = [100, 500, 1000, 5000];
  String? _errorText;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    // Pre-select first account when data loads
    ref.read(depositAccountsAsyncProvider.future).then((accounts) {
      if (accounts.isNotEmpty && mounted && _selectedAccountId == null) {
        setState(() {
          _selectedAccountId = accounts.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onChipSelected(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
      _errorText = null;
    });
  }

  void _validateAndSubmit() {
    final input = _amountController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorText = 'กรุณาระบุจำนวนเงิน';
      });
      return;
    }

    final amount = double.tryParse(input.replaceAll(',', ''));
    if (amount == null || amount < 1.0) {
      setState(() {
        _errorText = 'จำนวนเงินต้องมากกว่า 1.00 บาท';
      });
      return;
    }

    // Navigate to QR Screen with amount
    context.push('/wallet/topup/qr', extra: amount);
  }

  Future<void> _performRealDeposit() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกบัญชีเงินฝาก')),
      );
      return;
    }

    final input = _amountController.text.trim();
    final amount = double.tryParse(input.replaceAll(',', ''));

    if (amount == null || amount < 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินขั้นต่ำ 100 บาท')),
      );
      return;
    }

    // PIN Verification
    final pinResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (c) => const PinVerificationScreen()),
    );

    if (pinResult != true) {
      // PIN failed or cancelled
      return;
    }

    // Call Provider Logic
    try {
      await ref.read(depositActionProvider.notifier).deposit(
        accountId: _selectedAccountId!,
        amount: amount,
        description: 'ฝากเงิน (แอพมือถือ)',
      );

      if (mounted) {
        // Navigate to Success Screen (Using transfer success screen as placeholder or navigate back to account book)
        // Here we simulate going to success screen with real data
         context.go('/transfer/success', extra: {
            'transaction_id': 'DEP-${DateTime.now().millisecondsSinceEpoch}',
            'amount': amount,
            'target_name': 'บัญชีเงินฝากของฉัน',
            'note': 'ฝากเงินสำเร็จ',
            'timestamp': DateTime.now().toIso8601String(),
          });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(depositAccountsAsyncProvider);
    final isDepositing = ref.watch(depositActionProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ฝากเงิน'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Selection
            Text(
              'เลือกบัญชีรับเงิน',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                   return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('ไม่พบบัญชีเงินฝาก')));
                }
                
                // Set default if not set
                if (_selectedAccountId == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedAccountId = accounts.first.id);
                    });
                }

                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
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
                      child: Text(
                        '${account.accountName} (${account.accountNumber})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),

            Text(
              'ระบุจำนวนเงินที่ต้องการเติม',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
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
                errorText: _errorText,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
                prefixStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'เลือกจำนวนเงิน',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _chips.map((amount) {
                return ActionChip(
                  label: Text('${amount.toStringAsFixed(0)}'),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  onPressed: () => _onChipSelected(amount),
                  labelStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            
            // Generate QR Button (Original Flow)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isDepositing ? null : _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'สร้าง QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Toggle Real Deposit Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: isDepositing ? null : _performRealDeposit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: isDepositing ? Colors.green.withOpacity(0.1) : null,
                ),
                child: isDepositing 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                  '✅ ฝากเงินเข้าบัญชีจริง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
