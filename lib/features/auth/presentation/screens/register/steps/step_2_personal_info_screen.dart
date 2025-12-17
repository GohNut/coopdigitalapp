import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  
  DateTime? _selectedBirthDate;
  DateTime? _selectedSpouseBirthDate;
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
    _selectedBirthDate = personal.birthDate;
    _selectedMaritalStatus = personal.maritalStatus;
    _currentAddress = personal.currentAddress;
    
    // Spouse Init
    _spouseNameController = TextEditingController(text: personal.spouseInfo?.fullName ?? '');
    _selectedSpouseBirthDate = personal.spouseInfo?.birthDate;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _spouseNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isSpouse) async {
    final initialDate = isSpouse ? _selectedSpouseBirthDate : _selectedBirthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isSpouse) {
          _selectedSpouseBirthDate = picked;
        } else {
          _selectedBirthDate = picked;
        }
      });
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
              initialValue: account.citizenId, // Should be masked or unmasked? Let's show masked if possible, but raw for now
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

             // Birth Date
            InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันเกิด',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedBirthDate == null
                      ? 'เลือกวันที่'
                      : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                ),
              ),
            ),
            if (_selectedBirthDate == null) // Manual validation handling/display if needed
               const Padding(
                 padding: EdgeInsets.only(top: 8.0, left: 12),
                 child: Text('กรุณาระบุวันเกิด', style: TextStyle(color: Colors.red, fontSize: 12)),
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
                    InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'วันเกิดคู่สมรส',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedSpouseBirthDate == null
                              ? 'เลือกวันที่'
                              : DateFormat('dd/MM/yyyy').format(_selectedSpouseBirthDate!),
                        ),
                      ),
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
      if (_selectedBirthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันเกิด')));
          return;
      }
      
      final notifier = ref.read(registrationProvider.notifier);
      
      final spouseInfo = _selectedMaritalStatus == 'married'
          ? SpouseInfo(
              fullName: _spouseNameController.text,
              birthDate: _selectedSpouseBirthDate,
            )
          : null;

      notifier.updatePersonalInfo(
        PersonalInfo(
          fullName: _fullNameController.text,
          birthDate: _selectedBirthDate,
          maritalStatus: _selectedMaritalStatus!,
          spouseInfo: spouseInfo,
          currentAddress: _currentAddress,
        )
      );
      notifier.nextStep();
    }
  }
}
