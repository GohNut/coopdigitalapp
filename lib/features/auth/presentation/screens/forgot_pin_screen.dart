import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/user_role.dart';
import 'pin_setup_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _idCardFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _idCardFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _phoneController.dispose();
    _idCardFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลืมรหัส PIN'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'กรุณากรอกข้อมูลเพื่อยืนยันตัวตน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
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
                decoration: _inputDecoration('ระบุเบอร์โทรศัพท์ที่ลงทะเบียน', _phoneFocusNode, counterText: ''),
                validator: (v) => v!.length < 9 ? 'ระบุเบอร์โทรศัพท์ให้ถูกต้อง' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyIdentity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ยืนยัน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyIdentity() {
    if (_formKey.currentState!.validate()) {
      final id = _idCardController.text.trim();
      final phone = _phoneController.text.trim();

      // Basic validation against CurrentUser (Simulation)
      // In real app, this should check against API. For now, since we only have CurrentUser loaded:
      // Note: If user is logged out, CurrentUser might be default/empty.
      // But typically "Forgot PIN" is accessed usually when trying to transact, so user is logged in.
      // EXCEPT: If it's accessed from Login? No, usually PIN is for transaction.
      // Wait, if user is not logged in, they can't access PinVerificationScreen usually (unless it's app lock).
      // Assuming user is logged in.
      
      bool isValid = false;
      if (CurrentUser.id == id) { // Simplified check
         isValid = true;
      }

      if (isValid) {
        // Navigate to Reset PIN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              onPinSet: (newPin) {
                // Update PIN (no need for setState - it's a static variable)
                CurrentUser.pin = newPin;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เปลี่ยนรหัส PIN เรียบร้อยแล้ว'), backgroundColor: Colors.green),
                );
                Navigator.pop(context); // Close PinSetup
                
                // Note: The previous screen (PinVerification) is still observing result?
                // Actually PinVerification expects a result only if PIN is entered correctly.
                // If we changed PIN successfully, we might want to auto-fill or just let user type it again.
                // Let's just return to PinVerification.
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ข้อมูลไม่ถูกต้อง'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String hint, FocusNode? focusNode, {String? counterText}) {
    return InputDecoration(
      hintText: (focusNode?.hasFocus ?? false) ? null : hint,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
