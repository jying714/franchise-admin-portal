import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _hasCameraPermission = false;
  bool _isScanning = true;

  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _qrController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasCameraPermission = status.isGranted;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _processing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      setState(() {
        _isScanning = false; // pause scanning while processing
      });
      _processQR(rawValue);
    }
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

      // Best-effort reload branding (FranchiseProvider + shared.UiConfig pattern)
      try {
        final doc = await FirebaseFirestore.instance
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
          _statusMessage =
              'Error: ${e.toString().replaceAll('Exception: ', '')}';
          _isScanning = true; // allow retry
        });
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    });
  }

  void _onManualSubmit() {
    _processQR(_qrController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FranchiseAppBar(
        title: 'Scan Franchise QR',
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
        actions: [
          if (_hasCameraPermission)
            IconButton(
              icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
              onPressed: _processing ? null : _toggleScanning,
              tooltip: _isScanning ? 'Pause scanner' : 'Resume scanner',
            ),
        ],
      ),
      backgroundColor: shared.UiConfig.backgroundColorDark,
      body: SafeArea(
        child: Padding(
          padding: shared.UiConfig.defaultScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Real Camera Scanner or Permission UI
              if (_hasCameraPermission) ...[
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: shared.UiConfig.primaryColor, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      if (!_isScanning)
                        Container(
                          color: shared.UiConfig.shadowColor
                              .withValues(alpha: 0.54),
                          child: Center(
                            child: Text(
                              'Scanner Paused',
                              style: TextStyle(
                                  color: shared.UiConfig.onPrimaryColor,
                                  fontSize: 18),
                            ),
                          ),
                        ),
                      // Simple overlay corners
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: shared.UiConfig.secondaryColor
                                    .withValues(alpha: 0.6),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isScanning
                      ? 'Point camera at a franchise QR code (fhq://f/...)'
                      : 'Scanner paused — tap play to resume',
                  style: shared.UiConfig.captionStyle,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: shared.UiConfig.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography,
                          size: 48,
                          color: shared.UiConfig.onPrimaryColor
                              .withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      Text(
                        'Camera permission required',
                        style:
                            shared.UiConfig.titleStyle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _requestCameraPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shared.UiConfig.primaryColor,
                          foregroundColor: shared.UiConfig.foregroundColorDark,
                        ),
                        child: const Text('Grant Camera Access'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Manual fallback (always available)
              Text(
                'Or paste QR content manually',
                style: shared.UiConfig.captionStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qrController,
                style: TextStyle(color: shared.UiConfig.textColor),
                decoration: InputDecoration(
                  labelText: 'QR Payload (e.g. fhq://f/doughboys_pizzeria)',
                  labelStyle:
                      TextStyle(color: shared.UiConfig.secondaryTextColor),
                  filled: true,
                  fillColor: shared.UiConfig.surfaceColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _onManualSubmit(),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                icon: _processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle),
                label: Text(_processing
                    ? 'Processing...'
                    : 'Process & Switch Franchise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: shared.UiConfig.primaryColor,
                  foregroundColor: shared.UiConfig.foregroundColorDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _processing ? null : _onManualSubmit,
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('Error')
                        ? shared.UiConfig.errorColor.withValues(alpha: 0.15)
                        : shared.UiConfig.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Error')
                          ? shared.UiConfig.errorColor
                          : shared.UiConfig.successColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              Text(
                'Supports: fhq://f/{franchiseId}  •  https://franchisehq.io/f/{franchiseId}',
                style: shared.UiConfig.captionStyle.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
