import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_application_model.dart';
import '../../data/loan_repository_impl.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../notification/domain/notification_model.dart';
import '../../../auth/domain/user_role.dart';

class OfficerLoanDetailScreen extends ConsumerStatefulWidget {
  final LoanApplication application;

  const OfficerLoanDetailScreen({
    super.key,
    required this.application,
  });

  @override
  ConsumerState<OfficerLoanDetailScreen> createState() => _OfficerLoanDetailScreenState();
}

class _OfficerLoanDetailScreenState extends ConsumerState<OfficerLoanDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late LoanApplicationStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.application.status;
    _commentFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(LoanApplicationStatus newStatus) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = LoanRepositoryImpl();
      await repository.updateLoanStatus(
        widget.application.id, 
        newStatus, 
        comment: _commentController.text.isNotEmpty ? _commentController.text : null
      );

      if (mounted) {
        // Dismiss loading
        Navigator.of(context, rootNavigator: true).pop(); 
        
        setState(() {
          _currentStatus = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == LoanApplicationStatus.approved 
                  ? 'อนุมัติสินเชื่อเรียบร้อยแล้ว' 
                  : (newStatus == LoanApplicationStatus.waitingForDocs 
                      ? 'ส่งคำขอเอกสารเพิ่มเติมแล้ว' 
                      : 'ปฏิเสธสินเชื่อเรียบร้อยแล้ว')
            ),
            backgroundColor: newStatus == LoanApplicationStatus.approved 
                ? AppColors.success 
                : (newStatus == LoanApplicationStatus.waitingForDocs 
                    ? Colors.orange 
                    : AppColors.error),
          ),
        );
        
        // Delay slightly before going back
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        // Dismiss loading
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!CurrentUser.isOfficerOrApprover) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('รายละเอียดคำขอสินเชื่อ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),
            _buildApplicantInfo(),
            const SizedBox(height: 20),
            _buildFinancialInfo(currencyFormat),
            const SizedBox(height: 20),
            _buildDepositAccountInfo(),
            const SizedBox(height: 20),
            _buildGuarantorInfo(),
            const SizedBox(height: 20),
            _buildDocumentsInfo(),
            const SizedBox(height: 20),
            if (widget.application.additionalDocuments.isNotEmpty) ...[
              _buildAdditionalDocumentsInfo(),
              const SizedBox(height: 20),
            ],
            if (_currentStatus == LoanApplicationStatus.pending && CurrentUser.isOfficerOrApprover)
               _buildActionSection(),
            if (_currentStatus != LoanApplicationStatus.pending)
               _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_currentStatus) {
      case LoanApplicationStatus.approved:
        statusColor = AppColors.success;
        statusText = 'อนุมัติแล้ว';
        statusIcon = LucideIcons.checkCircle;
        break;
      case LoanApplicationStatus.rejected:
        statusColor = AppColors.error;
        statusText = 'ปฏิเสธแล้ว';
        statusIcon = LucideIcons.xCircle;
        break;
      case LoanApplicationStatus.waitingForDocs:
        statusColor = Colors.orange;
        statusText = 'รอเอกสารเพิ่มเติม';
        statusIcon = LucideIcons.fileQuestion;
        break;
      default:
        // Check if re-submitted
        if (widget.application.additionalDocuments.isNotEmpty) {
           statusColor = Colors.purple;
           statusText = 'รอตรวจสอบเอกสารเพิ่ม';
           statusIcon = LucideIcons.fileSearch;
        } else {
           statusColor = AppColors.warning;
           statusText = 'รอการพิจารณา';
           statusIcon = LucideIcons.clock;
        }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'เลขอ้างอิง: ${widget.application.id}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantInfo() {
    return _buildCard(
      title: 'ข้อมูลสมาชิก',
      icon: LucideIcons.user,
      children: [
        _buildInfoRow('ชื่อ-นามสกุล', widget.application.applicantName),
        _buildInfoRow('รหัสสมาชิก', widget.application.memberId),
        _buildInfoRow('เลขบัตรประชาชน', widget.application.applicantId),
      ],
    );
  }

  Widget _buildFinancialInfo(NumberFormat format) {
    return _buildCard(
      title: 'ข้อมูลสินเชื่อและการเงิน',
      icon: LucideIcons.banknote,
      children: [
        _buildInfoRow('ประเภทสินเชื่อ', widget.application.productName),
        _buildInfoRow('วงเงินที่ขอ', format.format(widget.application.amount), isHighlight: true),
        _buildInfoRow('ระยะเวลาผ่อน', '${widget.application.requestTerm} งวด'),
        const Divider(),
        _buildInfoRow('เงินเดือน', format.format(widget.application.monthlySalary)),
        _buildInfoRow('หนี้สินปัจจุบัน', format.format(widget.application.currentDebt)),
        _buildInfoRow('ภาระหนี้ต่อรายได้', '${widget.application.monthlySalary > 0 ? ((widget.application.currentDebt / widget.application.monthlySalary) * 100).toStringAsFixed(1) : "0.0"}%'),
      ],
    );
  }

  Widget _buildDepositAccountInfo() {
    return _buildCard(
      title: 'บัญชีรับเงินกู้',
      icon: LucideIcons.wallet,
      children: [
        if (widget.application.depositAccountId != null && 
            widget.application.depositAccountId!.isNotEmpty) ...[
          _buildInfoRow('ชื่อบัญชี', widget.application.depositAccountName ?? '-'),
          _buildInfoRow('เลขที่บัญชี', widget.application.depositAccountNumber ?? '-'),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ไม่ได้ระบุบัญชีรับเงินกู้',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuarantorInfo() {
    final guarantors = widget.application.security.guarantors;
    
    return _buildCard(
      title: 'ผู้ค้ำประกัน',
      icon: LucideIcons.userCheck,
      children: [
        if (guarantors.isNotEmpty) ...[
          ...guarantors.map((g) => Column(
            children: [
              _buildInfoRow('ชื่อผู้ค้ำประกัน', g.name.isNotEmpty ? g.name : '-'),
              _buildInfoRow('รหัสสมาชิก', g.memberId.isNotEmpty ? g.memberId : '-'),
              _buildInfoRow('ความสัมพันธ์', g.relationship.isNotEmpty ? g.relationship : '-'),
              if (guarantors.indexOf(g) < guarantors.length - 1) const Divider(),
            ],
          )),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ไม่มีข้อมูลผู้ค้ำประกัน',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsInfo() {
    final documents = widget.application.documents;
    
    return _buildCard(
      title: 'เอกสารประกอบ (เดิม)',
      icon: LucideIcons.fileText,
      children: [
        if (documents.isNotEmpty) ...[
          ...documents.map((doc) => _buildDocumentRow(doc)),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ไม่มีเอกสารแนบ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalDocumentsInfo() {
    final documents = widget.application.additionalDocuments;
    
    return _buildCard(
      title: 'เอกสารเพิ่มเติม (ใหม่)',
      icon: LucideIcons.files,
      children: [
        ...documents.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.filePlus, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'ส่งเมื่อ: ${widget.application.additionalDocRequestDate != null ? DateFormat('dd/MM/yy HH:mm').format(new DateTime.now()) : "-"}', // Mock time
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ใหม่',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _getDocumentTypeDisplay(String type) {
    switch (type) {
      case 'id_card':
        return 'สำเนาบัตรประชาชน';
      case 'salary_slip':
        return 'สลิปเงินเดือน';
      case 'other':
        return 'เอกสารอื่นๆ';
      default:
        return type;
    }
  }

  Widget _buildDocumentRow(LoanDocument doc) {
    IconData icon;
    switch (doc.type) {
      case 'id_card':
        icon = LucideIcons.creditCard;
        break;
      case 'salary_slip':
        icon = LucideIcons.receipt;
        break;
      default:
        icon = LucideIcons.file;
    }
    
    final isVerified = doc.status == 'verified' || doc.status == 'approved';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _getDocumentTypeDisplay(doc.type),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isVerified ? 'ตรวจสอบแล้ว' : 'รอตรวจสอบ',
              style: TextStyle(
                fontSize: 11,
                color: isVerified ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การพิจารณา',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          focusNode: _commentFocusNode,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: _commentFocusNode.hasFocus ? null : 'ความเห็นเจ้าหน้าที่ (ถ้ามี)',
            border: const OutlineInputBorder(),
            hintText: _commentFocusNode.hasFocus ? null : 'ระบุเหตุผล หรือเงื่อนไขเพิ่มเติม...',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestDocsDialog(),
                  icon: const Icon(LucideIcons.fileQuestion, size: 20),
                  label: const Text(
                    'ขอเอกสารเพิ่ม',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmationDialog(LoanApplicationStatus.rejected),
                  icon: const Icon(LucideIcons.x, size: 24),
                  label: const Text(
                    'ปฏิเสธ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmationDialog(LoanApplicationStatus.approved),
                  icon: const Icon(LucideIcons.check, size: 24),
                  label: const Text(
                    'อนุมัติ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        // เพิ่ม padding ด้านล่างเพื่อไม่ให้ปุ่มติด bar
        const SizedBox(height: 32),
      ],
    );
  }

  void _showRequestDocsDialog() {
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ขอเอกสารเพิ่มเติม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ระบุเอกสารหรือข้อมูลที่ต้องการเพิ่มเติม:'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'เช่น ขอสำเนาบัตรประชาชนใหม่ เนื่องจากภาพไม่ชัด',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุรายละเอียด')),
                );
                return;
              }
              Navigator.pop(context);
              
              // Update status with note
              _commentController.text = noteController.text; 
              await _updateStatus(LoanApplicationStatus.waitingForDocs);

              // Create Notification using Provider
              ref.read(notificationProvider.notifier).addNotification(
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'ขอเอกสารเพิ่มเติม',
                  message: 'เจ้าหน้าที่ต้องการเอกสารเพิ่มเติมสำหรับคำขอสินเชื่อ #${widget.application.id}: ${noteController.text}',
                  timestamp: DateTime.now(),
                  type: NotificationType.warning,
                  route: '/loan/contract/${widget.application.id}',
                  isRead: false,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  
  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ความเห็นเจ้าหน้าที่',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _commentController.text.isEmpty ? '-' : _commentController.text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showConfirmationDialog(LoanApplicationStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == LoanApplicationStatus.approved ? 'ยืนยันการอนุมัติ?' : 'ยืนยันการปฏิเสธ?'),
        content: Text(
          status == LoanApplicationStatus.approved 
              ? 'คุณต้องการอนุมัติวงเงินสินเชื่อนี้ใช่หรือไม่?'
              : 'คุณต้องการปฏิเสธคำขอนี้ใช่หรือไม่?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(status);
            },
            style: FilledButton.styleFrom(
              backgroundColor: status == LoanApplicationStatus.approved ? AppColors.success : AppColors.error,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }
}
