import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// A reusable PIN entry dialog.
/// Shows a numeric keypad for entering 4-6 digit PIN.
class PinEntryDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<bool> Function(String pin)? onVerify;
  final VoidCallback? onForgotPin;
  final bool showForgotPin;
  final bool returnPinOnly;

  const PinEntryDialog({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle,
    this.onVerify,
    this.onForgotPin,
    this.showForgotPin = false,
    this.returnPinOnly = false,
  });

  /// Show PIN entry dialog and return true if PIN was verified successfully
  static Future<bool> show(
    BuildContext context, {
    String title = 'Enter PIN',
    String? subtitle,
    required Future<bool> Function(String pin) onVerify,
    VoidCallback? onForgotPin,
    bool showForgotPin = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PinEntryDialog(
            title: title,
            subtitle: subtitle,
            onVerify: onVerify,
            onForgotPin: onForgotPin,
            showForgotPin: showForgotPin,
            returnPinOnly: false,
          ),
    );
    return result ?? false;
  }

  /// Show PIN entry dialog and return the entered PIN (for external verification)
  static Future<String?> getPin(
    BuildContext context, {
    String title = 'Enter PIN',
    String? message,
  }) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PinEntryDialog(
            title: title,
            subtitle: message,
            returnPinOnly: true,
          ),
    );
    return result;
  }

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }

    // If returnPinOnly, just return the PIN
    if (widget.returnPinOnly) {
      Navigator.of(context).pop(pin);
      return;
    }

    // Otherwise verify the PIN
    if (widget.onVerify == null) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await widget.onVerify!(pin);
      if (success) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Invalid PIN');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addDigit(String digit) {
    if (_pinController.text.length < 6) {
      _pinController.text += digit;
      setState(() => _error = null);
    }
  }

  void _removeDigit() {
    if (_pinController.text.isNotEmpty) {
      _pinController.text = _pinController.text.substring(
        0,
        _pinController.text.length - 1,
      );
      setState(() => _error = null);
    }
  }

  void _clearPin() {
    _pinController.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final pinLength = _pinController.text.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.lock, color: AppTheme.navyBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),

            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // PIN dots display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < pinLength;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.navyBlue : Colors.grey[300],
                    border: Border.all(
                      color: filled ? AppTheme.navyBlue : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Numeric keypad
            _buildKeypad(),

            const SizedBox(height: 20),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || pinLength < 4 ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            if (widget.showForgotPin && widget.onForgotPin != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onForgotPin,
                child: const Text('Forgot PIN?'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildKeypadRow(['C', '0', '⌫']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == 'C' || key == '⌫';
    final isEmpty = key.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color:
            isEmpty
                ? Colors.transparent
                : isSpecial
                ? Colors.grey[200]
                : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:
              isEmpty
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    if (key == 'C') {
                      _clearPin();
                    } else if (key == '⌫') {
                      _removeDigit();
                    } else {
                      _addDigit(key);
                    }
                  },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 64,
            height: 56,
            alignment: Alignment.center,
            child:
                key == '⌫'
                    ? const Icon(Icons.backspace_outlined, size: 22)
                    : Text(
                      key,
                      style: TextStyle(
                        fontSize: isSpecial ? 14 : 24,
                        fontWeight: FontWeight.w600,
                        color: isSpecial ? Colors.grey[700] : AppTheme.navyBlue,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
