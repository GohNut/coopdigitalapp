import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../../auth/domain/user_role.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _memberData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final memberData = await DynamicDepositApiService.getMember(CurrentUser.id);
      
      if (mounted) {
        setState(() {
          _memberData = memberData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลสมาชิก'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('เกิดข้อผิดพลาด: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMemberData,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Icon(LucideIcons.user, color: AppColors.primary, size: 48),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _memberData?['name_th'] ?? CurrentUser.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'สมาชิกสหกรณ์',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile Information
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoSection(
                              'ข้อมูลบัญชี',
                              [
                                _buildInfoTile(LucideIcons.creditCard, 'เลขบัตรประชาชน', _memberData?['memberid'] ?? CurrentUser.id),
                                _buildInfoTile(LucideIcons.mail, 'อีเมล', _memberData?['email'] ?? '-'),
                                _buildInfoTile(LucideIcons.phone, 'เบอร์โทรศัพท์', _memberData?['mobile'] ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              'ข้อมูลส่วนตัว',
                              [
                                _buildInfoTile(LucideIcons.calendar, 'วันเกิด', _formatDate(_memberData?['birth_date'])),
                                _buildInfoTile(LucideIcons.users, 'สถานะสมรส', _formatMaritalStatus(_memberData?['marital_status'])),
                                if (_memberData?['spouse_name'] != null)
                                  _buildInfoTile(LucideIcons.heart, 'ชื่อคู่สมรส', _memberData?['spouse_name']),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_memberData?['address_details'] != null)
                              _buildInfoSection(
                                'ที่อยู่ปัจจุบัน',
                                [
                                  _buildInfoTile(LucideIcons.mapPin, 'ที่อยู่', _memberData?['address_details']),
                                  _buildInfoTile(LucideIcons.map, 'รหัสไปรษณีย์', _memberData?['address_zipcode']),
                                ],
                              ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              'ข้อมูลอาชีพ',
                              [
                                _buildInfoTile(LucideIcons.briefcase, 'อาชีพ', _formatOccupationType(_memberData?['occupation_type'])),
                                _buildInfoTile(LucideIcons.banknote, 'รายได้', _formatIncome(_memberData?['income'])),
                                if (_memberData?['gov_unit_name'] != null)
                                  _buildInfoTile(LucideIcons.building, 'หน่วยงาน', _memberData?['gov_unit_name']),
                                if (_memberData?['gov_position'] != null)
                                  _buildInfoTile(LucideIcons.briefcase, 'ตำแหน่ง', _memberData?['gov_position']),
                                if (_memberData?['workplace_address_details'] != null)
                                  _buildInfoTile(LucideIcons.mapPin, 'ที่อยู่ที่ทำงาน', _memberData?['workplace_address_details']),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              'ข้อมูลระบบ',
                              [
                                _buildInfoTile(LucideIcons.calendar, 'วันที่สมัคร', _formatDate(_memberData?['created_at'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value ?? '-',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year + 543}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMaritalStatus(String? status) {
    if (status == null) return '-';
    switch (status) {
      case 'single':
        return 'โสด';
      case 'married':
        return 'สมรส';
      case 'divorced':
        return 'หย่าร้าง';
      case 'widowed':
        return 'หม้าย';
      default:
        return status;
    }
  }

  String _formatOccupationType(String? type) {
    if (type == null) return '-';
    switch (type) {
      case 'government':
        return 'ข้าราชการ';
      case 'company_employee':
        return 'พนักงานบริษัท';
      case 'self_employed':
        return 'ธุรกิจส่วนตัว';
      case 'other':
        return 'อื่นๆ';
      default:
        return type;
    }
  }

  String _formatIncome(dynamic income) {
    if (income == null) return '-';
    try {
      final amount = double.parse(income.toString());
      return '${amount.toStringAsFixed(0)} บาท';
    } catch (e) {
      return income.toString();
    }
  }
}
