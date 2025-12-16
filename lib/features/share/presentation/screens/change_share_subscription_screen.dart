import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/share_repository_impl.dart';

class ChangeShareSubscriptionScreen extends StatefulWidget {
  const ChangeShareSubscriptionScreen({super.key});

  @override
  State<ChangeShareSubscriptionScreen> createState() => _ChangeShareSubscriptionScreenState();
}

class _ChangeShareSubscriptionScreenState extends State<ChangeShareSubscriptionScreen> {
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _repository = ShareRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    // Validate minimum amount (Mock 500 baht)
    if (amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยอดส่งขั้นต่ำ 500 บาท')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mock PIN verification delay
      await Future.delayed(const Duration(seconds: 1));
      
      final success = await _repository.changeMonthlySubscription(amount);
      
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(LucideIcons.calendarCheck, color: Colors.blue, size: 48),
            title: const Text('ดำเนินการสำเร็จ'),
            content: const Text('รายการเปลี่ยนแปลงยอดส่งรายเดือนจะเริ่มมีผลในเดือนถัดไป (T+1 Month)'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); 
                  context.go('/share'); 
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('เปลี่ยนยอดส่งรายเดือน'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                         'ยอดปัจจุบัน: 1,000 บาท/เดือน',
                         style: TextStyle(color: Colors.blue.shade900),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 24),
               
               const Text("ระบุยอดส่งใหม่ที่ต้องการ", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 8),
               TextFormField(
                 controller: _amountController,
                 focusNode: _amountFocusNode,
                 keyboardType: TextInputType.number,
                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                 decoration: InputDecoration(
                   suffixText: 'บาท/เดือน',
                   filled: true,
                   fillColor: Colors.white,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(16),
                     borderSide: BorderSide.none,
                   ),
                   contentPadding: const EdgeInsets.all(20),
                   hintText: _amountFocusNode.hasFocus ? null : 'ขั้นต่ำ 500',
                 ),
                 validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณาตัวเลข';
                    return null;
                 },
               ),
               
               const SizedBox(height: 48),
               
               SizedBox(
                 height: 56,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _submit,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(16),
                     ),
                     elevation: 0,
                   ),
                   child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ยืนยันยอดใหม่', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
