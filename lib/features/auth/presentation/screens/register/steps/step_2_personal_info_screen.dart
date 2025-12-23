import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../providers/registration_provider.dart';
import '../../../../domain/models/registration_form_model.dart';
import '../../../widgets/address_form_widget.dart';

class Step2PersonalInfoScreen extends ConsumerStatefulWidget {
  const Step2PersonalInfoScreen({super.key});

  @override
  ConsumerState<Step2PersonalInfoScreen> createState() => _Step2PersonalInfoScreenState();
}

class _Step2PersonalInfoScreenState extends ConsumerState<Step2PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _spouseNameController;
  
  // Date Input Controllers
  late TextEditingController _birthDateController;
  late TextEditingController _spouseBirthDateController;

  final _dateMaskFormatter = MaskTextInputFormatter(
    mask: '##/##/####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );
  final _spouseDateMaskFormatter = MaskTextInputFormatter(
    mask: '##/##/####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );

  String? _selectedMaritalStatus;
  late Address _currentAddress;

  final List<String> _maritalStatuses = ['single', 'married', 'divorced'];
  final Map<String, String> _maritalStatusLabels = {
    'single': 'โสด',
    'married': 'สมรส',
    'divorced': 'หย่าร้าง',
  };

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationProvider);
    final personal = state.form.personalInfo;

    _fullNameController = TextEditingController(text: personal.fullName);
    _birthDateController = TextEditingController(
      text: personal.birthDate != null ? _formatDateToTh(personal.birthDate!) : ''
    );
    _spouseBirthDateController = TextEditingController(
      text: personal.spouseInfo?.birthDate != null ? _formatDateToTh(personal.spouseInfo!.birthDate!) : ''
    );

    _selectedMaritalStatus = personal.maritalStatus;
    _currentAddress = personal.currentAddress;
    
    // Spouse Init
    _spouseNameController = TextEditingController(text: personal.spouseInfo?.fullName ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _spouseNameController.dispose();
    _birthDateController.dispose();
    _spouseBirthDateController.dispose();
    super.dispose();
  }

  String _formatDateToTh(DateTime date) {
    // Convert DateTime to DD/MM/YYYY (BE) string
    final yearTh = date.year + 543;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/$yearTh';
  }

  DateTime? _parseDateTh(String input) {
    // Input format: DD/MM/YYYY (BE)
    try {
      final parts = input.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final yearBe = int.parse(parts[2]);
      final yearAd = yearBe - 543;

      // Basic validation
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      // Create date and check if it matches input (handles invalid days like 31 Feb)
      final date = DateTime(yearAd, month, day);
      if (date.day != day || date.month != month || date.year != yearAd) {
        return null;
      }
      
      return date;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    final account = state.form.accountInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Read-Only Fields from Step 1
            TextFormField(
              initialValue: account.citizenId,
              decoration: const InputDecoration(
                labelText: 'เลขบัตรประชาชน',
                filled: true,
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              enabled: false,
            ),
             const SizedBox(height: 16),
             TextFormField(
              initialValue: account.mobile,
              decoration: const InputDecoration(
                labelText: 'เบอร์มือถือ',
                filled: true,
                border: OutlineInputBorder(),
              ),
              readOnly: true,
               enabled: false,
            ),
            const Divider(height: 32),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ-นามสกุล' : null,
            ),
             const SizedBox(height: 16),

             // Birth Date Text Field
            TextFormField(
              controller: _birthDateController,
              inputFormatters: [_dateMaskFormatter],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'วันเกิด (วว/ดด/ปปปป)',
                hintText: 'เช่น 23/12/2530',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณาระบุวันเกิด';
                if (v.length != 10) return 'รูปแบบวันที่ไม่ถูกต้อง (วว/ดด/ปปปป)';
                if (_parseDateTh(v) == null) return 'วันที่ไม่ถูกต้อง';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Marital Status
            DropdownButtonFormField<String>(
              value: _selectedMaritalStatus,
              decoration: const InputDecoration(
                labelText: 'สถานะภาพสมรส',
                border: OutlineInputBorder(),
              ),
              items: _maritalStatuses.map((s) => DropdownMenuItem(
                value: s,
                child: Text(_maritalStatusLabels[s]!),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedMaritalStatus = val!);
              },
            ),
            const SizedBox(height: 16),

            // Spouse Info (Conditional)
            if (_selectedMaritalStatus == 'married') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ข้อมูลคู่สมรส', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _spouseNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ-นามสกุล คู่สมรส',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _selectedMaritalStatus == 'married' && v!.isEmpty ? 'ระบุชื่อคู่สมรส' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _spouseBirthDateController,
                      inputFormatters: [_spouseDateMaskFormatter],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'วันเกิดคู่สมรส (วว/ดด/ปปปป)',
                        hintText: 'เช่น 23/12/2530',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (v) {
                         if (_selectedMaritalStatus == 'married') {
                           if (v == null || v.isEmpty) return 'ระบุวันเกิดคู่สมรส';
                           if (v.length != 10) return 'รูปแบบวันที่ไม่ถูกต้อง';
                           if (_parseDateTh(v) == null) return 'วันที่ไม่ถูกต้อง';
                         }
                         return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Address
            const Text('ที่อยู่ปัจจุบัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AddressFormWidget(
              initialAddress: _currentAddress,
              onChanged: (addr) {
                _currentAddress = addr;
              },
            ),

            const SizedBox(height: 32),
            
            // Buttons
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: ref.read(registrationProvider.notifier).prevStep,
                     child: const Text('ย้อนกลับ'),
                    ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: _onNext,
                     child: const Text('ถัดไป'),
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final parsedBirthDate = _parseDateTh(_birthDateController.text);
      if (parsedBirthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('วันเกิดไม่ถูกต้อง')));
          return;
      }
      
      final notifier = ref.read(registrationProvider.notifier);
      
      SpouseInfo? spouseInfo;

      if (_selectedMaritalStatus == 'married') {
         final parsedSpouseDate = _parseDateTh(_spouseBirthDateController.text);
         if (parsedSpouseDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('วันเกิดคู่สมรสไม่ถูกต้อง')));
            return;
         }

          spouseInfo = SpouseInfo(
              fullName: _spouseNameController.text,
              birthDate: parsedSpouseDate,
            );
      } else {
        spouseInfo = null;
      }

      notifier.updatePersonalInfo(
        PersonalInfo(
          fullName: _fullNameController.text,
          birthDate: parsedBirthDate,
          maritalStatus: _selectedMaritalStatus!,
          spouseInfo: spouseInfo,
          currentAddress: _currentAddress,
        )
      );
      notifier.nextStep();
    }
  }
}
