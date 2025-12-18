import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../../auth/domain/user_role.dart';
// import '../../../auth/domain/models/registration_form_model.dart'; // Add Address
import '../../../../core/constants/address_data.dart';
import '../../../auth/presentation/widgets/address_form_widget.dart';
import '../../../auth/domain/models/registration_form_model.dart'; // For Address model

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _memberData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController; // ReadOnly? Usually editable
  late TextEditingController _spouseNameController;
  late TextEditingController _incomeController;
  late TextEditingController _govUnitController;
  late TextEditingController _govPositionController;

  // State Variables
  DateTime? _birthDate;
  String? _maritalStatus;
  DateTime? _spouseBirthDate;
  String? _occupationType;
  
  // Addresses
  Address _currentAddress = Address();
  Address _workplaceAddress = Address();

  final List<String> _maritalStatuses = ['single', 'married', 'divorced', 'widowed'];
  final Map<String, String> _maritalStatusLabels = {
    'single': 'โสด',
    'married': 'สมรส',
    'divorced': 'หย่าร้าง',
    'widowed': 'หม้าย',
  };

  final List<String> _occupationTypes = ['government', 'company_employee', 'self_employed', 'other'];
  final Map<String, String> _occupationTypeLabels = {
    'government': 'ข้าราชการ',
    'company_employee': 'พนักงานบริษัท',
    'self_employed': 'ธุรกิจส่วนตัว',
    'other': 'อื่นๆ',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _spouseNameController = TextEditingController();
    _incomeController = TextEditingController();
    _govUnitController = TextEditingController();
    _govPositionController = TextEditingController();
    
    _loadMemberData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _spouseNameController.dispose();
    _incomeController.dispose();
    _govUnitController.dispose();
    _govPositionController.dispose();
    super.dispose();
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
          _populateControllers();
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

  void _populateControllers() {
    if (_memberData == null) return;
    
    _nameController.text = _memberData!['name_th'] ?? '';
    _emailController.text = _memberData!['email'] ?? '';
    _mobileController.text = _memberData!['mobile'] ?? '';
    
    // Dates
    if (_memberData!['birth_date'] != null) {
      try {
        _birthDate = DateTime.parse(_memberData!['birth_date']);
      } catch (_) {}
    }
    
    _maritalStatus = _memberData!['marital_status'];
    _spouseNameController.text = _memberData!['spouse_name'] ?? '';
    if (_memberData!['spouse_birth_date'] != null) {
      try {
        _spouseBirthDate = DateTime.parse(_memberData!['spouse_birth_date']);
      } catch (_) {}
    }

    // Address
    _currentAddress = Address(
      details: _memberData!['address_details'] ?? '',
      provinceId: _memberData!['address_province_id'],
      districtId: _memberData!['address_district_id'],
      subDistrictId: _memberData!['address_subdistrict_id'],
      zipCode: _memberData!['address_zipcode'] ?? '',
    );

    // Occupation
    _occupationType = _memberData!['occupation_type'];
    _incomeController.text = _memberData!['income']?.toString() ?? '';
    
    _govUnitController.text = _memberData!['gov_unit_name'] ?? '';
    _govPositionController.text = _memberData!['gov_position'] ?? '';
    
    _workplaceAddress = Address(
      details: _memberData!['workplace_address_details'] ?? '',
      provinceId: _memberData!['workplace_address_province_id'],
      districtId: _memberData!['workplace_address_district_id'],
      subDistrictId: _memberData!['workplace_address_subdistrict_id'],
      zipCode: _memberData!['workplace_address_zipcode'] ?? '',
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final data = <String, dynamic>{
        'name_th': _nameController.text,
        'email': _emailController.text,
        'mobile': _mobileController.text,
        'birth_date': _birthDate?.toIso8601String(),
        'marital_status': _maritalStatus,
      };

      if (_maritalStatus == 'married') {
        data['spouse_name'] = _spouseNameController.text;
        data['spouse_birth_date'] = _spouseBirthDate?.toIso8601String();
      }

      // Address
      data['address_details'] = _currentAddress.details;
      data['address_province_id'] = _currentAddress.provinceId;
      data['address_district_id'] = _currentAddress.districtId;
      data['address_subdistrict_id'] = _currentAddress.subDistrictId;
      data['address_zipcode'] = _currentAddress.zipCode;

      // Occupation
      data['occupation_type'] = _occupationType;
      data['income'] = double.tryParse(_incomeController.text);
      
      if (_occupationType == 'government') {
        data['gov_unit_name'] = _govUnitController.text;
        data['gov_position'] = _govPositionController.text;
      }

      // Workplace Address
      data['workplace_address_details'] = _workplaceAddress.details;
      data['workplace_address_province_id'] = _workplaceAddress.provinceId;
      data['workplace_address_district_id'] = _workplaceAddress.districtId;
      data['workplace_address_subdistrict_id'] = _workplaceAddress.subDistrictId;
      data['workplace_address_zipcode'] = _workplaceAddress.zipCode;

      await DynamicDepositApiService.updateMember(
        memberId: CurrentUser.id,
        data: data,
      );

      // Reload data
      await _loadMemberData();
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(bool isSpouse) async {
     // ... logic reuse
    final initial = isSpouse ? _spouseBirthDate : _birthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isSpouse) {
          _spouseBirthDate = picked;
        } else {
          _birthDate = picked;
        }
      });
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
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error')) // Simplified error
              : _isEditing 
                ? _buildEditForm()
                : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section (Same as before)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  _memberData?['name_th'] ?? CurrentUser.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRole(_memberData?['role']),
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // View Content (Same logic, slightly cleaned up)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 _buildInfoSection('ข้อมูลบัญชี', [
                    _buildInfoTile(LucideIcons.creditCard, 'เลขบัตรประชาชน', _memberData?['memberid']),
                    _buildInfoTile(LucideIcons.mail, 'อีเมล', _memberData?['email']),
                    _buildInfoTile(LucideIcons.phone, 'เบอร์โทรศัพท์', _memberData?['mobile']),
                 ]),
                 const SizedBox(height: 24),
                 _buildInfoSection('ข้อมูลส่วนตัว', [
                    _buildInfoTile(LucideIcons.calendar, 'วันเกิด', _formatDate(_memberData?['birth_date'])),
                    _buildInfoTile(LucideIcons.users, 'สถานะสมรส', _formatMaritalStatus(_memberData?['marital_status'])),
                    if (_memberData?['spouse_name'] != null)
                      _buildInfoTile(LucideIcons.heart, 'ชื่อคู่สมรส', _memberData?['spouse_name']),
                 ]),
                 const SizedBox(height: 24),
                 if (_memberData?['address_details'] != null)
                    _buildInfoSection('ที่อยู่ปัจจุบัน', [
                      _buildInfoTile(LucideIcons.mapPin, 'ที่อยู่', _memberData?['address_details']),
                      _buildInfoTile(LucideIcons.map, 'จังหวัด', AddressData.getProvinceName(_memberData?['address_province_id'])),
                      _buildInfoTile(LucideIcons.map, 'อำเภอ/เขต', AddressData.getDistrictName(_memberData?['address_province_id'], _memberData?['address_district_id'])),
                      _buildInfoTile(LucideIcons.map, 'ตำบล/แขวง', AddressData.getSubDistrictName(_memberData?['address_district_id'], _memberData?['address_subdistrict_id'])),
                      _buildInfoTile(LucideIcons.map, 'รหัสไปรษณีย์', _memberData?['address_zipcode']),
                    ]),
                 const SizedBox(height: 24),
                  _buildInfoSection('ข้อมูลอาชีพ', [
                    _buildInfoTile(LucideIcons.briefcase, 'อาชีพ', _formatOccupationType(_memberData?['occupation_type'])),
                    _buildInfoTile(LucideIcons.banknote, 'รายได้', _formatIncome(_memberData?['income'])),
                    if (_memberData?['gov_unit_name'] != null)
                      _buildInfoTile(LucideIcons.building, 'หน่วยงาน', _memberData?['gov_unit_name']),
                    if (_memberData?['gov_position'] != null)
                      _buildInfoTile(LucideIcons.briefcase, 'ตำแหน่ง', _memberData?['gov_position']),
                    // Workplace Address
                    if (_memberData?['workplace_address_details'] != null) ...[
                        const Divider(),
                        const Padding(padding: EdgeInsets.all(8), child: Text('ที่อยู่ที่ทำงาน', style: TextStyle(fontWeight: FontWeight.bold))),
                        _buildInfoTile(LucideIcons.mapPin, 'ที่ตั้ง', _memberData?['workplace_address_details']),
                        _buildInfoTile(LucideIcons.map, 'จังหวัด', AddressData.getProvinceName(_memberData?['workplace_address_province_id'])),
                        _buildInfoTile(LucideIcons.map, 'อำเภอ/เขต', AddressData.getDistrictName(_memberData?['workplace_address_province_id'], _memberData?['workplace_address_district_id'])),
                        _buildInfoTile(LucideIcons.map, 'ตำบล/แขวง', AddressData.getSubDistrictName(_memberData?['workplace_address_district_id'], _memberData?['workplace_address_subdistrict_id'])),
                        _buildInfoTile(LucideIcons.map, 'รหัสไปรษณีย์', _memberData?['workplace_address_zipcode']),
                    ]
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSaving) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            
            // Account Info (ReadOnly ID)
            _sectionHeader('ข้อมูลบัญชี'),
            TextFormField(
              initialValue: _memberData?['memberid'],
              decoration: const InputDecoration(labelText: 'เลขบัตรประชาชน', filled: true),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ' : null,
            ),
             const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder()),
            ),
             const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'เบอร์มือถือ', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'กรุณาระบุเบอร์มือถือ' : null,
            ),
             const SizedBox(height: 24),

             _sectionHeader('ข้อมูลส่วนตัว'),
             InkWell(
               onTap: () => _pickDate(false),
               child: InputDecorator(
                 decoration: const InputDecoration(labelText: 'วันเกิด', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                 child: Text(_birthDate == null ? '-' : DateFormat('dd/MM/yyyy').format(_birthDate!)),
               ),
             ),
             const SizedBox(height: 16),
             DropdownButtonFormField<String>(
               value: _maritalStatus,
               decoration: const InputDecoration(labelText: 'สถานะสมรส', border: OutlineInputBorder()),
               items: _maritalStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_maritalStatusLabels[s]!))).toList(),
               onChanged: (val) => setState(() => _maritalStatus = val),
             ),
             if (_maritalStatus == 'married') ...[
               const SizedBox(height: 16),
               TextFormField(
                 controller: _spouseNameController,
                 decoration: const InputDecoration(labelText: 'ชื่อคู่สมรส', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               InkWell(
                 onTap: () => _pickDate(true),
                 child: InputDecorator(
                   decoration: const InputDecoration(labelText: 'วันเกิดคู่สมรส', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                   child: Text(_spouseBirthDate == null ? '-' : DateFormat('dd/MM/yyyy').format(_spouseBirthDate!)),
                 ),
               ),
             ],
             const SizedBox(height: 24),

             _sectionHeader('ที่อยู่ปัจจุบัน'),
             AddressFormWidget(
               initialAddress: _currentAddress,
               onChanged: (addr) => _currentAddress = addr,
             ),
             const SizedBox(height: 24),

             _sectionHeader('ข้อมูลอาชีพ'),
             DropdownButtonFormField<String>(
               value: _occupationType,
               decoration: const InputDecoration(labelText: 'อาชีพ', border: OutlineInputBorder()),
               items: _occupationTypes.map((s) => DropdownMenuItem(value: s, child: Text(_occupationTypeLabels[s]!))).toList(),
               onChanged: (val) => setState(() => _occupationType = val),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: _incomeController,
               decoration: const InputDecoration(labelText: 'รายได้ต่อเดือน', border: OutlineInputBorder()),
               keyboardType: TextInputType.number,
             ),
             if (_occupationType == 'government') ...[
               const SizedBox(height: 16),
               TextFormField(
                 controller: _govUnitController,
                 decoration: const InputDecoration(labelText: 'หน่วยงาน', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _govPositionController,
                 decoration: const InputDecoration(labelText: 'ตำแหน่ง', border: OutlineInputBorder()),
               ),
             ],
             const SizedBox(height: 24),
             _sectionHeader('ที่อยู่ที่ทำงาน'),
             AddressFormWidget(
               initialAddress: _workplaceAddress,
               onChanged: (addr) => _workplaceAddress = addr,
             ),
             const SizedBox(height: 40),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _isSaving ? null : _saveProfile,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18, color: Colors.white)),
               ),
             ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
  
  // Helpers (Reuse existing helpers or keep them)
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      subtitle: Text(value ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
    return _maritalStatusLabels[status] ?? status;
  }

  String _formatOccupationType(String? type) {
    if (type == null) return '-';
    return _occupationTypeLabels[type] ?? type;
  }

  String _formatRole(String? role) {
    if (role == null) return 'สมาชิกสหกรณ์';
    switch (role) {
      case 'officer':
        return 'เจ้าหน้าที่สหกรณ์';
      case 'member':
        return 'สมาชิกสหกรณ์';
      default:
        return 'สมาชิกสหกรณ์';
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
