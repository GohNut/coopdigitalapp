import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/loan_product_model.dart';
import '../../data/loan_repository_impl.dart';

/// ฟอร์มสร้าง/แก้ไขประเภทเงินกู้
class LoanProductFormScreen extends StatefulWidget {
  final LoanProduct? product; // null = create mode, not null = edit mode

  const LoanProductFormScreen({super.key, this.product});

  @override
  State<LoanProductFormScreen> createState() => _LoanProductFormScreenState();
}

class _LoanProductFormScreenState extends State<LoanProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final repository = LoanRepositoryImpl();
  
  // Form controllers
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _maxMonthsController;
  
  bool _requireGuarantor = false;
  bool _isLoading = false;
  
  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    final product = widget.product;
    _idController = TextEditingController(text: product?.id ?? '');
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _maxAmountController = TextEditingController(
      text: product != null ? product.maxAmount.toStringAsFixed(0) : '',
    );
    _interestRateController = TextEditingController(
      text: product != null ? product.interestRate.toString() : '',
    );
    _maxMonthsController = TextEditingController(
      text: product != null ? product.maxMonths.toString() : '',
    );
    _requireGuarantor = product?.requireGuarantor ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _maxAmountController.dispose();
    _interestRateController.dispose();
    _maxMonthsController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final product = LoanProduct(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        maxAmount: double.parse(_maxAmountController.text.replaceAll(',', '')),
        interestRate: double.parse(_interestRateController.text),
        maxMonths: int.parse(_maxMonthsController.text),
        requireGuarantor: _requireGuarantor,
        conditions: widget.product?.conditions ?? [],
      );
      
      await repository.saveLoanProduct(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'แก้ไขประเภทเงินกู้เรียบร้อย' : 'เพิ่มประเภทเงินกู้เรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permission
    if (!CurrentUser.isOfficerOrApprover) {
      return Scaffold(
        appBar: AppBar(title: const Text('กำหนดประเภทเงินกู้')),
        body: const Center(child: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'แก้ไขประเภทเงินกู้' : 'เพิ่มประเภทเงินกู้'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product ID
            _buildTextField(
              controller: _idController,
              label: 'รหัสประเภทเงินกู้',
              hint: 'เช่น emergency, housing, personal',
              icon: LucideIcons.hash,
              enabled: !isEditMode, // Cannot edit ID in edit mode
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสประเภทเงินกู้';
                }
                if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(value)) {
                  return 'ใช้ได้เฉพาะ a-z, 0-9, _ และ -';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Name
            _buildTextField(
              controller: _nameController,
              label: 'ชื่อประเภทเงินกู้',
              hint: 'เช่น สินเชื่อฉุกเฉิน',
              icon: LucideIcons.type,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อประเภทเงินกู้';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'คำอธิบาย',
              hint: 'รายละเอียดประเภทเงินกู้',
              icon: LucideIcons.fileText,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกคำอธิบาย';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Section: Financial Details
            Text(
              'รายละเอียดทางการเงิน',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Max Amount
            _buildTextField(
              controller: _maxAmountController,
              label: 'วงเงินสูงสุด (บาท)',
              hint: 'เช่น 500000',
              icon: LucideIcons.banknote,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกวงเงินสูงสุด';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Interest Rate
            _buildTextField(
              controller: _interestRateController,
              label: 'อัตราดอกเบี้ย (% ต่อปี)',
              hint: 'เช่น 6.5',
              icon: LucideIcons.percent,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกอัตราดอกเบี้ย';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) {
                  return 'กรุณากรอกอัตราดอกเบี้ยที่ถูกต้อง (0-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Max Months
            _buildTextField(
              controller: _maxMonthsController,
              label: 'ระยะเวลาผ่อนสูงสุด (งวด)',
              hint: 'เช่น 120',
              icon: LucideIcons.calendar,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกระยะเวลาผ่อนสูงสุด';
                }
                final months = int.tryParse(value);
                if (months == null || months <= 0) {
                  return 'กรุณากรอกจำนวนงวดที่ถูกต้อง';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Section: Requirements
            Text(
              'เงื่อนไข',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Require Guarantor Switch
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: SwitchListTile(
                title: const Text('ต้องมีผู้ค้ำประกัน'),
                subtitle: const Text('กำหนดว่าต้องมีผู้ค้ำหรือไม่'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.userCheck, color: AppColors.primary),
                ),
                value: _requireGuarantor,
                onChanged: (value) {
                  setState(() => _requireGuarantor = value);
                },
                activeColor: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button (alternative to AppBar action)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.save),
                label: Text(
                  _isLoading ? 'กำลังบันทึก...' : 'บันทึกประเภทเงินกู้',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
