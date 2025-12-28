import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/registration_provider.dart';
import '../../../../domain/models/registration_form_model.dart';
import '../../pin_setup_screen.dart';
import '../../../../../../services/dynamic_deposit_api.dart';
import '../../../../domain/user_role.dart'; // Import for CurrentUser
import '../../../../../../features/deposit/data/deposit_providers.dart';
import '../../../../../../features/notification/presentation/providers/notification_provider.dart';



class Step4ConsentScreen extends ConsumerStatefulWidget {
  const Step4ConsentScreen({super.key});

  @override
  ConsumerState<Step4ConsentScreen> createState() => _Step4ConsentScreenState();
}

class _Step4ConsentScreenState extends ConsumerState<Step4ConsentScreen> {
  // We can use local state for checkboxes if we don't strictly need to persist them across steps (usually last step),
  // but to be safe and consistent with "Global State", let's use the provider.
  // Actually, the provider already has `Consent` model.
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    final form = state.form;
    final consent = form.consent;
    final notifier = ref.read(registrationProvider.notifier);

    final isAllAccepted = consent.ruleAccepted && 
                          consent.feeAgreement && 
                          consent.pdpaAccepted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ยืนยันข้อมูลและข้อตกลง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryItem('เลขบัตรประชาชน', form.accountInfo.citizenId), // Masking needed?
                  _buildSummaryItem('ชื่อ-นามสกุล', form.personalInfo.fullName),
                  _buildSummaryItem('เบอร์มือถือ', form.accountInfo.mobile),
                  _buildSummaryItem('อาชีพ', _getOccupationLabel(form.occupationInfo.occupationType)),
                  _buildSummaryItem('รายได้', '${NumberFormat('#,##0.00').format(form.occupationInfo.income ?? 0)} บาท'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Consents
          const Text('ข้อตกลงและเงื่อนไข', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          _buildCheckbox(
            title: 'ข้าพเจ้ายอมรับระเบียบและข้อบังคับของสหกรณ์',
            value: consent.ruleAccepted,
            onChanged: (val) => notifier.updateConsent(consent.copyWith(ruleAccepted: val)),
          ),
          _buildCheckbox(
            title: 'ข้าพเจ้ายินยอมให้หักเงินค่าธรรมเนียมแรกเข้า',
            value: consent.feeAgreement,
            onChanged: (val) => notifier.updateConsent(consent.copyWith(feeAgreement: val)),
          ),
          _buildCheckbox(
             title: 'ข้าพเจ้ายินยอมให้ข้อมูลส่วนบุคคล (PDPA)',
             value: consent.pdpaAccepted,
             onChanged: (val) => notifier.updateConsent(consent.copyWith(pdpaAccepted: val)),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : notifier.prevStep,
                  child: const Text('ย้อนกลับ'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isAllAccepted && !state.isLoading) 
                      ? _onSubmit 
                      : null,
                  child: state.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('สมัครสมาชิก'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildCheckbox({required String title, required bool value, required ValueChanged<bool?> onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  String _getOccupationLabel(String type) {
    switch (type) {
      case 'company_employee': return 'พนักงานบริษัท';
      case 'self_employed': return 'ประกอบกิจการส่วนตัว';
      case 'government': return 'รับราชการ';
      case 'other': return 'อื่นๆ';
      default: return type;
    }
  }

  Future<void> _onSubmit() async {
    if (!mounted) return;
    
    // Navigate to PIN setup
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          onPinSet: (pin) async {
            final notifier = ref.read(registrationProvider.notifier);
            final form = ref.read(registrationProvider).form;
            
            // Submit registration with PIN
            final success = await notifier.submitRegistration(pin: pin);
            if (success && mounted) {
              
              // Auto-Login Logic
              await CurrentUser.setUser(
                newName: form.personalInfo.fullName,
                newId: form.accountInfo.citizenId,
                newRole: UserRole.member,
                newIsMember: true,
                newPin: pin,
              );
              
              // Invalidate providers to ensure data is fresh
              ref.invalidate(depositAccountsAsyncProvider);
              ref.invalidate(totalDepositBalanceAsyncProvider);
              ref.invalidate(notificationProvider);

              // Navigate to Home
              if (mounted) context.go('/home');
              
              // Show success message after navigation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('สมัครสมาชิกสำเร็จและเข้าสู่ระบบเรียบร้อยแล้ว'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            } else if (mounted) {
              // Show error and close PIN screen
              final error = ref.read(registrationProvider).error ?? 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
              Navigator.of(context).pop(); // Only pop on error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
