import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/models/franchise_info.dart';
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
// design_tokens import removed for MVP compatibility; using Material defaults
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/models/user.dart' as app_user;

/// Simple Franchise Selector screen (or can be shown as bottom sheet).
/// Lists the user's available franchises and allows switching.
/// Pulls full FranchiseInfo using the user's franchiseIds for name/logo.
class FranchiseSelectorScreen extends StatefulWidget {
  const FranchiseSelectorScreen({super.key});

  @override
  State<FranchiseSelectorScreen> createState() => _FranchiseSelectorScreenState();
}

class _FranchiseSelectorScreenState extends State<FranchiseSelectorScreen> {
  List<FranchiseInfo> _franchises = [];
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
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      // Get current user from the stream provider or firestore
      // For simplicity, we assume the profile/user data has franchiseIds.
      // In a real app you'd have the current User model easily accessible.
      // Here we fetch fresh for the selector.
      final currentUser = await _getCurrentUser(firestore); // simplistic

      if (currentUser == null || currentUser.franchiseIds.isEmpty) {
        setState(() {
          _franchises = [];
          _loading = false;
        });
        return;
      }

      final infos = await firestore.getFranchisesByIds(currentUser.franchiseIds);
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

  // Helper to get current user (in real app this would come from a UserProvider/StreamProvider)
  Future<app_user.User?> _getCurrentUser(FirestoreService firestore) async {
    // This is a simplification. In production you'd have a proper current user provider.
    final fbUser = FirebaseAuth.instance.currentUser; // need import
    if (fbUser == null) return null;
    return await firestore.getUser(fbUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider = Provider.of<FranchiseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Restaurant'),
        backgroundColor: Colors.deepOrange,
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
                        final isCurrent = f.id == franchiseProvider.currentFranchiseId;

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
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: f.status != null ? Text(f.status!) : null,
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: () async {
                            await franchiseProvider.setCurrentFranchiseId(f.id);
                            // Load details for dynamic branding
                            final firestore = Provider.of<FirestoreService>(context, listen: false);
                            await franchiseProvider.loadCurrentFranchiseDetails(firestore);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Switched to ${f.name}')),
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

