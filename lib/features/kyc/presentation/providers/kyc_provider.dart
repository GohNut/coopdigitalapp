import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/kyc_service.dart';

class KYCState {
  final XFile? idCardImage;
  final XFile? bankBookImage;
  final XFile? selfieImage;
  final String? bankId;
  final String? bankAccountNo;
  final String? kycStatus; // 'not_verified', 'pending', 'verified', 'rejected'
  final String? rejectReason;

  KYCState({
    this.idCardImage,
    this.bankBookImage,
    this.selfieImage,
    this.bankId,
    this.bankAccountNo,
    this.kycStatus = 'not_verified',
    this.rejectReason,
  });

  KYCState copyWith({
    XFile? idCardImage,
    XFile? bankBookImage,
    XFile? selfieImage,
    String? bankId,
    String? bankAccountNo,
    String? kycStatus,
    String? rejectReason,
  }) {
    return KYCState(
      idCardImage: idCardImage ?? this.idCardImage,
      bankBookImage: bankBookImage ?? this.bankBookImage,
      selfieImage: selfieImage ?? this.selfieImage,
      bankId: bankId ?? this.bankId,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}

class KYCNotifier extends Notifier<KYCState> {
  @override
  KYCState build() {
    // We can trigger background loading here if needed, 
    // but better to call it explicitly when opening the intro screen.
    return KYCState();
  }

  Future<void> loadKYCStatus() async {
    try {
      final statusData = await KYCService.getKYCStatus();
      state = state.copyWith(
        kycStatus: statusData['status'],
        rejectReason: statusData['reject_reason'],
      );
    } catch (e) {
      print('Error loading KYC status: $e');
    }
  }

  void setIdCardImage(XFile image) {
    state = state.copyWith(idCardImage: image);
  }

  void setBankInfo(String bankId, String accountNo, XFile image) {
    state = state.copyWith(
      bankId: bankId,
      bankAccountNo: accountNo,
      bankBookImage: image,
    );
  }

  void setSelfieImage(XFile image) {
    state = state.copyWith(selfieImage: image);
  }

  void reset() {
    state = KYCState();
    loadKYCStatus(); // Reload status after reset
  }
}

final kycProvider = NotifierProvider<KYCNotifier, KYCState>(KYCNotifier.new);
