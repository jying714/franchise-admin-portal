// lib/core/models/bank_account.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccount {
  final String id;
  final DocumentReference franchiseRef;
  final DocumentReference locationRef;
  final DocumentReference ownerRef;
  final String bankName;
  final String accountLast4;
  final String accountType; // e.g., 'business', 'personal'
  final String currency;
  final String country;
  final bool verified;
  final String plaidStatus;
  final String stripeStatus;
  final String integration; // e.g., 'plaid', 'stripe'
  final DateTime? addedAt;
  final DateTime? removedAt;
  final Map<String, dynamic> customFields;

  BankAccount({
    required this.id,
    required this.franchiseRef,
    required this.locationRef,
    required this.ownerRef,
    required this.bankName,
    required this.accountLast4,
    required this.accountType,
    required this.currency,
    required this.country,
    required this.verified,
    required this.plaidStatus,
    required this.stripeStatus,
    required this.integration,
    this.addedAt,
    this.removedAt,
    this.customFields = const {},
  });

  factory BankAccount.fromFirestore(Map<String, dynamic> data, String id) {
    return BankAccount(
      id: id,
      franchiseRef: data['franchiseId'] as DocumentReference,
      locationRef: data['locationId'] as DocumentReference,
      ownerRef: data['owner_id'] as DocumentReference,
      bankName: data['bank_name'] ?? '',
      accountLast4: data['account_last4'] ?? '',
      accountType: data['account_type'] ?? '',
      currency: data['currency'] ?? '',
      country: data['country'] ?? '',
      verified: data['verified'] ?? false,
      plaidStatus: data['plaid_status'] ?? '',
      stripeStatus: data['stripe_status'] ?? '',
      integration: data['integration'] ?? '',
      addedAt: (data['added_at'] as Timestamp?)?.toDate(),
      removedAt: (data['removed_at'] as Timestamp?)?.toDate(),
      customFields: data['custom_fields'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseRef,
      'locationId': locationRef,
      'owner_id': ownerRef,
      'bank_name': bankName,
      'account_last4': accountLast4,
      'account_type': accountType,
      'currency': currency,
      'country': country,
      'verified': verified,
      'plaid_status': plaidStatus,
      'stripe_status': stripeStatus,
      'integration': integration,
      'added_at': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
      'removed_at': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
      'custom_fields': customFields,
    };
  }

  BankAccount copyWith({
    String? id,
    DocumentReference? franchiseRef,
    DocumentReference? locationRef,
    DocumentReference? ownerRef,
    String? bankName,
    String? accountLast4,
    String? accountType,
    String? currency,
    String? country,
    bool? verified,
    String? plaidStatus,
    String? stripeStatus,
    String? integration,
    DateTime? addedAt,
    DateTime? removedAt,
    Map<String, dynamic>? customFields,
  }) {
    return BankAccount(
      id: id ?? this.id,
      franchiseRef: franchiseRef ?? this.franchiseRef,
      locationRef: locationRef ?? this.locationRef,
      ownerRef: ownerRef ?? this.ownerRef,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      verified: verified ?? this.verified,
      plaidStatus: plaidStatus ?? this.plaidStatus,
      stripeStatus: stripeStatus ?? this.stripeStatus,
      integration: integration ?? this.integration,
      addedAt: addedAt ?? this.addedAt,
      removedAt: removedAt ?? this.removedAt,
      customFields: customFields ?? this.customFields,
    );
  }
}
