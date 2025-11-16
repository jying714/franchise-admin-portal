// web_app/lib/core/widgets/franchise_selector.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FranchiseSelector extends StatefulWidget {
  final void Function(String franchiseId) onSelected;

  const FranchiseSelector({required this.onSelected, super.key});

  @override
  State<FranchiseSelector> createState() => _FranchiseSelectorState();
}

class _FranchiseSelectorState extends State<FranchiseSelector> {
  late Future<List<_FranchiseInfo>> _franchisesFuture;

  @override
  void initState() {
    super.initState();
    _franchisesFuture = _fetchFranchises();
  }

  Future<List<_FranchiseInfo>> _fetchFranchises() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('franchises').get();
      return snapshot.docs.map((doc) {
        return _FranchiseInfo(
          id: doc.id,
          name: doc.data()['displayName']?.toString() ?? doc.id,
          logoUrl: doc.data()['logoUrl']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching franchises: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Franchise'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<_FranchiseInfo>>(
        future: _franchisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load franchises.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        setState(() {
                          _franchisesFuture = _fetchFranchises();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          final franchises = snapshot.data ?? [];
          if (franchises.isEmpty) {
            return const Center(
              child: Text('No franchises available. Please contact support.'),
            );
          }

          final allFranchisesOption = _FranchiseInfo(
            id: 'all',
            name: 'All Franchises',
            logoUrl: null,
          );

          final displayList = [allFranchisesOption, ...franchises];

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final f = displayList[idx];
              return ListTile(
                leading: f.logoUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(f.logoUrl!))
                    : idx == 0
                        ? const CircleAvatar(child: Icon(Icons.all_inclusive))
                        : const CircleAvatar(child: Icon(Icons.storefront)),
                title: Text(f.name),
                subtitle: Text(f.id),
                onTap: () => widget.onSelected(f.id),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FranchiseInfo {
  final String id;
  final String name;
  final String? logoUrl;
  _FranchiseInfo({required this.id, required this.name, this.logoUrl});
}
