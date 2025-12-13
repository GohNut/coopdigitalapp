import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_request_args.dart';

class LoanDocumentScreen extends StatefulWidget {
  final LoanRequestArgs args;

  const LoanDocumentScreen({super.key, required this.args});

  @override
  State<LoanDocumentScreen> createState() => _LoanDocumentScreenState();
}

class _LoanDocumentScreenState extends State<LoanDocumentScreen> {
  PlatformFile? _idCardFile;
  PlatformFile? _salarySlipFile;
  PlatformFile? _otherFile;

  Future<void> _pickFile(Function(PlatformFile) onFilePicked) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        onFilePicked(result.files.first);
      });
    }
  }

  void _goNext() {
    final updatedArgs = widget.args.copyWith(
      idCardFileName: _idCardFile?.name,
      salarySlipFileName: _salarySlipFile?.name,
      otherFileName: _otherFile?.name,
    );
    context.push('/loan/review', extra: updatedArgs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('แนบเอกสาร'),
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
                _buildStepLine(true),
                _buildStepIndicator(3, 'เอกสาร', true),
                _buildStepLine(false),
                _buildStepIndicator(4, 'ยืนยัน', false),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'กรุณาแนบเอกสารประกอบ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'เอกสารช่วยให้การพิจารณาอนุมัติรวดเร็วขึ้น',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            
            const SizedBox(height: 24),
            
            _buildFilePickerCard(
              icon: Icons.badge,
              label: 'สำเนาบัตรประชาชน',
              description: 'หน้า-หลัง ลงนามสำเนาถูกต้อง',
              file: _idCardFile,
              onPick: () => _pickFile((f) => _idCardFile = f),
              onRemove: () => setState(() => _idCardFile = null),
            ),
            
            const SizedBox(height: 16),
            
            _buildFilePickerCard(
              icon: Icons.receipt_long,
              label: 'สลิปเงินเดือน',
              description: '3 เดือนล่าสุด',
              file: _salarySlipFile,
              onPick: () => _pickFile((f) => _salarySlipFile = f),
              onRemove: () => setState(() => _salarySlipFile = null),
            ),
            
            const SizedBox(height: 16),
            
            _buildFilePickerCard(
              icon: Icons.folder,
              label: 'เอกสารอื่นๆ (ถ้ามี)',
              description: 'เช่น ใบแจ้งหนี้, หนังสือรับรอง',
              file: _otherFile,
              onPick: () => _pickFile((f) => _otherFile = f),
              onRemove: () => setState(() => _otherFile = null),
            ),

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

  Widget _buildFilePickerCard({
    required IconData icon,
    required String label,
    required String description,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? Colors.green : Colors.grey.shade200,
          width: hasFile ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFile ? null : onPick,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasFile ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    hasFile ? Icons.check : icon,
                    color: hasFile ? Colors.green : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFile ? file.name : description,
                        style: TextStyle(
                          color: hasFile ? Colors.green : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasFile)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onRemove,
                  )
                else
                  const Icon(Icons.upload_file, color: AppColors.primary),
              ],
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
