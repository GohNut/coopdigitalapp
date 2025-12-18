import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../domain/loan_request_args.dart';
import '../../../../services/dynamic_deposit_api.dart'; // Import API Service

class LoanInfoScreen extends ConsumerStatefulWidget {
  final LoanRequestArgs args;

  const LoanInfoScreen({super.key, required this.args});

  @override
  ConsumerState<LoanInfoScreen> createState() => _LoanInfoScreenState();
}

class _LoanInfoScreenState extends ConsumerState<LoanInfoScreen> {
  final TextEditingController _objectiveController = TextEditingController();
  final TextEditingController _guarantorIdCardController = TextEditingController();
  final TextEditingController _guarantorNameController = TextEditingController();
  final TextEditingController _guarantorRelationController = TextEditingController();
  final TextEditingController _guarantorPhoneController = TextEditingController(); // Phone Controller
  
  String _guarantorType = 'member'; // 'member' or 'external'
  DepositAccount? _selectedAccount;

  @override
  void dispose() {
    _objectiveController.dispose();
    _guarantorIdCardController.dispose();
    _guarantorNameController.dispose();
    _guarantorRelationController.dispose();
    _guarantorPhoneController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกบัญชีรับเงินกู้')),
      );
      return;
    }
    
    final updatedArgs = widget.args.copyWith(
      objective: _objectiveController.text.isEmpty ? null : _objectiveController.text,
      guarantorMemberId: _guarantorIdCardController.text.isEmpty ? null : _guarantorIdCardController.text,
      guarantorType: _guarantorType,
      guarantorName: _guarantorNameController.text.isEmpty ? null : _guarantorNameController.text,
      guarantorRelationship: _guarantorRelationController.text.isEmpty ? null : _guarantorRelationController.text,
      guarantorPhone: _guarantorPhoneController.text.isEmpty ? null : _guarantorPhoneController.text,
      depositAccountId: _selectedAccount!.id,
      depositAccountNumber: _selectedAccount!.accountNumber,
      depositAccountName: _selectedAccount!.accountName,
    );
    context.push('/loan/document', extra: updatedArgs);
  }

  bool _isSearching = false;
  bool _memberFound = false;

  Future<void> _searchMember() async {
    final idCard = _guarantorIdCardController.text;
    if (idCard.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกเลขบัตรประชาชน 13 หลัก')));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final member = await DynamicDepositApiService.getMember(idCard);
      setState(() {
         _isSearching = false;
         if (member != null) {
           _guarantorNameController.text = member['name_th'] ?? '';
           _guarantorPhoneController.text = member['mobile'] ?? '';
           _guarantorRelationController.text = 'สมาชิกสหกรณ์'; 
           _memberFound = true;
         } else {
           _memberFound = false;
           // Clear fields if not found or keep them empty? User didn't specify. Assuming clear or show error.
           _guarantorNameController.clear();
           _guarantorPhoneController.clear();
           _guarantorRelationController.clear();
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลสมาชิก')));
         }
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.args.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ข้อมูลการกู้'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              children: [
                _buildStepIndicator(1, 'วงเงิน', true),
                _buildStepLine(true),
                _buildStepIndicator(2, 'ข้อมูล', true),
                _buildStepLine(false),
                _buildStepIndicator(3, 'เอกสาร', false),
                _buildStepLine(false),
                _buildStepIndicator(4, 'ยืนยัน', false),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Objective Input
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'วัตถุประสงค์การกู้',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _objectiveController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'เช่น ซื้อรถ, ซ่อมบ้าน, ค่าเทอมบุตร',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Deposit Account Selector
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'บัญชีรับเงินกู้',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เลือกบัญชีที่ต้องการรับเงินกู้',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ref.watch(depositAccountsAsyncProvider).when(
                      data: (accounts) {
                        // Filter for only 'loan' type accounts
                        final loanAccounts = accounts.where((a) => a.accountType == AccountType.loan).toList();

                        if (loanAccounts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ไม่พบบัญชีเงินฝาก กรุณาเปิดบัญชีก่อน',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        
                        return Column(
                          children: loanAccounts.map((account) {
                            final isSelected = _selectedAccount?.id == account.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAccount = account),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.accountName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? AppColors.primary : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            account.accountNumber,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ไม่สามารถโหลดข้อมูลบัญชีได้',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Guarantor Section
            if (product.requireGuarantor) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'ข้อมูลผู้ค้ำประกัน',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'กรุณาเลือกประเภทผู้ค้ำประกัน',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // ตัวเลือกประเภทผู้ค้ำ
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _guarantorType = 'member'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _guarantorType == 'member' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _guarantorType == 'member' ? AppColors.primary : Colors.grey.shade300,
                                    width: _guarantorType == 'member' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.badge,
                                      size: 32,
                                      color: _guarantorType == 'member' ? AppColors.primary : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'สมาชิกสหกรณ์',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _guarantorType == 'member' ? AppColors.primary : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _guarantorType = 'external'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _guarantorType == 'external' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _guarantorType == 'external' ? AppColors.primary : Colors.grey.shade300,
                                    width: _guarantorType == 'external' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 32,
                                      color: _guarantorType == 'external' ? AppColors.primary : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'บุคคลภายนอก',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _guarantorType == 'external' ? AppColors.primary : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // ฟอร์มกรอกข้อมูลตามประเภท
                      // 1. เลขบัตรประชาชน (แสดงเสมอ)
                      const Text('เลขบัตรประชาชนผู้ค้ำประกัน', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      // If member: Row with Search Button
                      // If external: TextField only
                        if (_guarantorType == 'member') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _guarantorIdCardController,
                                  style: const TextStyle(fontSize: 16),
                                  keyboardType: TextInputType.number,
                                  maxLength: 13,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    hintText: 'กรอกเลขบัตรประชาชน 13 หลัก',
                                    prefixIcon: const Icon(Icons.credit_card),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    counterText: "",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSearching ? null : _searchMember,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isSearching 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Icon(Icons.search, color: Colors.white),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            controller: _guarantorIdCardController,
                            style: const TextStyle(fontSize: 16),
                            keyboardType: TextInputType.number,
                            maxLength: 13,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: 'กรอกเลขบัตรประชาชน 13 หลัก',
                              prefixIcon: const Icon(Icons.credit_card),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              counterText: "",
                            ),
                          ),
                        ],
                      const SizedBox(height: 16),
                      
                      // Show fields for both Member (Auto-filled/Locked) and External (Editable)
                      // If type is member and not found yet, maybe hide? But user said show 4 fields.
                      // Let's show them always, but change readOnly state.
                      
                      const Text('ชื่อ - นามสกุล ผู้ค้ำประกัน', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _guarantorNameController,
                        readOnly: _guarantorType == 'member' && _memberFound,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'กรอกชื่อ-นามสกุล',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: (_guarantorType == 'member' && _memberFound) ? Colors.grey.shade200 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text('เบอร์โทรศัพท์', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _guarantorPhoneController,
                        readOnly: _guarantorType == 'member' && _memberFound,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'กรอกเบอร์โทรศัพท์',
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: (_guarantorType == 'member' && _memberFound) ? Colors.grey.shade200 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('ความสัมพันธ์กับผู้กู้', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _guarantorRelationController,
                        readOnly: _guarantorType == 'member' && _memberFound,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'เช่น บิดา, มารดา, พี่น้อง, เพื่อน',
                          prefixIcon: const Icon(Icons.family_restroom),
                          filled: true,
                          fillColor: (_guarantorType == 'member' && _memberFound) ? Colors.grey.shade200 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ไม่ต้องใช้ผู้ค้ำประกัน',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'สินเชื่อประเภท ${product.name} ใช้หุ้นสะสมเป็นหลักประกัน',
                              style: TextStyle(fontSize: 13, color: Colors.green.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'ถัดไป',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}
