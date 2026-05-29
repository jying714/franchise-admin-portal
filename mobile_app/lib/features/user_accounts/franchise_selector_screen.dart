import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';

class FranchiseSelectorScreen extends StatefulWidget {
  const FranchiseSelectorScreen({super.key});

  @override
  State<FranchiseSelectorScreen> createState() =>
      _FranchiseSelectorScreenState();
}

class _FranchiseSelectorScreenState extends State<FranchiseSelectorScreen> {
  List<shared.FranchiseInfo> _franchises = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFranchises();
  }

  Future<void> _loadFranchises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final currentUser = await _getCurrentUser(firestore);

      if (currentUser == null || currentUser.franchiseIds.isEmpty) {
        setState(() {
          _franchises = [];
          _loading = false;
        });
        return;
      }

      final infos =
          await firestore.getFranchisesByIds(currentUser.franchiseIds);
      setState(() {
        _franchises = infos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<shared.User?> _getCurrentUser(
      shared.FirestoreService firestore) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return null;
    return await firestore.getUser(fbUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider = Provider.of<FranchiseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.switchRestaurant),
        backgroundColor: UiConfig.primaryColor, // Use your UiConfig
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error loading locations: $_error'))
              : _franchises.isEmpty
                  ? Center(
                      child: Text(
                        'No restaurant locations found for your account.',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _franchises.length,
                      itemBuilder: (context, index) {
                        final f = _franchises[index];
                        final isCurrent =
                            f.id == franchiseProvider.currentFranchiseId;

                        return ListTile(
                          leading: f.logoUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(f.logoUrl!),
                                  backgroundColor: Colors.grey[200],
                                )
                              : const CircleAvatar(child: Icon(Icons.store)),
                          title: Text(
                            f.name,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: f.status != null ? Text(f.status!) : null,
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                          onTap: () async {
                            await franchiseProvider.setCurrentFranchiseId(f.id);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Switched to ${f.name}')),
                              );
                              Navigator.of(context).pop(); // close selector
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
