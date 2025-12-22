import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/kyc_required_dialog.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../../deposit/data/deposit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const ShareConfirmationScreen({super.key, required this.args});

  @override
  ConsumerState<ShareConfirmationScreen> createState() => _ShareConfirmationScreenState();
}

class _ShareConfirmationScreenState extends ConsumerState<ShareConfirmationScreen> {
  final _repository = ShareRepositoryImpl();
  bool _isConsent = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    // 1. PIN Verification
    final isVerified = await context.push<bool>('/pin');
    if (isVerified != true) return;

    setState(() => _isLoading = true);
    
    try {
      final units = widget.args['units'] as int;
      final netTotal = widget.args['netTotal'] as double;
      final method = widget.args['paymentMethod'] as String;
      final paymentSourceId = widget.args['paymentSourceId'] as String?;
      
      // 2. ตัดเงินจากแหล่งชำระเงิน (ถ้าเป็นบัญชีออมทรัพย์)
      if (paymentSourceId != null && paymentSourceId.isNotEmpty) {
        final accountData = await DynamicDepositApiService.getAccountById(paymentSourceId);
        if (accountData != null) {
          final currentBalance = (accountData['balance'] ?? 0.0).toDouble();
          
          // ตรวจสอบยอดเงินเพียงพอ
          if (currentBalance < netTotal) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ยอดเงินในบัญชีไม่เพียงพอ'),
                  backgroundColor: Colors.red,
                )
              );
              setState(() => _isLoading = false);
            }
            return;
          }
          
          // ตัดเงินจากบัญชี (ใช้ payment แทน withdraw เพื่อให้แสดงเป็น "จ่ายเงิน")
          await DynamicDepositApiService.payment(
            accountId: paymentSourceId,
            amount: netTotal,
            currentBalance: currentBalance,
            description: 'ซื้อหุ้นสหกรณ์ $units หุ้น',
          );
        }
      }
      
      // 3. ซื้อหุ้น
      await _repository.buyShare(
        units: units,
        amount: netTotal,
        paymentMethod: method,
        paymentSourceId: paymentSourceId ?? '',
      );

      // Invalidate providers to refresh data immediately
      ref.invalidate(depositAccountsAsyncProvider);
      if (paymentSourceId != null && paymentSourceId.isNotEmpty) {
        ref.invalidate(depositAccountByIdAsyncProvider(paymentSourceId));
      }
      ref.invalidate(totalDepositBalanceAsyncProvider);

      if (mounted) {
         // Go to Step 4: Success
         context.go('/share/buy/success');
      }
    } catch (e) {
      if (mounted) {
        // ตรวจจับ KYC error และแสดง Dialog แทน SnackBar
        if (isKYCError(e)) {
          await showKYCRequiredDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            )
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final unitFormat = NumberFormat("#,##0", "th_TH");
    
    final units = widget.args['units'] as int;
    final price = widget.args['pricePerUnit'] as double;
    final totalBody = widget.args['totalBody'] as double;
    final netTotal = widget.args['netTotal'] as double;
    final method = widget.args['paymentMethod'] as String;
    final paymentSourceId = widget.args['paymentSourceId'] as String?;

    // Get payment method label
    String methodLabel = 'ไม่ทราบ';
    String? accountInfo;
    
    if (method == 'qr') {
      methodLabel = 'QR PromptPay';
    } else if (method == 'account' && paymentSourceId != null) {
      // ดึงข้อมูลบัญชีจาก provider
      final accounts = ref.watch(depositAccountsProvider);
      final account = accounts.where((a) => a.id == paymentSourceId).firstOrNull;
      
      if (account != null) {
        methodLabel = 'บัญชีออมทรัพย์';
        accountInfo = '${account.accountName} (${account.maskedAccountNumber})';
      } else {
        methodLabel = 'บัญชีออมทรัพย์';
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ตรวจสอบและยืนยัน (3/4)'),
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
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.fileText, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('สรุปรายการคำสั่งซื้อ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  
                  _buildRow('จำนวนหุ้น', '${unitFormat.format(units)} หุ้น'),
                  const SizedBox(height: 8),
                  _buildRow('ราคาต่อหน่วย', '${currencyFormat.format(price)} บาท'),
                  const SizedBox(height: 8),
                  _buildRow('ราคารวม', '${currencyFormat.format(totalBody)} บาท'),
                  const Divider(height: 24),
                  _buildRow('ยอดชำระสุทธิ', '${currencyFormat.format(netTotal)} บาท', isTotal: true),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.wallet, size: 20, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text('ชำระผ่าน: $methodLabel', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        if (accountInfo != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Text(accountInfo, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _isConsent, 
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isConsent = val!)
                ),
                const Expanded(child: Text('ฉันตรวจสอบข้อมูลถูกต้องและยืนยันการชำระเงิน', style: TextStyle(fontSize: 14))),
              ],
            ),
            
            const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               height: 56,
               child: ElevatedButton(
                 onPressed: (!_isConsent || _isLoading) ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                 ),
                 child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ยืนยันการซื้อหุ้น', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isHighlight ? Colors.orange : Colors.grey.shade700,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
        )),
        Expanded(child: Text(value, style: TextStyle(
          fontWeight: isTotal || isHighlight ? FontWeight.bold : FontWeight.w600,
          fontSize: isTotal ? 20 : 14,
          color: isTotal ? AppColors.primary : (isHighlight ? Colors.orange : Colors.black),
        ), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
