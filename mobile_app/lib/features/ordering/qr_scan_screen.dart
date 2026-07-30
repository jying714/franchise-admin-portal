import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_mobile_app/core/services/franchise_bind_service.dart';

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

      if (franchiseId.isEmpty || franchiseId.contains('/')) {
        throw Exception(
          'Invalid franchise QR. Expected fhq://f/{id} or https://franchisehq.io/f/{id}',
        );
      }
      final ok = await FranchiseBindService.bind(context, franchiseId);
      if (!mounted) return;

      if (!ok) {
        throw Exception('Could not switch franchise');
      }

      setState(() {
        _statusMessage = 'Switched to franchise: $franchiseId';
      });
      // Navigation handled inside FranchiseBindService.bind
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
    final scheme = Theme.of(context).colorScheme;
    // Fixed success feedback (D4) — not franchise primary.
    const successColor = Color(0xFF2E7D32);

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
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: shared.UiConfig.defaultScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasCameraPermission) ...[
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.primary, width: 2),
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
                          color: scheme.scrim.withValues(alpha: 0.54),
                          child: Center(
                            child: Text(
                              'Scanner Paused',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.9),
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
                  style: shared.UiConfig.captionStyle.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_photography,
                        size: 48,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Camera permission required',
                        style: shared.UiConfig.titleStyle.copyWith(
                          fontSize: 16,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _requestCameraPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                        child: const Text('Grant Camera Access'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Or paste QR content manually',
                style: shared.UiConfig.captionStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qrController,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'QR Payload (e.g. fhq://f/doughboys_pizzeria)',
                  labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                  filled: true,
                  fillColor: scheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                ),
                onSubmitted: (_) => _onManualSubmit(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: _processing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_processing
                    ? 'Processing...'
                    : 'Process & Switch Franchise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
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
                        ? scheme.error.withValues(alpha: 0.15)
                        : successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Error')
                          ? scheme.error
                          : successColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Supports: fhq://f/{franchiseId}  •  https://franchisehq.io/f/{franchiseId}',
                style: shared.UiConfig.captionStyle.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
