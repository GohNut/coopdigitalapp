import 'package:flutter/material.dart';
import '../../domain/models/registration_form_model.dart'; // Import Address model

class AddressFormWidget extends StatefulWidget {
  final Address initialAddress;
  final ValueChanged<Address> onChanged;

  const AddressFormWidget({
    super.key,
    required this.initialAddress,
    required this.onChanged,
  });

  @override
  State<AddressFormWidget> createState() => _AddressFormWidgetState();
}

class _AddressFormWidgetState extends State<AddressFormWidget> {
  late TextEditingController _detailsController;
  late TextEditingController _extraController;
  late TextEditingController _zipCodeController;
  
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  int? _selectedSubDistrictId;

  // Mock Data
  final List<Map<String, dynamic>> _provinces = [
    {'id': 1, 'name': 'กรุงเทพมหานคร'},
    {'id': 2, 'name': 'เชียงใหม่'},
    {'id': 3, 'name': 'ขอนแก่น'},
    {'id': 4, 'name': 'ภูเก็ต'},
  ];

  final Map<int, List<Map<String, dynamic>>> _districts = {
    1: [
      {'id': 101, 'name': 'เขตพระนคร'},
      {'id': 102, 'name': 'เขตดุสิต'},
      {'id': 103, 'name': 'เขตบางรัก'},
    ],
    2: [
      {'id': 201, 'name': 'เมืองเชียงใหม่'},
      {'id': 202, 'name': 'แม่ริม'},
    ],
    // Add more as needed
  };

  final Map<int, List<Map<String, dynamic>>> _subDistricts = {
    101: [{'id': 1001, 'name': 'พระบรมมหาราชวัง', 'zip': '10200'}, {'id': 1002, 'name': 'วังบูรพาภิรมย์', 'zip': '10200'}],
    102: [{'id': 1003, 'name': 'ดุสิต', 'zip': '10300'}],
    201: [{'id': 2001, 'name': 'ศรีภูมิ', 'zip': '50200'}],
  };

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController(text: widget.initialAddress.details);
    _extraController = TextEditingController(text: widget.initialAddress.extra);
    _zipCodeController = TextEditingController(text: widget.initialAddress.zipCode);
    
    _selectedProvinceId = widget.initialAddress.provinceId;
    _selectedDistrictId = widget.initialAddress.districtId;
    _selectedSubDistrictId = widget.initialAddress.subDistrictId;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _extraController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(Address(
      details: _detailsController.text,
      extra: _extraController.text,
      provinceId: _selectedProvinceId,
      districtId: _selectedDistrictId,
      subDistrictId: _selectedSubDistrictId,
      zipCode: _zipCodeController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _detailsController,
          decoration: const InputDecoration(
            labelText: 'ที่อยู่ (เลขที่, หมู่, ซอย, ถนน)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _notifyChanged(),
          validator: (val) => val == null || val.isEmpty ? 'กรุณากรอกที่อยู่' : null,
        ),
        const SizedBox(height: 16),
        
        // Province Dropdown
        DropdownButtonFormField<int>(
          value: _selectedProvinceId,
          decoration: const InputDecoration(
            labelText: 'จังหวัด',
            border: OutlineInputBorder(),
          ),
          items: _provinces.map((p) => DropdownMenuItem<int>(
            value: p['id'] as int,
            child: Text(p['name'] as String),
          )).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvinceId = val;
              _selectedDistrictId = null;
              _selectedSubDistrictId = null;
              _zipCodeController.clear();
            });
            _notifyChanged();
          },
          validator: (val) => val == null ? 'กรุณาเลือกจังหวัด' : null,
        ),
        const SizedBox(height: 16),

        // District Dropdown (Enabled only if Country selected - Logic implied)
        DropdownButtonFormField<int>(
          key: const ValueKey('district_dropdown'), // Unique key for district dropdown
          value: _selectedDistrictId,
          decoration: const InputDecoration(
            labelText: 'อำเภอ/เขต',
            border: OutlineInputBorder(),
          ),
          items: (_selectedProvinceId != null && _districts.containsKey(_selectedProvinceId))
              ? _districts[_selectedProvinceId]!.map((d) => DropdownMenuItem<int>(
                  value: d['id'] as int,
                  child: Text(d['name'] as String),
                )).toList()
              : [],
          onChanged: _selectedProvinceId == null ? null : (val) {
            setState(() {
              _selectedDistrictId = val;
              _selectedSubDistrictId = null;
              _zipCodeController.clear();
            });
            _notifyChanged();
          },
          validator: (val) {
            // Only validate if province is selected (user has started filling the form)
            if (_selectedProvinceId != null && val == null) {
              return 'กรุณาเลือกอำเภอ/เขต';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // SubDistrict Dropdown
         DropdownButtonFormField<int>(
           key: const ValueKey('subdistrict_dropdown'),
          value: _selectedSubDistrictId,
          decoration: const InputDecoration(
            labelText: 'ตำบล/แขวง',
            border: OutlineInputBorder(),
          ),
          items: (_selectedDistrictId != null && _subDistricts.containsKey(_selectedDistrictId))
              ? _subDistricts[_selectedDistrictId]!.map((d) => DropdownMenuItem<int>(
                  value: d['id'] as int,
                  child: Text(d['name'] as String),
                )).toList()
              : [],
          onChanged: _selectedDistrictId == null ? null : (val) {
             // Auto-fill zip code
             final subDistrict = _subDistricts[_selectedDistrictId]!.firstWhere((d) => d['id'] == val);
             setState(() {
              _selectedSubDistrictId = val;
              _zipCodeController.text = subDistrict['zip'] as String;
            });
            _notifyChanged();
          },
          validator: (val) {
            // Only validate if district is selected
            if (_selectedDistrictId != null && val == null) {
              return 'กรุณาเลือกตำบล/แขวง';
            }
            return null;
          },
        ),
         const SizedBox(height: 16),

        TextFormField(
          controller: _zipCodeController,
          decoration: const InputDecoration(
            labelText: 'รหัสไปรษณีย์',
            border: OutlineInputBorder(),
          ),
          readOnly: true, // Auto-filled
          onChanged: (_) => _notifyChanged(),
        ),
      ],
    );
  }
}
