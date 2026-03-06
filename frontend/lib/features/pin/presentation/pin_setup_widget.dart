import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import 'pin_provider.dart';

/// Widget for setting up or managing PIN in patient profile
class PinSetupWidget extends StatefulWidget {
  const PinSetupWidget({super.key});

  @override
  State<PinSetupWidget> createState() => _PinSetupWidgetState();
}

class _PinSetupWidgetState extends State<PinSetupWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PinProvider>().loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PinProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.navyBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock, color: AppTheme.navyBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security PIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.hasPinSet
                            ? 'Your data is protected'
                            : 'Add extra security to your data',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (provider.hasPinSet)
                  Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              provider.hasPinSet
                  ? 'Your PIN protects access to your QR code, health records, and prevents unauthorized providers from viewing your data.'
                  : 'Set up a 4-6 digit PIN to protect your health data. Providers will need this PIN to view your records.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.hasPinSet)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showChangePinDialog(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Change'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.navyBlue,
                        side: const BorderSide(color: AppTheme.navyBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRemovePinDialog(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSetPinDialog(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Set Up PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBlue,
                    foregroundColor: Colors.white,
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

  Future<void> _showSetPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppTheme.navyBlue),
                      const SizedBox(width: 12),
                      const Text('Set Up PIN'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a 4-6 digit PIN to protect your health data.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'New PIN',
                            hintText: 'Enter 4-6 digits',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Confirm PIN',
                            hintText: 'Re-enter PIN',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Account Password',
                            hintText: 'Verify your identity',
                            prefixIcon: Icon(Icons.password),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final pin = pinController.text.trim();
                                final confirmPin =
                                    confirmPinController.text.trim();
                                final password = passwordController.text;

                                if (pin.length < 4) {
                                  setState(
                                    () =>
                                        error = 'PIN must be at least 4 digits',
                                  );
                                  return;
                                }
                                if (pin != confirmPin) {
                                  setState(() => error = 'PINs do not match');
                                  return;
                                }
                                if (password.isEmpty) {
                                  setState(
                                    () => error = 'Password is required',
                                  );
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                  error = null;
                                });

                                final provider = context.read<PinProvider>();
                                final success = await provider.setPin(
                                  pin,
                                  password,
                                );

                                if (success) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PIN set up successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    error =
                                        provider.error ?? 'Failed to set PIN';
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Set PIN'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    bool isLoading = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.navyBlue),
                      const SizedBox(width: 12),
                      const Text('Change PIN'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: currentPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Current PIN',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'New PIN',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Confirm New PIN',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final currentPin =
                                    currentPinController.text.trim();
                                final newPin = newPinController.text.trim();
                                final confirmPin =
                                    confirmPinController.text.trim();

                                if (currentPin.length < 4) {
                                  setState(
                                    () => error = 'Enter your current PIN',
                                  );
                                  return;
                                }
                                if (newPin.length < 4) {
                                  setState(
                                    () =>
                                        error =
                                            'New PIN must be at least 4 digits',
                                  );
                                  return;
                                }
                                if (newPin != confirmPin) {
                                  setState(
                                    () => error = 'New PINs do not match',
                                  );
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                  error = null;
                                });

                                final provider = context.read<PinProvider>();
                                final success = await provider.changePin(
                                  currentPin,
                                  newPin,
                                );

                                if (success) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'PIN changed successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    error =
                                        provider.error ??
                                        'Failed to change PIN';
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Change'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _showRemovePinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    bool isLoading = false;
    String? error;

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text('Remove PIN'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to remove your PIN? Your health data will no longer be protected.',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Current PIN',
                          prefixIcon: Icon(Icons.pin),
                          counterText: '',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final pin = pinController.text.trim();
                                if (pin.length < 4) {
                                  setState(
                                    () => error = 'Enter your current PIN',
                                  );
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                  error = null;
                                });

                                final provider = context.read<PinProvider>();
                                final success = await provider.removePin(pin);

                                if (success) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PIN removed'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    error =
                                        provider.error ??
                                        'Failed to remove PIN';
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Remove'),
                    ),
                  ],
                ),
          ),
    );
  }
}
