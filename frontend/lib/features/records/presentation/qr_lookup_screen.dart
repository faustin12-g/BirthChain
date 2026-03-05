import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patients/presentation/patient_detail_screen.dart';
import 'record_provider.dart';

class QrLookupScreen extends StatefulWidget {
  const QrLookupScreen({super.key});

  @override
  State<QrLookupScreen> createState() => _QrLookupScreenState();
}

class _QrLookupScreenState extends State<QrLookupScreen> {
  final _qrCtrl = TextEditingController();
  bool _showManualEntry = false;

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final qr = _qrCtrl.text.trim();
    if (qr.isEmpty) return;
    final prov = context.read<RecordProvider>();
    await prov.loadByQrCode(qr);
    if (prov.currentClient != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patient: prov.currentClient!),
        ),
      );
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
            Icon(Icons.shield, color: Colors.orange.shade300, size: 22),
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
              'Scan Patient QR Code',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // QR Scanner placeholder
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C6D).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1A3C6D).withAlpha(50),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: theme.colorScheme.primary.withAlpha(100),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Camera preview',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Corner brackets
                  Positioned(
                    top: 40,
                    left: 40,
                    child: _ScanCorner(alignment: Alignment.topLeft),
                  ),
                  Positioned(
                    top: 40,
                    right: 40,
                    child: _ScanCorner(alignment: Alignment.topRight),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 40,
                    child: _ScanCorner(alignment: Alignment.bottomLeft),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: _ScanCorner(alignment: Alignment.bottomRight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Align the QR code within frame to scan.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Manual entry toggle
            OutlinedButton.icon(
              onPressed:
                  () => setState(() => _showManualEntry = !_showManualEntry),
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter QR Code Manually'),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qrCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Enter QR Code (e.g. BC-XXXX)',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _search,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),

              // Error display
              Consumer<RecordProvider>(
                builder: (_, prov, __) {
                  if (prov.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        prov.error!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
