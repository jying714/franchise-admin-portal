import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for branding reload in foundations (same pattern as main.dart)

/// Foundational QR scan screen for franchise switching (P2).
/// 
/// - Accepts manual paste / simulated scan (full camera scanner requires mobile_scanner + platform config - out of foundations scope)
/// - Parses using shared qr_utils
/// - Calls FranchiseProvider.setFranchiseId + triggers branding reload
/// - Navigates to main menu with the new franchise active
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _qrController = TextEditingController();
  String? _statusMessage;
  bool _processing = false;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _processQR(String raw) async {
    if (raw.trim().isEmpty) return;

    setState(() {
      _processing = true;
      _statusMessage = null;
    });

    try {
      final parsed = shared.parseFranchiseQR(raw);
      final franchiseId = parsed['franchiseId'] ?? '';

      if (franchiseId.isEmpty) {
        throw Exception('Invalid franchise QR payload');
      }

      final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);

      await fp.setFranchiseId(franchiseId);

      // Best-effort reload branding (same pattern as bootstrap)
      try {
        final doc = await FirebaseFirestore.instance  // direct for foundations parity with main.dart
            .collection('franchises')
            .doc(franchiseId)
            .get();
        if (doc.exists && doc.data() != null) {
          fp.setBrandingFromFranchiseDoc(doc.data()!);
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Switched to franchise: $franchiseId';
      });

      // Navigate to main menu (franchise now active)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _simulateDoughboys() {
    final testPayload = shared.generateFranchiseQR(
      'doughboys_pizzeria',
      name: 'Doughboys Pizzeria',
    );
    _qrController.text = testPayload;
    _processQR(testPayload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Franchise QR'),
        backgroundColor: UiConfig.primaryColor,
        foregroundColor: UiConfig.foregroundColorDark,
        elevation: 0,
      ),
      backgroundColor: UiConfig.backgroundColorDark,
      body: Padding(
        padding: UiConfig.defaultScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 96, color: Colors.white70),
            const SizedBox(height: 24),
            Text(
              'Point your camera at a franchise QR code',
              style: UiConfig.titleStyle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Foundations mode: use Simulate or paste a payload like "fhq://f/doughboys_pizzeria"',
              style: UiConfig.captionStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _qrController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'QR Content or Franchise ID',
                labelStyle: TextStyle(color: UiConfig.secondaryTextColor),
                filled: true,
                fillColor: UiConfig.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (v) => _processQR(v),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: _processing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle),
              label: Text(_processing ? 'Processing...' : 'Process QR / Switch Franchise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UiConfig.primaryColor,
                foregroundColor: UiConfig.foregroundColorDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _processing ? null : () => _processQR(_qrController.text),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text('Simulate Doughboys QR (test)'),
              onPressed: _processing ? null : _simulateDoughboys,
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage!.startsWith('Error')
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.startsWith('Error') ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ),
            ],

            const Spacer(),
            Text(
              'Deep link example: https://franchisehq.io/f/doughboys_pizzeria',
              style: UiConfig.captionStyle.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
