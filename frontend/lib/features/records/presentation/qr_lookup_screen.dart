import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../patients/domain/patient_models.dart';
import '../../patients/presentation/patient_detail_screen.dart';
import '../../pin/data/pin_repository.dart';
import '../../pin/presentation/pin_entry_dialog.dart';
import '../../pin/presentation/pin_provider.dart';
import '../domain/record_models.dart';
import 'record_provider.dart';

class QrLookupScreen extends StatefulWidget {
  const QrLookupScreen({super.key});

  @override
  State<QrLookupScreen> createState() => _QrLookupScreenState();
}

class _QrLookupScreenState extends State<QrLookupScreen> {
  final _qrCtrl = TextEditingController();
  bool _showManualEntry = false;
  ClientLookup? _clientLookup;
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final qr = _qrCtrl.text.trim();
    if (qr.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _clientLookup = null;
    });

    final pinProvider = context.read<PinProvider>();
    final lookup = await pinProvider.lookupClientByQr(qr);

    if (lookup == null) {
      setState(() {
        _isSearching = false;
        _searchError = pinProvider.error ?? 'Patient not found';
      });
      return;
    }

    setState(() {
      _isSearching = false;
      _clientLookup = lookup;
    });

    // If no PIN is set, proceed with old flow
    if (!lookup.hasPinSet) {
      await _loadFullDataWithoutPin(qr);
    }
    // If PIN is set, wait for patient to enter PIN via _verifyPatientPin
  }

  Future<void> _loadFullDataWithoutPin(String qrCode) async {
    final prov = context.read<RecordProvider>();
    await prov.loadByQrCode(qrCode);
    if (prov.currentClient != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patient: prov.currentClient!),
        ),
      );
    }
  }

  Future<void> _verifyPatientPin() async {
    if (_clientLookup == null) return;

    final pin = await PinEntryDialog.getPin(
      context,
      title: 'Patient PIN Required',
      message: 'Ask ${_clientLookup!.fullName} to enter their PIN',
    );

    if (pin == null || pin.isEmpty || !mounted) return;

    final pinProvider = context.read<PinProvider>();
    final data = await pinProvider.verifyClientPinAndGetData(
      _clientLookup!.qrCodeId,
      pin,
    );

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pinProvider.error ?? 'Invalid PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Build Patient and records from verified data
    if (mounted) {
      final patient = Patient.fromJson(data['client']);
      final records =
          (data['records'] as List?)
              ?.map((r) => MedicalRecord.fromJson(r))
              .toList() ??
          [];

      // Update RecordProvider with the data
      final recordProv = context.read<RecordProvider>();
      recordProv.setClientAndRecords(patient, records);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(patient: patient),
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _clientLookup = null;
      _searchError = null;
      _qrCtrl.clear();
    });
    context.read<PinProvider>().clearClientLookup();
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
            // If we have a client lookup with PIN required, show verification screen
            if (_clientLookup != null && _clientLookup!.hasPinSet)
              _buildPinVerificationCard(theme)
            else ...[
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
                      onPressed: _isSearching ? null : _search,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      child:
                          _isSearching
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.search),
                    ),
                  ],
                ),

                // Error display
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _searchError!,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPinVerificationCard(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  size: 48,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Patient Found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _clientLookup!.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'QR: ${_clientLookup!.qrCodeId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentOrange.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: AppTheme.accentOrange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN Protected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ask the patient to enter their PIN to access their records',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verifyPatientPin,
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter Patient PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearSearch,
                child: const Text('Search Different Patient'),
              ),
            ],
          ),
        ),
      ],
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
