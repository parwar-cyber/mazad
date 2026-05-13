import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-progress KYC submission held in memory across the multi-step flow.
/// Discarded on completion or back-out — never persisted to disk because
/// the ID document file path is sensitive (path may include the user's
/// UUID; we don't want it in any logs or shared-prefs storage).
@immutable
class KycDraft {
  const KycDraft({
    this.idDocFile,
    this.idDocStoragePath,
    this.line1,
    this.line2,
    this.city,
    this.governorate,
    this.payoutMethod,
    this.payoutAccount,
    this.businessName,
  });

  final File? idDocFile;
  final String? idDocStoragePath; // set after successful upload
  final String? line1;
  final String? line2;
  final String? city;
  final String? governorate;
  final String? payoutMethod; // 'zaincash' | 'fastpay' | 'bank' | 'cod'
  final String? payoutAccount;
  final String? businessName;

  KycDraft copyWith({
    File? idDocFile,
    String? idDocStoragePath,
    String? line1,
    String? line2,
    String? city,
    String? governorate,
    String? payoutMethod,
    String? payoutAccount,
    String? businessName,
  }) =>
      KycDraft(
        idDocFile: idDocFile ?? this.idDocFile,
        idDocStoragePath: idDocStoragePath ?? this.idDocStoragePath,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        governorate: governorate ?? this.governorate,
        payoutMethod: payoutMethod ?? this.payoutMethod,
        payoutAccount: payoutAccount ?? this.payoutAccount,
        businessName: businessName ?? this.businessName,
      );
}

class KycDraftNotifier extends StateNotifier<KycDraft> {
  KycDraftNotifier() : super(const KycDraft());

  void setIdDoc(File file, {String? storagePath}) =>
      state = state.copyWith(idDocFile: file, idDocStoragePath: storagePath);

  void setIdDocStoragePath(String path) =>
      state = state.copyWith(idDocStoragePath: path);

  void setAddress({
    required String line1,
    String? line2,
    required String city,
    String? governorate,
  }) =>
      state = state.copyWith(
        line1: line1,
        line2: line2,
        city: city,
        governorate: governorate,
      );

  void setPayout({required String method, String? account}) =>
      state = state.copyWith(
        payoutMethod: method,
        payoutAccount: account,
      );

  void setBusinessName(String name) =>
      state = state.copyWith(businessName: name);

  void reset() => state = const KycDraft();
}

final kycDraftProvider =
    StateNotifierProvider<KycDraftNotifier, KycDraft>((ref) {
  return KycDraftNotifier();
});

/// Submits the KYC tier-2 application. The ID file must already be
/// uploaded — `idDocStoragePath` is the only thing the RPC sees.
Future<void> submitKycTier2(KycDraft d) async {
  final client = Supabase.instance.client;
  await client.rpc('submit_kyc_tier2', params: {
    'p_business_name': d.businessName,
    'p_address': {
      'line1': d.line1,
      if (d.line2 != null && d.line2!.isNotEmpty) 'line2': d.line2,
      'city': d.city,
      if (d.governorate != null && d.governorate!.isNotEmpty)
        'governorate': d.governorate,
    },
    'p_payout_method': d.payoutMethod,
    'p_payout_account':
        d.payoutAccount == null ? null : {'value': d.payoutAccount},
    'p_id_doc_path': d.idDocStoragePath,
  });
}
