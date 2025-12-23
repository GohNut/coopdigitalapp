
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/kyc_service.dart';

class OfficerKYCDetailScreen extends StatefulWidget {
  final String memberId;

  const OfficerKYCDetailScreen({super.key, required this.memberId});

  @override
  State<OfficerKYCDetailScreen> createState() => _OfficerKYCDetailScreenState();
}

class _OfficerKYCDetailScreenState extends State<OfficerKYCDetailScreen> {
  late Future<Map<String, dynamic>> _kycDetailFuture;
  bool _isSubmitting = false;
  bool _promoteToOfficer = false;

  @override
  void initState() {
    super.initState();
    _kycDetailFuture = KYCService.getKYCDetail(widget.memberId);
  }

  Future<void> _submitReview(String status, [String? reason]) async {
    setState(() => _isSubmitting = true);
    try {
      await KYCService.reviewKYC(
        memberId: widget.memberId,
        status: status,
        reason: reason,
        isOfficer: status == 'verified' && _promoteToOfficer,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกผลการตรวจสอบ: $status เรียบร้อยแล้ว')),
        );
        context.pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ระบุเหตุผลที่ไม่อนุมัติ'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'เช่น รูปบัตรไม่ชัดเจน, ชื่อไม่ตรงกับบัญชี',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              context.pop();
              _submitReview('rejected', reasonController.text);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ยืนยันไม่อนุมัติ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลการตรวจสอบโดยละเอียด'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _kycDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final member = data['member'] as Map<String, dynamic>;
          final images = data['images'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('ข้อมูลสมาชิก'),
                _buildInfoRow('ID', member['memberid']),
                _buildInfoRow('ชื่อ-นามสกุล', member['name_th']),
                _buildInfoRow('ธนาคาร', member['bank_id'] ?? '-'),
                _buildInfoRow('เลขบัญชี', member['bank_account_no'] ?? '-'),
                const SizedBox(height: 24),
                
                _buildSectionHeader('หลักฐานรูปภาพ'),
                if (images['kyc_id_card_image_key'] != null)
                  _buildImagePreview('บัตรประชาชน', images['kyc_id_card_image_key']),
                if (images['kyc_bank_book_image_key'] != null)
                  _buildImagePreview('สมุดบัญชี', images['kyc_bank_book_image_key']),
                if (images['kyc_selfie_image_key'] != null)
                  _buildImagePreview('ภาพถ่ายคู่บัตร (Selfie)', images['kyc_selfie_image_key']),
                  
                const SizedBox(height: 32),
                
                // Promote to Officer Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'แต่งตั้งเป็นเจ้าหน้าที่ (Officer)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    subtitle: const Text('เมื่ออนุมัติ สมาชิกจะได้รับสิทธิ์เป็นเจ้าหน้าที่ทันที'),
                    value: _promoteToOfficer,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _promoteToOfficer = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                const SizedBox(height: 24),
                if (_isSubmitting)
                   const Center(child: CircularProgressIndicator())
                else
                   Row(
                     children: [
                       Expanded(
                         child: OutlinedButton.icon(
                           onPressed: _showRejectDialog,
                           icon: const Icon(LucideIcons.x),
                           label: const Text('ไม่อนุมัติ'),
                           style: OutlinedButton.styleFrom(
                             foregroundColor: Colors.red,
                             side: const BorderSide(color: Colors.red),
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: FilledButton.icon(
                           onPressed: () => _submitReview('verified'),
                           icon: const Icon(LucideIcons.check),
                           label: const Text('อนุมัติ'),
                           style: FilledButton.styleFrom(
                             backgroundColor: Colors.green,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                         ),
                       ),
                     ],
                   )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String? url) {
    if (url == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => 
                  const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
