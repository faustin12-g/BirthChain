import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/widgets/notification_bell.dart';
import '../di/injection.dart';
import '../features/auth/presentation/auth_provider.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = getIt<ApiClient>();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _updatingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Helper to get appropriate ImageProvider for data URLs or network URLs
  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('data:')) {
      // Data URL - extract base64 and decode
      final data = url.split(',').last;
      return MemoryImage(base64Decode(data));
    }
    return NetworkImage(url);
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get(ApiEndpoints.profile);
      _profile = res.data as Map<String, dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
    );
    if (image == null) return;

    setState(() => _updatingImage = true);
    try {
      // Read and convert image to base64
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = image.path.split('.').last.toLowerCase();
      final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

      await _api.dio.put(
        ApiEndpoints.profileImage,
        data: {'base64Image': base64Image, 'contentType': contentType},
      );
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to update image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _updatingImage = false);
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remove Profile Image'),
            content: const Text(
              'Are you sure you want to remove your profile image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _api.dio.delete(ApiEndpoints.profileImage);
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile image removed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to remove image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _profile?['fullName'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.put(
                      ApiEndpoints.profile,
                      data: {
                        'fullName': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      },
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                    navigator.pop(true);
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ?? 'Failed to update',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (updated == true) _loadProfile();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Current Password *',
                    ),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New Password *',
                    ),
                    obscureText: true,
                    validator:
                        (v) =>
                            v != null && v.length >= 6 ? null : 'Min 6 chars',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password *',
                    ),
                    obscureText: true,
                    validator:
                        (v) =>
                            v == newCtrl.text ? null : 'Passwords don\'t match',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.put(
                      ApiEndpoints.profilePassword,
                      data: {
                        'currentPassword': currentCtrl.text,
                        'newPassword': newCtrl.text,
                      },
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                    navigator.pop();
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ??
                              'Failed to change password',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'FacilityAdmin':
        return AppTheme.accentOrange;
      case 'Provider':
        return Colors.teal;
      default:
        return AppTheme.navyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profileImageUrl = _profile?['profileImageUrl'] as String?;
    final hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    final roleColor = _getRoleColor(auth.role);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Profile'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile card with image
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap:
                                      _updatingImage
                                          ? null
                                          : _pickAndUploadImage,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: roleColor.withAlpha(25),
                                    backgroundImage:
                                        hasImage
                                            ? _getImageProvider(
                                              profileImageUrl!,
                                            )
                                            : null,
                                    child:
                                        _updatingImage
                                            ? const CircularProgressIndicator()
                                            : hasImage
                                            ? null
                                            : Text(
                                              (auth.name ?? 'U')[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: roleColor,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap:
                                        _updatingImage
                                            ? null
                                            : _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.navyBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasImage)
                              TextButton.icon(
                                onPressed: _removeImage,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                                label: Text(
                                  'Remove Image',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              _profile?['fullName'] ?? auth.name ?? 'User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile?['email'] ?? '',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if ((_profile?['phone'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _profile!['phone'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                auth.role ?? 'User',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showEditDialog,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit Profile'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Change Password'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Admin section
                    if (auth.isAdmin) ...[
                      Text(
                        'Administration',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.dashboard_outlined),
                              title: const Text('Admin Dashboard'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/admin-dashboard'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Account section
                    Text(
                      'Account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red.shade400),
                        title: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                        onTap: () async {
                          final authProv = context.read<AuthProvider>();
                          final navigator = Navigator.of(context);
                          await authProv.logout();
                          if (context.mounted) {
                            navigator.pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
