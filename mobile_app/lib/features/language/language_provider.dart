import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

/// Manages app language, supporting user-level language preference.
class LanguageProvider extends ChangeNotifier {
  final Logger _logger = Logger('LanguageProvider');
  Locale _locale = const Locale('en', 'US');
  bool _initialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _initialized;

  LanguageProvider() {
    _initLanguage();
  }

  /// Initializes by loading the language for the current user or global config.
  Future<void> _initLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Attempt to load user-specific language preference
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final String? lang = userDoc.data()?['language'];
        if (lang != null) {
          _locale = _localeForCode(lang);
          _logger.info('Loaded user language: $lang');
        } else {
          await _loadGlobalLanguage();
        }
      } else {
        await _loadGlobalLanguage();
      }
      _initialized = true;
      notifyListeners();
    } catch (e, stack) {
      _logger.severe('Error initializing language: $e', e, stack);
    }
  }

  /// Loads the default language from the global config.
  Future<void> _loadGlobalLanguage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('language')
          .get();
      if (doc.exists && doc['enabled'] == true) {
        final String? lang = doc.data()?['default'];
        _locale = _localeForCode(lang ?? 'en');
        _logger.info('Loaded global language: $lang');
      } else {
        _locale = const Locale('en', 'US');
        _logger.info('No global language found; defaulted to en-US');
      }
    } catch (e, stack) {
      _logger.severe('Error loading global language: $e', e, stack);
    }
  }

  /// Sets the language for the app (and saves to user profile if signed in).
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = _localeForCode(languageCode);
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'language': languageCode}, SetOptions(merge: true));
        _logger.info('Saved user language to Firestore: $languageCode');
      }
    } catch (e, stack) {
      _logger.severe('Error saving user language: $e', e, stack);
    }
  }

  Locale _localeForCode(String code) {
    switch (code) {
      case 'es':
        return const Locale('es', 'ES');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
}


