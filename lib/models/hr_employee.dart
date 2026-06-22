import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeStatus {
  active('Active'),
  onLeave('On Leave'),
  resigned('Resigned'),
  terminated('Terminated');

  const EmployeeStatus(this.value);
  final String value;

  static EmployeeStatus fromString(String value) => EmployeeStatus.values
      .firstWhere((s) => s.value == value, orElse: () => EmployeeStatus.active);
}

enum EmploymentType {
  fullTime('Full-time'),
  partTime('Part-time'),
  contract('Contract'),
  intern('Intern');

  const EmploymentType(this.value);
  final String value;

  static EmploymentType fromString(String value) =>
      EmploymentType.values.firstWhere((s) => s.value == value,
          orElse: () => EmploymentType.fullTime);
}

enum PaymentMethod {
  cash('Cash'),
  bank('Bank'),
  eWallet('E-Wallet');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) => PaymentMethod.values
      .firstWhere((s) => s.value == value, orElse: () => PaymentMethod.cash);
}

enum SalaryCurrency {
  usd('USD'),
  khr('KHR');

  const SalaryCurrency(this.value);
  final String value;

  static SalaryCurrency fromString(String value) => SalaryCurrency.values
      .firstWhere((s) => s.value == value, orElse: () => SalaryCurrency.usd);
}

