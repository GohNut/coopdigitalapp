import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/registration_form_model.dart';
import '../../../../services/dynamic_deposit_api.dart';

class RegistrationState {
  final int currentStep;
  final RegistrationFormModel form;
  final bool isLoading;
  final String? error;

  RegistrationState({
    this.currentStep = 0,
    required this.form,
    this.isLoading = false,
    this.error,
  });

  RegistrationState copyWith({
    int? currentStep,
    RegistrationFormModel? form,
    bool? isLoading,
    String? error,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      form: form ?? this.form,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error if not provided (or handle explicitly if needed)
    );
  }
}

class RegistrationNotifier extends Notifier<RegistrationState> {
  @override
  RegistrationState build() {
    return RegistrationState(
      form: RegistrationFormModel(
        accountInfo: AccountInfo(),
        personalInfo: PersonalInfo(currentAddress: Address()),
        occupationInfo: OccupationInfo(workplaceAddress: Address()),
        consent: Consent(),
      ),
    );
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  void updateAccountInfo(AccountInfo info) {
    state = state.copyWith(
      form: state.form.copyWith(accountInfo: info),
    );
  }

  void updatePersonalInfo(PersonalInfo info) {
    state = state.copyWith(
      form: state.form.copyWith(personalInfo: info),
    );
  }

  void updateOccupationInfo(OccupationInfo info) {
    state = state.copyWith(
      form: state.form.copyWith(occupationInfo: info),
    );
  }

  void updateConsent(Consent consent) {
    state = state.copyWith(
      form: state.form.copyWith(consent: consent),
    );
  }

  Future<bool> checkDuplicate(String citizenId, String mobile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Real API Check
      final existingMember = await DynamicDepositApiService.getMember(citizenId);
      
      if (existingMember != null) {
        throw 'เลขบัตรประชาชนนี้มีในระบบแล้ว';
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<String> _generateUniqueMemberNumber() async {
    final random = DateTime.now().microsecondsSinceEpoch % 100000000;
    String memberNumber = 'M${random.toString().padLeft(8, '0')}';
    
    // Check uniqueness
    bool isUnique = await DynamicDepositApiService.isMemberNumberUnique(memberNumber);
    int attempts = 0;
    while (!isUnique && attempts < 10) {
      final nextRandom = (DateTime.now().microsecondsSinceEpoch + attempts) % 100000000;
      memberNumber = 'M${nextRandom.toString().padLeft(8, '0')}';
      isUnique = await DynamicDepositApiService.isMemberNumberUnique(memberNumber);
      attempts++;
    }
    return memberNumber;
  }

  Future<bool> submitRegistration({String? pin}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final form = state.form;
      final account = form.accountInfo;
      final personal = form.personalInfo;
      final occupation = form.occupationInfo;

      // 0. Generate Unique Member Number
      final memberNumber = await _generateUniqueMemberNumber();
      
      // Prepare additional data
      final additionalData = <String, dynamic>{
        'member_number': memberNumber, // เก็บหมายเลขสมาชิกที่สุ่มมา
        'birth_date': personal.birthDate?.toIso8601String(),
        'marital_status': personal.maritalStatus,
        'occupation_type': occupation.occupationType,
        'income': occupation.income,
      };

      // Add spouse info if married
      if (personal.spouseInfo != null) {
        additionalData['spouse_name'] = personal.spouseInfo!.fullName;
        additionalData['spouse_birth_date'] = personal.spouseInfo!.birthDate?.toIso8601String();
      }

      // Add address info
      if (personal.currentAddress.details.isNotEmpty) {
        additionalData['address_details'] = personal.currentAddress.details;
        additionalData['address_province_id'] = personal.currentAddress.provinceId;
        additionalData['address_district_id'] = personal.currentAddress.districtId;
        additionalData['address_subdistrict_id'] = personal.currentAddress.subDistrictId;
        additionalData['address_zipcode'] = personal.currentAddress.zipCode;
      }

      // Add occupation details
      if (occupation.occupationType == 'government' && occupation.govDetails != null) {
        additionalData['gov_unit_name'] = occupation.govDetails!.unitName;
        additionalData['gov_position'] = occupation.govDetails!.position;
      }

      // Add workplace address info
      if (occupation.workplaceAddress.details.isNotEmpty) {
        additionalData['workplace_address_details'] = occupation.workplaceAddress.details;
        additionalData['workplace_address_province_id'] = occupation.workplaceAddress.provinceId;
        additionalData['workplace_address_district_id'] = occupation.workplaceAddress.districtId;
        additionalData['workplace_address_subdistrict_id'] = occupation.workplaceAddress.subDistrictId;
        additionalData['workplace_address_zipcode'] = occupation.workplaceAddress.zipCode;
      }

      // Call API to create member
      try {
        await DynamicDepositApiService.createMember(
          citizenId: account.citizenId,
          nameTh: personal.fullName,
          mobile: account.mobile,
          email: account.email,
          password: account.password,
          pin: pin, // Pass PIN from PIN setup screen
          additionalData: additionalData,
        );
      } catch (e) {
        // If member already exists, we might be resuming a partial registration
        // Check if the error is about duplicate member
        if (e.toString().contains('409') || e.toString().contains('already exists')) {
          // This is fine, we'll continue to try creating accounts if they don't exist
          print('Member already exists, proceeding to check/create accounts');
        } else {
          rethrow;
        }
      }

      // Auto-create Savings Account (บัญชีออมทรัพย์)
      try {
        // Check if member already has a savings account
        final existingAccounts = await DynamicDepositApiService.getAccounts(account.citizenId);
        final hasSavings = existingAccounts.any((acc) => acc['accounttype'] == 'savings');
        
        if (hasSavings) {
          print('Member already has a savings account, skipping creation');
        } else {
          final randomAccountNo = '2${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-${(10000 + DateTime.now().microsecond % 90000).toString()}';
          await DynamicDepositApiService.createAccount(
            memberId: account.citizenId,
            accountNumber: randomAccountNo,
            accountName: 'บัญชีออมทรัพย์ - ${personal.fullName}',
            accountType: 'savings',
            interestRate: 0,
          );
        }
      } catch (e) {
         // Silently ignore if account exists or handle specifically
         if (!e.toString().contains('409') && !e.toString().contains('already exists')) {
           rethrow;
         }
      }


      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final registrationProvider =
    NotifierProvider.autoDispose<RegistrationNotifier, RegistrationState>(() {
  return RegistrationNotifier();
});
