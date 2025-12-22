
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class KYCState {
  final XFile? idCardImage;
  final XFile? bankBookImage;
  final XFile? selfieImage;
  final String? bankId;
  final String? bankAccountNo;

  KYCState({
    this.idCardImage,
    this.bankBookImage,
    this.selfieImage,
    this.bankId,
    this.bankAccountNo,
  });

  KYCState copyWith({
    XFile? idCardImage,
    XFile? bankBookImage,
    XFile? selfieImage,
    String? bankId,
    String? bankAccountNo,
  }) {
    return KYCState(
      idCardImage: idCardImage ?? this.idCardImage,
      bankBookImage: bankBookImage ?? this.bankBookImage,
      selfieImage: selfieImage ?? this.selfieImage,
      bankId: bankId ?? this.bankId,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
    );
  }
}

class KYCNotifier extends Notifier<KYCState> {
  @override
  KYCState build() {
    return KYCState();
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
  }
}

final kycProvider = NotifierProvider<KYCNotifier, KYCState>(KYCNotifier.new);
