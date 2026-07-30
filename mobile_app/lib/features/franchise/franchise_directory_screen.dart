import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/services/franchise_bind_service.dart';
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:provider/provider.dart';

/// CF7: Public directory foundation — listed franchises only; bind on select.
class FranchiseDirectoryScreen extends StatefulWidget {
  const FranchiseDirectoryScreen({super.key});

  @override
  State<FranchiseDirectoryScreen> createState() =>
      _FranchiseDirectoryScreenState();
}

class _FranchiseDirectoryScreenState extends State<FranchiseDirectoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _binding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _select(String franchiseId) async {
    if (_binding || franchiseId.isEmpty) return;
    setState(() => _binding = true);
    try {
      final ok = await FranchiseBindService.bind(context, franchiseId);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that restaurant')),
        );
        setState(() => _binding = false);
      }
      // On success bind navigates to MainMenu.
    } catch (e) {
      if (mounted) {
        setState(() => _binding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return docs;
    return docs.where((doc) {
      final d = doc.data();
      final name = (d['name'] as String? ?? '').toLowerCase();
      final city = _cityOf(d).toLowerCase();
      final id = doc.id.toLowerCase();
      return name.contains(q) || city.contains(q) || id.contains(q);
    }).toList();
  }

  String _cityOf(Map<String, dynamic> d) {
    final direct = d['city'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final address = d['address'];
    if (address is Map && address['city'] is String) {
      return address['city'] as String;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: 'Find a restaurant',
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          // When directory is root (post-auth, no franchise), user must reach Sign in again.
          if (Provider.of<shared.User?>(context, listen: false) == null)
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context)
                      .pop(); // back to SignIn if it is under us
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Sign in'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or city',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_binding)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 2),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('franchises')
                  .where('listedInDirectory', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Directory unavailable.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _filter(snapshot.data!.docs);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No restaurants listed yet.\n'
                        'Try a QR code or check back soon.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final d = doc.data();
                    final name = (d['name'] as String?) ?? doc.id;
                    final city = _cityOf(d);
                    final logoUrl = d['logoUrl'] as String?;

                    return ListTile(
                      enabled: !_binding,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkImageWidget(
                          imageUrl: logoUrl,
                          fallbackAsset: shared.BrandingConfig.defaultPizzaIcon,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(name),
                      subtitle: city.isEmpty ? null : Text(city),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _select(doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
