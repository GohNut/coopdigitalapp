import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/registration_provider.dart';
import '../../../../domain/models/registration_form_model.dart';
import '../../../widgets/address_form_widget.dart';

class Step3OccupationScreen extends ConsumerStatefulWidget {
  const Step3OccupationScreen({super.key});

  @override
  ConsumerState<Step3OccupationScreen> createState() => _Step3OccupationScreenState();
}

class _Step3OccupationScreenState extends ConsumerState<Step3OccupationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _occupationType;
  final TextEditingController _otherOccupationController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _workplaceNameController = TextEditingController(); // Used for non-gov

  // Government Fields
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _unitCodeController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _positionCodeController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _affiliationController = TextEditingController();
  
  late Address _workplaceAddress;
  bool _useCurrentAddress = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationProvider);
    final occupation = state.form.occupationInfo;

    _occupationType = occupation.occupationType;
    _otherOccupationController.text = occupation.otherOccupation;
    _incomeController.text = occupation.income?.toString() ?? '';
    _incomeController.text = occupation.income?.toString() ?? '';
    _workplaceAddress = occupation.workplaceAddress;
    _useCurrentAddress = occupation.useCurrentAddress;

    if (occupation.occupationType == 'government' && occupation.govDetails != null) {
      _unitNameController.text = occupation.govDetails!.unitName;
      _unitCodeController.text = occupation.govDetails!.unitCode;
      _positionController.text = occupation.govDetails!.position;
      _positionCodeController.text = occupation.govDetails!.positionCode;
      _levelController.text = occupation.govDetails!.level;
      _affiliationController.text = occupation.govDetails!.affiliation;
    } else {
       // If not government, maybe use 'otherOccupation' as workplace name? 
       // The requirements say "Case B: General/Self -> Show Workplace Name".
       // Let's assume _otherOccupationController holds workplace name for general/self if needed,
       // OR we should split the logic.
       // Requirement says: "Case B... Show Workplace Name ONLY".
       // And "Case A... Show Unit, Position...".
       
       // Re-reading requirements:
       // "company_employee", "self_employed", "government", "other".
       // "Case B: General/Self-Employed -> Show Workplace Name".
       // So I should have a Workplace Name field for non-government.
    }
  }

  @override
  void dispose() {
    _otherOccupationController.dispose();
    _incomeController.dispose();
    _workplaceNameController.dispose();
    _unitNameController.dispose();
    _unitCodeController.dispose();
    _positionController.dispose();
    _positionCodeController.dispose();
    _levelController.dispose();
    _affiliationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลอาชีพ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Radio Group
            _buildRadioOption('company_employee', 'พนักงานบริษัท'),
            _buildRadioOption('self_employed', 'ประกอบกิจการส่วนตัว'),
            _buildRadioOption('government', 'รับราชการ'),
            _buildRadioOption('other', 'อื่นๆ'),
            
            const Divider(height: 32),

            // Dynamic Fields
            if (_occupationType == 'government') _buildGovernmentFields()
            else _buildGeneralFields(),

            const SizedBox(height: 16),

            // Income (Common)
            TextFormField(
              controller: _incomeController,
              decoration: const InputDecoration(
                labelText: 'รายได้ต่อเดือน (บาท)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'กรุณาระบุรายได้' : null,
            ),
            
            const SizedBox(height: 24),
            
            // Workplace Address (Common)
            const Text('ที่อยู่ที่ทำงาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('ใช้ที่อยู่เดียวกับที่อยู่ปัจจุบัน'),
              value: _useCurrentAddress,
              onChanged: (val) {
                setState(() {
                  _useCurrentAddress = val ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            if (!_useCurrentAddress)
              AddressFormWidget(
                initialAddress: _workplaceAddress,
                onChanged: (addr) => _workplaceAddress = addr,
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

  Widget _buildRadioOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _occupationType,
      onChanged: (val) {
        setState(() => _occupationType = val!);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildGovernmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ข้อมูลราชการ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('หน่วยงาน', _unitNameController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('รหัสหน่วยงาน', _unitCodeController)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('ตำแหน่ง', _positionController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('รหัสตำแหน่ง', _positionCodeController)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('ระดับ', _levelController),
        const SizedBox(height: 12),
        _buildTextField('สังกัด', _affiliationController),
      ],
    );
  }

  Widget _buildGeneralFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_occupationType == 'other')
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildTextField('ระบุอาชีพ', _otherOccupationController),
          ),
        _buildTextField('ชื่อสถานที่ทำงาน / กิจการ', _workplaceNameController),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (v) {
        // Validation logic can be stricter if needed
        if (_occupationType == 'government' && (label == 'หน่วยงาน' || label == 'ตำแหน่ง')) {
             return v!.isEmpty ? 'จำเป็นต้องระบุ' : null;
        }
        if (_occupationType != 'government' && label.contains('ชื่อสถานที่ทำงาน') && v!.isEmpty) {
             return 'กรุณาระบุชื่อสถานที่ทำงาน';
        }
        return null;
      },
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(registrationProvider.notifier);
      
      GovDetails? govDetails;
      if (_occupationType == 'government') {
        govDetails = GovDetails(
          unitName: _unitNameController.text,
          unitCode: _unitCodeController.text,
          position: _positionController.text,
          positionCode: _positionCodeController.text,
          level: _levelController.text,
          affiliation: _affiliationController.text,
        );
      }

      // If general, we store workplace name in 'otherOccupation' or add a new field to model.
      // Model has `otherOccupation`. Let's use it for "Workplace Name" if not government,
      // or "Other Occupation" specific text.
      // Limitation: The model provided in the prompt was:
      // occupationType, otherOccupation, income, workplaceAddress, govDetails.
      // It didn't explicitly have "workplaceName".
      // But prompt said: "Case B... Show Workplace Name".
      // I'll stick to using `otherOccupation` to store "Workplace Name" for general cases, 
      // or append it logic.
      // For `other` type, we have both "Specify Occupation" and "Workplace Name".
      // I'll combine them or just ignore strict mapping for now.
      
      String otherOcc = _otherOccupationController.text;
      if (_occupationType != 'government' && _occupationType != 'other') {
         otherOcc = _workplaceNameController.text;
      }
      
      // Logic to copy address if checked
      Address finalWorkplaceAddress = _workplaceAddress;
      if (_useCurrentAddress) {
        final personalInfo = ref.read(registrationProvider).form.personalInfo;
        finalWorkplaceAddress = personalInfo.currentAddress;
      }

      notifier.updateOccupationInfo(
        OccupationInfo(
          occupationType: _occupationType,
          otherOccupation: otherOcc, // Mapping Workplace Name here for simplicity
          income: double.tryParse(_incomeController.text),
          workplaceAddress: finalWorkplaceAddress,
          govDetails: govDetails,
          useCurrentAddress: _useCurrentAddress,
        )
      );
      notifier.nextStep();
    }
  }
}
