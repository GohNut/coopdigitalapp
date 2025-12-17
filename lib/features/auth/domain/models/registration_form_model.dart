class RegistrationFormModel {
  final AccountInfo accountInfo;
  final PersonalInfo personalInfo;
  final OccupationInfo occupationInfo;
  final Consent consent;

  RegistrationFormModel({
    required this.accountInfo,
    required this.personalInfo,
    required this.occupationInfo,
    required this.consent,
  });

  RegistrationFormModel copyWith({
    AccountInfo? accountInfo,
    PersonalInfo? personalInfo,
    OccupationInfo? occupationInfo,
    Consent? consent,
  }) {
    return RegistrationFormModel(
      accountInfo: accountInfo ?? this.accountInfo,
      personalInfo: personalInfo ?? this.personalInfo,
      occupationInfo: occupationInfo ?? this.occupationInfo,
      consent: consent ?? this.consent,
    );
  }
}

class AccountInfo {
  final String? email;
  final String citizenId;
  final String mobile;
  final String password;
  final String confirmPassword;

  AccountInfo({
    this.email,
    this.citizenId = '',
    this.mobile = '',
    this.password = '',
    this.confirmPassword = '',
  });

  AccountInfo copyWith({
    String? email,
    String? citizenId,
    String? mobile,
    String? password,
    String? confirmPassword,
  }) {
    return AccountInfo(
      email: email ?? this.email,
      citizenId: citizenId ?? this.citizenId,
      mobile: mobile ?? this.mobile,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }
}

class PersonalInfo {
  final String fullName;
  final DateTime? birthDate;
  final String maritalStatus; // 'single', 'married', 'divorced'
  final SpouseInfo? spouseInfo;
  final Address currentAddress;

  PersonalInfo({
    this.fullName = '',
    this.birthDate,
    this.maritalStatus = 'single',
    this.spouseInfo,
    required this.currentAddress,
  });

  PersonalInfo copyWith({
    String? fullName,
    DateTime? birthDate,
    String? maritalStatus,
    SpouseInfo? spouseInfo,
    Address? currentAddress,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      spouseInfo: spouseInfo ?? this.spouseInfo,
      currentAddress: currentAddress ?? this.currentAddress,
    );
  }
}

class SpouseInfo {
  final String fullName;
  final DateTime? birthDate;

  SpouseInfo({
    this.fullName = '',
    this.birthDate,
  });

  SpouseInfo copyWith({
    String? fullName,
    DateTime? birthDate,
  }) {
    return SpouseInfo(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

class Address {
  final String details;
  final String extra;
  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;
  final String zipCode;

  Address({
    this.details = '',
    this.extra = '',
    this.provinceId,
    this.districtId,
    this.subDistrictId,
    this.zipCode = '',
  });

  Address copyWith({
    String? details,
    String? extra,
    int? provinceId,
    int? districtId,
    int? subDistrictId,
    String? zipCode,
  }) {
    return Address(
      details: details ?? this.details,
      extra: extra ?? this.extra,
      provinceId: provinceId ?? this.provinceId,
      districtId: districtId ?? this.districtId,
      subDistrictId: subDistrictId ?? this.subDistrictId,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}

class OccupationInfo {
  final String occupationType; // 'company_employee', 'self_employed', 'government', 'other'
  final String otherOccupation;
  final double? income;
  final Address workplaceAddress;
  final GovDetails? govDetails;

  OccupationInfo({
    this.occupationType = 'company_employee',
    this.otherOccupation = '',
    this.income,
    required this.workplaceAddress,
    this.govDetails,
  });

  OccupationInfo copyWith({
    String? occupationType,
    String? otherOccupation,
    double? income,
    Address? workplaceAddress,
    GovDetails? govDetails,
  }) {
    return OccupationInfo(
      occupationType: occupationType ?? this.occupationType,
      otherOccupation: otherOccupation ?? this.otherOccupation,
      income: income ?? this.income,
      workplaceAddress: workplaceAddress ?? this.workplaceAddress,
      govDetails: govDetails ?? this.govDetails,
    );
  }
}

class GovDetails {
  final String unitName;
  final String unitCode;
  final String position;
  final String positionCode;
  final String level;
  final String lineOfWorkCode;
  final String affiliation;
  final String affiliationCode;

  GovDetails({
    this.unitName = '',
    this.unitCode = '',
    this.position = '',
    this.positionCode = '',
    this.level = '',
    this.lineOfWorkCode = '',
    this.affiliation = '',
    this.affiliationCode = '',
  });

   GovDetails copyWith({
    String? unitName,
    String? unitCode,
    String? position,
    String? positionCode,
    String? level,
    String? lineOfWorkCode,
    String? affiliation,
    String? affiliationCode,
  }) {
    return GovDetails(
      unitName: unitName ?? this.unitName,
      unitCode: unitCode ?? this.unitCode,
      position: position ?? this.position,
      positionCode: positionCode ?? this.positionCode,
      level: level ?? this.level,
      lineOfWorkCode: lineOfWorkCode ?? this.lineOfWorkCode,
      affiliation: affiliation ?? this.affiliation,
      affiliationCode: affiliationCode ?? this.affiliationCode,
    );
  }
}

class Consent {
  final bool ruleAccepted;
  final bool nonMemberElsewhere;
  final bool feeAgreement;
  final bool pdpaAccepted;

  Consent({
    this.ruleAccepted = false,
    this.nonMemberElsewhere = false,
    this.feeAgreement = false,
    this.pdpaAccepted = false,
  });

  Consent copyWith({
    bool? ruleAccepted,
    bool? nonMemberElsewhere,
    bool? feeAgreement,
    bool? pdpaAccepted,
  }) {
    return Consent(
      ruleAccepted: ruleAccepted ?? this.ruleAccepted,
      nonMemberElsewhere: nonMemberElsewhere ?? this.nonMemberElsewhere,
      feeAgreement: feeAgreement ?? this.feeAgreement,
      pdpaAccepted: pdpaAccepted ?? this.pdpaAccepted,
    );
  }
}
