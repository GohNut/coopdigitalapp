import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../domain/user_role.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../deposit/data/deposit_providers.dart';
import 'pin_setup_screen.dart'; // Import Pin Setup

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: CurrentUser.name);
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _idCardFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _idCardFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _idCardFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สมัครสมาชิกสหกรณ์'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'กรุณากรอกข้อมูลเพื่อทำการสมัครสมาชิกสหกรณ์ออมทรัพย์',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form
              _buildInputLabel('ชื่อ-นามสกุล'),
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: _inputDecoration('ระบุชื่อ-นามสกุล', _nameFocusNode),
                validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ' : null,
              ),
              const SizedBox(height: 16),

              _buildInputLabel('เลขบัตรประชาชน'),
              TextFormField(
                controller: _idCardController,
                focusNode: _idCardFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: _inputDecoration('ระบุเลขบัตรประชาชน 13 หลัก', _idCardFocusNode, counterText: ''),
                validator: (v) => v!.length != 13 ? 'ระบุให้ครบ 13 หลัก' : null,
              ),
              const SizedBox(height: 16),

              _buildInputLabel('เบอร์โทรศัพท์'),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration('ระบุเบอร์โทรศัพท์', _phoneFocusNode, counterText: ''),
                validator: (v) => v!.length < 9 ? 'ระบุเบอร์โทรศัพท์ให้ถูกต้อง' : null,
              ),
              
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onNextPressed, // Changed from _submitRegistration
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ดำเนินการต่อ', // Changed text
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onNextPressed() async {
    if (_formKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final idCard = _idCardController.text.trim();
        final member = await DynamicDepositApiService.getMember(idCard);
        
        // Hide loading
        if (!mounted) return;
        Navigator.pop(context);

        if (member != null) {
          // ID already exists
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เลขบัตรประชาชนนี้ถูกใช้งานแล้ว'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Navigate to PIN Setup
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              onPinSet: (pin) {
                Navigator.pop(context); // Close PIN screen
                _submitRegistration(pin); // Proceed to submit with PIN
              },
            ),
          ),
        );

      } catch (e) {
        // Hide loading
        if (!mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRegistration(String pin) async {
    // No need to validate again as it was done before PIN setup
    setState(() {
        // Show loading dialog or simple snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังบันทึกข้อมูล...')),
        );
      });

      try {
        final idCard = _idCardController.text.trim();
        final name = _nameController.text.trim();
        final mobile = _phoneController.text.trim();

        // 1. Call API to create member
        await DynamicDepositApiService.createMember(
          citizenId: idCard,
          nameTh: name,
          mobile: mobile,
          pin: pin, // Pass PIN
        );

        // 2. Auto-create Savings Account
        final randomAccountNo = '2${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-${(10000 + DateTime.now().microsecond % 90000).toString()}';
        await DynamicDepositApiService.createAccount(
          memberId: idCard,
          accountNumber: randomAccountNo,
          accountName: 'บัญชีออมทรัพย์ - $name',
          accountType: 'savings',
          interestRate: 0.25,
        );

        // 3. Auto-create Loan Account (บัญชีเงินกู้สหกรณ์)
        final loanAccountNo = '5${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-${(10000 + DateTime.now().microsecond % 90000).toString()}';
        await DynamicDepositApiService.createAccount(
          memberId: idCard,
          accountNumber: loanAccountNo,
          accountName: 'บัญชีเงินกู้สหกรณ์ - $name',
          accountType: 'loan',
          interestRate: 0.0, // ดอกเบี้ยคิดตามสัญญากู้
        );

        if (!mounted) return;

        // Success -> Update User State
        CurrentUser.setUser(
          newName: name,
          newId: idCard, // Use ID Card as ID
          newRole: UserRole.member,
          newIsMember: true,
          newPin: pin,
        );
        
        // Invalidate providers to fetch the newly created account
        ref.invalidate(depositAccountsAsyncProvider);
        ref.invalidate(totalDepositBalanceAsyncProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกและเปิดบัญชีสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to Home
        context.go('/home');

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
  }

  InputDecoration _inputDecoration(String hint, FocusNode? focusNode, {String? counterText}) {
    return InputDecoration(
      hintText: (focusNode?.hasFocus ?? false) ? null : hint,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
