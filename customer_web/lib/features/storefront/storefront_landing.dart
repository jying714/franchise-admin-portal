import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../home/storefront_home_screen.dart';
import 'storefront_template.dart';
import 'templates/modern/modern_storefront_home.dart';

/// Resolves config/storefront.templateId and mounts the correct landing.
/// Default remains [StorefrontHomeScreen] (unchanged).
class StorefrontLanding extends StatefulWidget {
  const StorefrontLanding({super.key});

  @override
  State<StorefrontLanding> createState() => _StorefrontLandingState();
}

class _StorefrontLandingState extends State<StorefrontLanding> {
  bool _loading = true;
  StorefrontTemplateId _template = StorefrontTemplateId.defaultLayout;
  String? _loadedForId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = Provider.of<shared.FranchiseProvider>(
      context,
      listen: false,
    ).currentFranchiseId;
    if (id.isEmpty || id == 'unknown') return;
    if (_loadedForId == id) return;
    _loadedForId = id;
    _load(id);
  }

  Future<void> _load(String franchiseId) async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('storefront')
          .get();
      final data = snap.data() ?? {};
      final parsed = parseStorefrontTemplateId(data['templateId']?.toString());
      if (!mounted) return;
      setState(() {
        _template = parsed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _template = StorefrontTemplateId.defaultLayout;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_template) {
      case StorefrontTemplateId.modern:
        return const ModernStorefrontHome();
      case StorefrontTemplateId.defaultLayout:
        return const StorefrontHomeScreen();
    }
  }
}
