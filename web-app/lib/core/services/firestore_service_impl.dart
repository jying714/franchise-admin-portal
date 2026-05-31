// web-app/lib/core/services/firestore_service_impl.dart
//
// Thin compatibility wrapper for the web admin portal.
// All real logic lives in AdminFirestoreService (which extends the shared lightweight impl).
//
// This file exists so that existing code using `FirestoreServiceImpl()`, `shared.FirestoreService()`,
// and `Provider<shared.FirestoreService>` continues to work without mass changes.

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_core/shared_core.dart';
import 'admin_firestore_service.dart';

/// Thin wrapper that gives the **full admin** implementation.
/// Use this everywhere in web-app for backward compatibility.
class FirestoreServiceImpl extends AdminFirestoreService {
  FirestoreServiceImpl({
    firestore.FirebaseFirestore? db,
    fb_auth.FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : super(db: db, auth: auth, functions: functions);
}

/// Convenience factory / alias used in many places in the current web-app codebase.
/// This returns the full admin implementation.
FirestoreServiceImpl createFirestoreService() => FirestoreServiceImpl();

// NOTE: The previous monolithic ~2400-line implementation has been split.
// The old content was archived during the 2026-05 refactor into:
// - packages/shared_core/.../firestore_service_impl.dart (lightweight customer + common)
// - web-app/.../admin_firestore_service.dart (full admin heavy logic)
// This thin file provides a drop-in replacement for all previous Provider and direct instantiation sites.

