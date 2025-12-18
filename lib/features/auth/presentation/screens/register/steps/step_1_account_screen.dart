import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../providers/registration_provider.dart';
import '../../../../domain/models/registration_form_model.dart';

class Step1AccountScreen extends ConsumerStatefulWidget {
  const Step1AccountScreen({super.key});

  @override
  ConsumerState<Step1AccountScreen> createState() => _Step1AccountScreenState();
}

class _Step1AccountScreenState extends ConsumerState<Step1AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _idCardController;
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  final _idCardMask = MaskTextInputFormatter(
    mask: '#-####-#####-##-#', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  final _mobileMask = MaskTextInputFormatter(
    mask: '###-###-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationProvider);
    final account = state.form.accountInfo;
    
    _emailController = TextEditingController(text: account.email);
    _idCardController = TextEditingController(text: account.citizenId); // Assume unmasked stored? Or re-mask? 
    // If stored unmasked, we need to apply mask to initial value if meaningful. 
    // For simplicity, let's assume if it's not empty, it's valid 13 digits, so we mask it.
    if (account.citizenId.isNotEmpty) {
      _idCardController.text = _idCardMask.maskText(account.citizenId);
    }

    _mobileController = TextEditingController(text: account.mobile);
    if (account.mobile.isNotEmpty) {
      _mobileController.text = _mobileMask.maskText(account.mobile);
    }

    _passwordController = TextEditingController(text: account.password);
    _confirmPasswordController = TextEditingController(text: account.confirmPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _idCardController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email (Optional)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'อีเมล (ไม่บังคับ)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // ID Card
            TextFormField(
              controller: _idCardController,
              inputFormatters: [_idCardMask],
              decoration: const InputDecoration(
                labelText: 'เลขบัตรประชาชน',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
                hintText: 'x-xxxx-xxxxx-xx-x'
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกเลขบัตรประชาชน';
                }
                if (_idCardMask.getUnmaskedText().length != 13) {
                  return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                }
                // Checksum validation could be added here
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile
            TextFormField(
              controller: _mobileController,
              inputFormatters: [_mobileMask],
              decoration: const InputDecoration(
                labelText: 'เบอร์มือถือ',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                hintText: 'xxx-xxx-xxxx'
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกเบอร์มือถือ';
                }
                if (_mobileMask.getUnmaskedText().length != 10) {
                  return 'เบอร์มือถือต้องมี 10 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสผ่าน';
                }
                if (value.length < 8) {
                  return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                }
                // Complex password validation could be added here
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'ยืนยันรหัสผ่าน',
                prefixIcon: const Icon(Icons.lock_clock),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: !_isConfirmPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณายืนยันรหัสผ่าน';
                }
                if (value != _passwordController.text) {
                  return 'รหัสผ่านไม่ตรงกัน';
                }
                return null;
              },
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('กลับ'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _onNext,
                      child: state.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ถัดไป'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(registrationProvider.notifier);
      final citizenId = _idCardMask.getUnmaskedText();
      final mobile = _mobileMask.getUnmaskedText();

      // Check duplicate
      final isSuccess = await notifier.checkDuplicate(citizenId, mobile);
      
      if (isSuccess && mounted) {
        // Save state
        notifier.updateAccountInfo(
          AccountInfo(
            email: _emailController.text.trim(),
            citizenId: citizenId,
            mobile: mobile,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          )
        );
        // Go to next step
        notifier.nextStep();
      }
    }
  }
}
