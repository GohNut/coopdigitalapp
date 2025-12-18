import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/loan_repository_impl.dart';

class AdditionalDocumentArgs {
  final String applicationId;
  final String officerNote;
  final List<PlatformFile> files;

  AdditionalDocumentArgs({
    required this.applicationId,
    required this.officerNote,
    required this.files,
  });
}

class AdditionalDocumentReviewScreen extends StatefulWidget {
  final AdditionalDocumentArgs args;

  const AdditionalDocumentReviewScreen({super.key, required this.args});

  @override
  State<AdditionalDocumentReviewScreen> createState() => _AdditionalDocumentReviewScreenState();
}

class _AdditionalDocumentReviewScreenState extends State<AdditionalDocumentReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    try {
      final repository = LoanRepositoryImpl();
      final fileNames = widget.args.files.map((f) => f.name).toList();
      
      await repository.submitAdditionalDocuments(
        applicationId: widget.args.applicationId,
        fileNames: fileNames,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งเอกสารเพิ่มเติมเรียบร้อยแล้ว'),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop back to loan detail, then potentially to dashboard
        context.go('/loan');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตรวจสอบเอกสาร'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator (simplified for additional docs)
            Row(
              children: [
                _buildStepIndicator(1, 'เลือกไฟล์', true),
                _buildStepLine(true),
                _buildStepIndicator(2, 'ยืนยัน', true),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Officer Request Note Card
            _buildSectionCard(
              context,
              title: 'คำขอจากเจ้าหน้าที่',
              icon: LucideIcons.messageSquare,
              color: Colors.orange,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.args.officerNote.isNotEmpty 
                        ? widget.args.officerNote 
                        : 'กรุณาแนบเอกสารเพิ่มเติม',
                    style: TextStyle(color: Colors.orange[800], fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Documents List Card
            _buildSectionCard(
              context,
              title: 'เอกสารที่จะส่ง (${widget.args.files.length} ไฟล์)',
              icon: LucideIcons.files,
              color: AppColors.primary,
              children: [
                ...widget.args.files.map((file) => _buildDocumentRow(context, file.name)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Warning/Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'เมื่อยืนยันแล้ว เจ้าหน้าที่จะได้รับเอกสารใหม่และดำเนินการตรวจสอบต่อ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
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
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.success.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'ยืนยันส่งเอกสาร',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String fileName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.fileCheck, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