class HREmployee {
  const HREmployee({
    required this.id,
    required this.storeId,
    required this.firstName,
    required this.lastName,
    required this.employeeCode,
    this.profileImage,
    this.profileImageThumbnail,
    required this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.nationalId,
    this.nationality,
    required this.phoneNumber,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    required this.position,
    this.department,
    required this.employmentType,
    this.workShift,
    this.startWorkingTime,
    this.endWorkingTime,
    this.lateTime,
    required this.status,
    required this.joinDate,
    this.probationEndDate,
    this.contractEndDate,
    this.reportsTo,
    this.workLocation,
    required this.basicSalary,
    required this.currency,
    this.payFrequency,
    this.overtimeRate,
    this.allowances,
    required this.paymentMethod,
    this.bankName,
    this.bankAccountName,
    this.bankAccount,
    this.eWalletProvider,
    this.eWalletNumber,
    this.isPr,
    this.commission,
    this.commissionType,
    this.taxId,
    this.socialSecurityNumber,
    this.education,
    this.fieldOfStudy,
    this.skills,
    this.notes,
    this.allowCheckinRemote,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String storeId;

  // Basic Info
  final String firstName;
  final String lastName;
  final String employeeCode;
  final String? profileImage;
  final String? profileImageThumbnail;

  // Personal Information
  final String gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? nationalId;
  final String? nationality;

  // Contact Information
  final String phoneNumber;
  final String? email;
  final String? address;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;

  // Employment Details
  final String position;
  final String? department;
  final EmploymentType employmentType;
  final String? workShift;
  final String? startWorkingTime;
  final String? endWorkingTime;
  final int? lateTime;
  final EmployeeStatus status;

  // Important Dates
  final DateTime joinDate;
  final DateTime? probationEndDate;
  final DateTime? contractEndDate;

  // Reporting
  final String? reportsTo;
  final String? workLocation;

  // Salary Information
  final double basicSalary;
  final SalaryCurrency currency;
  final String? payFrequency;
  final double? overtimeRate;
  final double? allowances;

  // Payment Details
  final PaymentMethod paymentMethod;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccount;
  final String? eWalletProvider;
  final String? eWalletNumber;
  final bool? isPr;
  final double? commission;
  final String? commissionType;

  // Tax & Deductions
  final String? taxId;
  final String? socialSecurityNumber;

  // Additional Information
  final String? education;
  final String? fieldOfStudy;
  final String? skills;
  final String? notes;

  // Attendance
  final bool? allowCheckinRemote;

  // Messaging
  final String? fcmToken;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName';

  factory HREmployee.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDateTime(dynamic ts) {
      if (ts is DateTime) return ts;
      try {
        return (ts as Timestamp).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? toDateTimeNullable(dynamic ts) {
      if (ts == null) return null;
      return toDateTime(ts);
    }

    return HREmployee(
      id: id,
      storeId: map['storeId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      employeeCode: map['employeeCode'] as String,
      profileImage: map['profileImage'] as String?,
      profileImageThumbnail: map['profileImageThumbnail'] as String?,
      gender: map['gender'] as String,
      dateOfBirth: toDateTimeNullable(map['dateOfBirth']),
      maritalStatus: map['maritalStatus'] as String?,
      nationalId: map['nationalId'] as String?,
      nationality: map['nationality'] as String?,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactRelation: map['emergencyContactRelation'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      position: map['position'] as String,
      department: map['department'] as String?,
      employmentType: EmploymentType.fromString(map['employmentType'] as String),
      workShift: map['workShift'] as String?,
      startWorkingTime: map['startWorkingTime'] as String?,
      endWorkingTime: map['endWorkingTime'] as String?,
      lateTime: (map['lateTime'] as num?)?.toInt(),
      status: EmployeeStatus.fromString(map['status'] as String),
      joinDate: toDateTime(map['joinDate']),
      probationEndDate: toDateTimeNullable(map['probationEndDate']),
      contractEndDate: toDateTimeNullable(map['contractEndDate']),
      reportsTo: map['reportsTo'] as String?,
      workLocation: map['workLocation'] as String?,
      basicSalary: (map['basicSalary'] as num).toDouble(),
      currency: SalaryCurrency.fromString(map['currency'] as String),
      payFrequency: map['payFrequency'] as String?,
      overtimeRate: (map['overtimeRate'] as num?)?.toDouble(),
      allowances: (map['allowances'] as num?)?.toDouble(),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String),
      bankName: map['bankName'] as String?,
      bankAccountName: map['bankAccountName'] as String?,
      bankAccount: map['bankAccount'] as String?,
      eWalletProvider: map['eWalletProvider'] as String?,
      eWalletNumber: map['eWalletNumber'] as String?,
      isPr: map['isPr'] as bool?,
      commission: (map['commission'] as num?)?.toDouble(),
      commissionType: map['commissionType'] as String?,
      taxId: map['taxId'] as String?,
      socialSecurityNumber: map['socialSecurityNumber'] as String?,
      education: map['education'] as String?,
      fieldOfStudy: map['fieldOfStudy'] as String?,
      skills: map['skills'] as String?,
      notes: map['notes'] as String?,
      allowCheckinRemote: map['allowCheckinRemote'] as bool?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: toDateTime(map['createdAt']),
      updatedAt: toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'firstName': firstName,
        'lastName': lastName,
        'employeeCode': employeeCode,
        if (profileImage != null) 'profileImage': profileImage,
        if (profileImageThumbnail != null)
          'profileImageThumbnail': profileImageThumbnail,
        'gender': gender,
        if (dateOfBirth != null)
          'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        if (maritalStatus != null) 'maritalStatus': maritalStatus,
        if (nationalId != null) 'nationalId': nationalId,
        if (nationality != null) 'nationality': nationality,
        'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (emergencyContactName != null)
          'emergencyContactName': emergencyContactName,
        if (emergencyContactRelation != null)
          'emergencyContactRelation': emergencyContactRelation,
        if (emergencyContactPhone != null)
          'emergencyContactPhone': emergencyContactPhone,
        'position': position,
        if (department != null) 'department': department,
        'employmentType': employmentType.value,
        if (workShift != null) 'workShift': workShift,
        if (startWorkingTime != null) 'startWorkingTime': startWorkingTime,
        if (endWorkingTime != null) 'endWorkingTime': endWorkingTime,
        if (lateTime != null) 'lateTime': lateTime,
        'status': status.value,
        'joinDate': Timestamp.fromDate(joinDate),
        if (probationEndDate != null)
          'probationEndDate': Timestamp.fromDate(probationEndDate!),
        if (contractEndDate != null)
          'contractEndDate': Timestamp.fromDate(contractEndDate!),
        if (reportsTo != null) 'reportsTo': reportsTo,
        if (workLocation != null) 'workLocation': workLocation,
        'basicSalary': basicSalary,
        'currency': currency.value,
        if (payFrequency != null) 'payFrequency': payFrequency,
        if (overtimeRate != null) 'overtimeRate': overtimeRate,
        if (allowances != null) 'allowances': allowances,
        'paymentMethod': paymentMethod.value,
        if (bankName != null) 'bankName': bankName,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        if (bankAccount != null) 'bankAccount': bankAccount,
        if (eWalletProvider != null) 'eWalletProvider': eWalletProvider,
        if (eWalletNumber != null) 'eWalletNumber': eWalletNumber,
        if (isPr != null) 'isPr': isPr,
        if (commission != null) 'commission': commission,
        if (commissionType != null) 'commissionType': commissionType,
        if (taxId != null) 'taxId': taxId,
        if (socialSecurityNumber != null)
          'socialSecurityNumber': socialSecurityNumber,
        if (education != null) 'education': education,
        if (fieldOfStudy != null) 'fieldOfStudy': fieldOfStudy,
        if (skills != null) 'skills': skills,
        if (notes != null) 'notes': notes,
        if (allowCheckinRemote != null) 'allowCheckinRemote': allowCheckinRemote,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}