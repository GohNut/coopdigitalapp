import 'dart:convert';
import 'package:flutter/services.dart';

class AddressData {
  static List<Map<String, dynamic>> provinces = [];
  static Map<int, List<Map<String, dynamic>>> districts = {};
  static Map<int, List<Map<String, dynamic>>> subDistricts = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/json/thailand_geography.json');
      final List<dynamic> data = jsonDecode(jsonString);

      // Unique sets to avoid duplicates
      final Set<int> addedProvinceIds = {};
      final Set<int> addedDistrictIds = {};

      provinces = [];
      districts = {};
      subDistricts = {};

      for (var item in data) {
        // Parse Province
        int pId = item['provinceCode']; 
        if (!addedProvinceIds.contains(pId)) {
          provinces.add({
            'id': pId,
            'name': item['provinceNameTh'],
          });
          addedProvinceIds.add(pId);
        }

        // Parse District (Amphure)
        int dId = item['districtCode'];
        if (!addedDistrictIds.contains(dId)) {
          if (!districts.containsKey(pId)) {
            districts[pId] = [];
          }
          districts[pId]!.add({
            'id': dId,
            'name': item['districtNameTh'],
          });
          addedDistrictIds.add(dId);
        }

        // Parse SubDistrict (Tambon)
        int sdId = item['subdistrictCode'];
        if (!subDistricts.containsKey(dId)) {
          subDistricts[dId] = [];
        }
        // SubDistricts might have duplicates in the flat list if they have multiple postal codes?
        // Actually, the structure seems to be one row per subdistrict.
        // Wait, the sample had multiple entries for "Phra Nakhon" district.
        // Subdistricts are unique per district usually.
        // The ID of subdistrict should be unique.
        
        // Check if this subdistrict is already added to this district list
        bool alreadyAdded = subDistricts[dId]!.any((sd) => sd['id'] == sdId);
        if (!alreadyAdded) {
           subDistricts[dId]!.add({
            'id': sdId,
            'name': item['subdistrictNameTh'],
            'zip': item['postalCode']?.toString() ?? '',
          });
        }
      }
      
      // Sort lists by name for better UX
      provinces.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      for (var key in districts.keys) {
        districts[key]!.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }
      for (var key in subDistricts.keys) {
        subDistricts[key]!.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }

      _initialized = true;
    } catch (e) {
      print('Error loading geography data: $e');
    }
  }

  static String getProvinceName(int? id) {
    if (id == null) return '-';
    // Handle case where data might not be loaded yet? 
    // Ideally init() should be called before this.
    final province = provinces.firstWhere(
      (p) => p['id'] == id, 
      orElse: () => {'name': '-'}
    );
    return province['name'];
  }

  static String getDistrictName(int? provinceId, int? districtId) {
    if (provinceId == null || districtId == null) return '-';
    if (!districts.containsKey(provinceId)) return '-';
    final districtList = districts[provinceId]!;
    final district = districtList.firstWhere(
      (d) => d['id'] == districtId, 
      orElse: () => {'name': '-'}
    );
    return district['name'];
  }

  static String getSubDistrictName(int? districtId, int? subDistrictId) {
    if (districtId == null || subDistrictId == null) return '-';
    if (!subDistricts.containsKey(districtId)) return '-';
    final subDistrictList = subDistricts[districtId]!;
    final subDistrict = subDistrictList.firstWhere(
      (d) => d['id'] == subDistrictId, 
      orElse: () => {'name': '-'}
    );
    return subDistrict['name'];
  }
}
