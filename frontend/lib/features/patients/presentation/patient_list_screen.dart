import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../records/presentation/record_provider.dart';
import 'patient_detail_screen.dart';
import 'register_patient_screen.dart';

/// Providers find patients by QR code only — no list of all patients.
class PatientLookupScreen extends StatefulWidget {
  const PatientLookupScreen({super.key});

  @override
  State<PatientLookupScreen> createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final _qrCtrl = TextEditingController();
  bool _showManualEntry = false;
  bool _isProcessing = false;

  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _qrCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  /// Called when the camera detects a QR / barcode.
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return; // avoid duplicate fires
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!.trim();
    if (code.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerCtrl.stop(); // pause camera while we look up
    _lookupCode(code);
  }

  Future<void> _lookup() async {
    final qr = _qrCtrl.text.trim();
    if (qr.isEmpty) return;
    setState(() => _isProcessing = true);
    await _lookupCode(qr);
  }

  Future<void> _lookupCode(String qr) async {
    final prov = context.read<RecordProvider>();
    await prov.loadByQrCode(qr);

    if (prov.currentClient != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patient: prov.currentClient!),
        ),
      );
    } else if (prov.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error!),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }

    // Re-enable scanning
    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerCtrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('BirthChain'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Find Patient',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan a QR code or enter it manually to\naccess a patient\'s health records.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── Live QR Scanner ──
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C6D).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1A3C6D).withAlpha(50),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera feed
                  MobileScanner(
                    controller: _scannerCtrl,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera unavailable',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use manual entry below',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Scanning overlay with corner brackets
                  if (_isProcessing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  // Corner brackets
                  Positioned(
                    top: 36,
                    left: 36,
                    child: _ScanCorner(alignment: Alignment.topLeft),
                  ),
                  Positioned(
                    top: 36,
                    right: 36,
                    child: _ScanCorner(alignment: Alignment.topRight),
                  ),
                  Positioned(
                    bottom: 36,
                    left: 36,
                    child: _ScanCorner(alignment: Alignment.bottomLeft),
                  ),
                  Positioned(
                    bottom: 36,
                    right: 36,
                    child: _ScanCorner(alignment: Alignment.bottomRight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Align the QR code within frame to scan.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // ── Manual entry toggle ──
            OutlinedButton.icon(
              onPressed:
                  () => setState(() => _showManualEntry = !_showManualEntry),
              icon: Icon(
                _showManualEntry ? Icons.keyboard_hide : Icons.keyboard,
              ),
              label: Text(
                _showManualEntry
                    ? 'Hide Manual Entry'
                    : 'Enter QR Code Manually',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_showManualEntry) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qrCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _lookup(),
                      decoration: InputDecoration(
                        hintText: 'e.g. BC-A1B2C3D4',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer<RecordProvider>(
                    builder:
                        (_, prov, __) => FilledButton(
                          onPressed: prov.isLoading ? null : _lookup,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child:
                              prov.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.search),
                        ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ── Register new patient ──
            Text(
              'New patient?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterPatientScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Register New Patient'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Corner bracket widget for scanner frame ──

class _ScanCorner extends StatelessWidget {
  final Alignment alignment;
  const _ScanCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CornerPainter(alignment: alignment)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  _CornerPainter({required this.alignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF00BFA5)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    if (alignment == Alignment.topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
