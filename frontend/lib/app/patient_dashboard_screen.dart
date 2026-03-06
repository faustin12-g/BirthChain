import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../core/widgets/notification_bell.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/notifications/notification_provider.dart';
import '../features/patients/domain/patient_models.dart';
import '../features/pin/presentation/pin_provider.dart';
import '../features/pin/presentation/pin_setup_widget.dart';
import '../features/pin/presentation/pin_entry_dialog.dart';
import '../features/records/domain/record_models.dart';
import '../features/records/presentation/record_provider.dart';
import 'theme.dart';

/// Dashboard shown to patients (role = Patient).
/// Tabs: Home, My Records, My QR Code, Profile.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final prov = context.read<RecordProvider>();
    Future.microtask(() => prov.loadMyRecords());
    // Load notifications from backend
    Future.microtask(
      () => context.read<NotificationProvider>().loadNotifications(),
    );
    // Load PIN status for security checks
    Future.microtask(
      () => context.read<PinProvider>().loadStatus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const _MyRecordsTab(),
      const _MyQrCodeTab(),
      const _PatientProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'My QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 0: Home – Overview + Notifications
// ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

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
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final patient = prov.currentClient;
          final records = prov.records;
          final greeting = _greeting(auth.name ?? 'there');

          return RefreshIndicator(
            onRefresh: () => prov.loadMyRecords(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Greeting card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.navyBlue, Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s your health overview',
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Quick stats ──
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_outlined,
                        label: 'Records',
                        value: '${records.length}',
                        color: AppTheme.navyBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_hospital_outlined,
                        label: 'Last Visit',
                        value:
                            records.isNotEmpty
                                ? _shortDate(records.last.eventDate)
                                : '—',
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.qr_code_2,
                        label: 'QR ID',
                        value: patient?.qrCodeId ?? '—',
                        color: Colors.teal,
                        small: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Notifications section ──
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._buildNotifications(records, patient),
                const SizedBox(height: 24),

                // ── Recent records preview ──
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Records',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  const _EmptyCard(
                    icon: Icons.folder_open,
                    message: 'No records yet. Visit a provider to get started.',
                  )
                else
                  ...records.reversed
                      .take(3)
                      .map((r) => _RecentRecordTile(record: r)),

                // ── Health tips ──
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.accentOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Health Tip',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  color: AppTheme.accentOrange.withAlpha(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppTheme.accentOrange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _healthTip(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _greeting(String name) {
    final hour = DateTime.now().hour;
    final first = name.split(' ').first;
    if (hour < 12) return 'Good Morning, $first';
    if (hour < 17) return 'Good Afternoon, $first';
    return 'Good Evening, $first';
  }

  static String _shortDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return raw.length > 6 ? raw.substring(0, 6) : raw;
    }
  }

  static String _healthTip() {
    final tips = [
      'Stay hydrated — aim for at least 8 glasses of water a day.',
      'Regular check-ups can catch health issues early. Schedule yours today!',
      'A balanced diet rich in fruits and vegetables boosts immunity.',
      'Walking 30 minutes a day reduces the risk of chronic diseases.',
      'Quality sleep is as important as exercise for your overall health.',
      'Keep your medical records up to date for better care coordination.',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  /// Build notification items based on patient state
  static List<Widget> _buildNotifications(
    List<MedicalRecord> records,
    dynamic patient,
  ) {
    final notifications = <Widget>[];

    if (records.isEmpty && patient != null) {
      notifications.add(
        const _NotificationCard(
          icon: Icons.info_outline,
          color: Colors.blue,
          title: 'Welcome to BirthChain!',
          subtitle:
              'Your account is set up. Show your QR code to a healthcare provider to start building your health history.',
          time: 'Just now',
        ),
      );
    }

    if (records.isNotEmpty) {
      final latest = records.last;
      notifications.add(
        _NotificationCard(
          icon: Icons.note_add,
          color: Colors.green,
          title: 'New Record Added',
          subtitle:
              '${latest.facilityName.isNotEmpty ? latest.facilityName : "A provider"} added a ${latest.recordType.toLowerCase()} record.',
          time: _formatTimeAgo(latest.createdAt),
        ),
      );
    }

    if (records.length >= 3) {
      notifications.add(
        _NotificationCard(
          icon: Icons.trending_up,
          color: AppTheme.accentOrange,
          title: 'Health Journey',
          subtitle:
              'You have ${records.length} records across your health history. Keep tracking!',
          time: '',
        ),
      );
    }

    if (patient != null && patient.email.isEmpty) {
      notifications.add(
        const _NotificationCard(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          title: 'Complete Your Profile',
          subtitle:
              'Add your email address to receive important health updates.',
          time: '',
        ),
      );
    }

    if (notifications.isEmpty) {
      notifications.add(
        const _EmptyCard(
          icon: Icons.notifications_off_outlined,
          message: 'No notifications right now. Check back later!',
        ),
      );
    }

    return notifications;
  }

  static String _formatTimeAgo(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool small;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: small ? 11 : 18,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            time.isNotEmpty
                ? Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                )
                : null,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  final MedicalRecord record;
  const _RecentRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String date;
    try {
      date = DateFormat('MMM d, yyyy').format(DateTime.parse(record.eventDate));
    } catch (_) {
      date = record.eventDate;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(20),
          child: Icon(
            _typeIcon(record.recordType),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          record.recordType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          record.facilityName.isNotEmpty
              ? record.facilityName
              : record.details.length > 40
              ? '${record.details.substring(0, 40)}...'
              : record.details,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          date,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'diagnosis':
        return Icons.medical_services;
      case 'medication':
        return Icons.medication;
      case 'vaccination':
        return Icons.vaccines;
      case 'lab test':
        return Icons.science;
      default:
        return Icons.description;
    }
  }
}

// ─────────────────────────────────────────────
// Tab 1: My Records (full list with search & filter)
// ─────────────────────────────────────────────
class _MyRecordsTab extends StatefulWidget {
  const _MyRecordsTab();

  @override
  State<_MyRecordsTab> createState() => _MyRecordsTabState();
}

class _MyRecordsTabState extends State<_MyRecordsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _facilityFilter;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MedicalRecord> _applyFilters(List<MedicalRecord> records) {
    var filtered = records;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((r) {
            return r.details.toLowerCase().contains(q) ||
                r.symptoms.toLowerCase().contains(q) ||
                r.medication.toLowerCase().contains(q) ||
                r.notes.toLowerCase().contains(q) ||
                r.labTests.toLowerCase().contains(q) ||
                r.facilityName.toLowerCase().contains(q) ||
                r.providerName.toLowerCase().contains(q);
          }).toList();
    }

    if (_facilityFilter != null) {
      filtered =
          filtered.where((r) => r.facilityName == _facilityFilter).toList();
    }

    if (_dateRange != null) {
      filtered =
          filtered.where((r) {
            final date = DateTime.tryParse(r.eventDate);
            if (date == null) return false;
            return !date.isBefore(_dateRange!.start) &&
                !date.isAfter(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
    }

    return filtered;
  }

  List<String> _uniqueFacilities(List<MedicalRecord> records) {
    return records
        .map((r) => r.facilityName)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _clearAllFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _facilityFilter = null;
      _dateRange = null;
    });
  }

  static String _fmtChipDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinProvider = context.watch<PinProvider>();
    final hasFilters =
        _searchQuery.isNotEmpty ||
        _facilityFilter != null ||
        _dateRange != null;

    // Check if PIN verification is required
    if (pinProvider.hasPinSet && !pinProvider.isPinVerified) {
      return _buildRecordsPinVerificationScreen(context, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My Health Records'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prov.error!,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => prov.loadMyRecords(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (prov.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No medical records yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Records will appear here when a\nhealthcare provider adds them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final allRecords = prov.records.reversed.toList();
          final filtered = _applyFilters(allRecords);
          final facilities = _uniqueFacilities(prov.records);

          return RefreshIndicator(
            onRefresh: () => prov.loadMyRecords(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Search bar ──
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: theme.colorScheme.primary.withAlpha(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: 8),

                // ── Filter chips ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date range chip
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            _dateRange != null
                                ? '${_fmtChipDate(_dateRange!.start)} – ${_fmtChipDate(_dateRange!.end)}'
                                : 'Date range',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _dateRange != null,
                          onSelected: (_) => _pickDateRange(),
                          onDeleted:
                              _dateRange != null
                                  ? () => setState(() => _dateRange = null)
                                  : null,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Facility chips
                      ...facilities.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: const Icon(Icons.local_hospital, size: 14),
                            label: Text(
                              f,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: _facilityFilter == f,
                            onSelected: (sel) {
                              setState(() => _facilityFilter = sel ? f : null);
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Header row with count + clear ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} of ${allRecords.length} record${allRecords.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (hasFilters)
                      TextButton.icon(
                        onPressed: _clearAllFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Filtered records ──
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No records match your filters',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((rec) => _PatientRecordCard(record: rec)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsPinVerificationScreen(
    BuildContext context,
    ThemeData theme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My Health Records'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_information_outlined,
                  size: 64,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Records Protected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your PIN to view your health records',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordsPinVerification(context),
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter PIN'),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRecordsPinVerification(BuildContext context) async {
    final pin = await PinEntryDialog.getPin(
      context,
      title: 'Enter Your PIN',
      message: 'Verify your identity to view records',
    );
    if (pin != null && pin.isNotEmpty && context.mounted) {
      final pinProvider = context.read<PinProvider>();
      final success = await pinProvider.verifyPin(pin);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pinProvider.error ?? 'Invalid PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PatientRecordCard extends StatelessWidget {
  final MedicalRecord record;
  const _PatientRecordCard({required this.record});

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.facilityName.isNotEmpty
                        ? record.facilityName
                        : 'Unknown Facility',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  _fmtDate(record.eventDate),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            if (record.providerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Dr. ${record.providerName}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const Divider(height: 20),
            if (record.details.isNotEmpty)
              _Field(label: 'Diagnosis', value: record.details),
            if (record.symptoms.isNotEmpty)
              _Field(label: 'Symptoms', value: record.symptoms),
            if (record.medication.isNotEmpty)
              _Field(label: 'Medication', value: record.medication),
            if (record.labTests.isNotEmpty)
              _Field(label: 'Lab Tests', value: record.labTests),
            if (record.notes.isNotEmpty)
              _Field(label: 'Notes', value: record.notes),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2: My QR Code
// ─────────────────────────────────────────────
class _MyQrCodeTab extends StatefulWidget {
  const _MyQrCodeTab();

  @override
  State<_MyQrCodeTab> createState() => _MyQrCodeTabState();
}

class _MyQrCodeTabState extends State<_MyQrCodeTab> {
  bool _busy = false;

  /// Build a professional PDF document with logo, patient info, and QR code.
  Future<Uint8List> _buildPdf(Patient patient) async {
    final pdf = pw.Document();

    // Load the logo from assets
    final logoData = await rootBundle.load('assets/icon/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Generate the QR code image
    final qrPainter = QrPainter(
      data: patient.qrCodeId,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF1A3C6D),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1A3C6D),
      ),
    );
    final qrImage = await qrPainter.toImageData(
      600,
      format: ui.ImageByteFormat.png,
    );
    final qrBytes = qrImage!.buffer.asUint8List();
    final qrPdfImage = pw.MemoryImage(qrBytes);

    final navy = PdfColor.fromHex('#1A3C6D');
    final orange = PdfColor.fromHex('#F58B1F');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            children: [
              // ── Header with logo and app name ──
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: pw.BoxDecoration(
                  color: navy,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 50, height: 50),
                    pw.SizedBox(width: 14),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BirthChain',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Secure Birth Record Management',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColor.fromHex('#B0C4DE'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // ── Title ──
              pw.Text(
                'Patient QR Code Card',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: navy,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(width: 60, height: 3, color: orange),
              pw.SizedBox(height: 24),

              // ── QR Code ──
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: navy, width: 2),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Image(qrPdfImage, width: 200, height: 200),
                    pw.SizedBox(height: 14),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EEF2F7'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        patient.qrCodeId,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: navy,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── Patient Information ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColor.fromHex('#DEE2E6')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Patient Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _pdfInfoRow('Full Name', patient.fullName),
                    if (patient.email.isNotEmpty)
                      _pdfInfoRow('Email', patient.email),
                    if (patient.phone.isNotEmpty)
                      _pdfInfoRow('Phone', patient.phone),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // ── Instructions ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF8F0'),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: orange.shade(.3)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: orange,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Instructions',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '• Present this QR code to your healthcare provider to access your birth records.\n'
                      '• Keep this document safe. It serves as your unique patient identifier.\n'
                      '• Do not share this QR code with unauthorized persons.',
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── Footer ──
              pw.Divider(color: PdfColor.fromHex('#DEE2E6')),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateFormat('MMMM d, yyyy – h:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#6C757D'),
                    ),
                  ),
                  pw.Text(
                    'BirthChain © ${DateTime.now().year}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#6C757D'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#6C757D'),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(Patient patient) async {
    setState(() => _busy = true);
    try {
      final pdfBytes = await _buildPdf(patient);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSave(Patient patient) async {
    setState(() => _busy = true);
    try {
      final pdfBytes = await _buildPdf(patient);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/BirthChain_QR_${patient.qrCodeId}.pdf');
      await file.writeAsBytes(pdfBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            backgroundColor: Colors.green.shade700,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleShare(Patient patient) async {
    setState(() => _busy = true);
    try {
      final pdfBytes = await _buildPdf(patient);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/BirthChain_QR_${patient.qrCodeId}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinProvider = context.watch<PinProvider>();

    // Check if PIN verification is required
    if (pinProvider.hasPinSet && !pinProvider.isPinVerified) {
      return _buildPinVerificationScreen(context, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My QR Code'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final patient = prov.currentClient;
          if (patient == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'QR Code not available',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => prov.loadMyRecords(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Show this QR code to your\nhealthcare provider',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                            QrImageView(
                              data: patient.qrCodeId,
                              version: QrVersions.auto,
                              size: 220,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: theme.colorScheme.primary,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                patient.qrCodeId,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.person,
                                label: patient.fullName,
                              ),
                              if (patient.email.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: patient.email,
                                ),
                              if (patient.phone.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: patient.phone,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Action buttons: Print, Save, Share ──
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.print_rounded,
                              label: 'Print',
                              color: theme.colorScheme.primary,
                              onTap: () => _handlePrint(patient),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.save_alt_rounded,
                              label: 'Save PDF',
                              color: AppTheme.accentOrange,
                              onTap: () => _handleSave(patient),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              color: Colors.green.shade600,
                              onTap: () => _handleShare(patient),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_busy)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinVerificationScreen(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My QR Code'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code Protected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your PIN to view your QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _showPinVerification(context),
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter PIN'),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPinVerification(BuildContext context) async {
    final pin = await PinEntryDialog.getPin(
      context,
      title: 'Enter Your PIN',
      message: 'Verify your identity to view QR code',
    );
    if (pin != null && pin.isNotEmpty && context.mounted) {
      final pinProvider = context.read<PinProvider>();
      final success = await pinProvider.verifyPin(pin);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pinProvider.error ?? 'Invalid PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Styled action button for the QR tab
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(22),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3: Patient Profile
// ─────────────────────────────────────────────
class _PatientProfileTab extends StatelessWidget {
  const _PatientProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My Profile'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (auth.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.name ?? 'Patient',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Patient details from loaded client
          Consumer<RecordProvider>(
            builder: (_, prov, __) {
              final p = prov.currentClient;
              if (p == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        if (p.email.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Email'),
                            subtitle: Text(p.email),
                          ),
                        if (p.phone.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Phone'),
                            subtitle: Text(p.phone),
                          ),
                        if (p.gender.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.wc_outlined),
                            title: const Text('Gender'),
                            subtitle: Text(p.gender),
                          ),
                        if (p.address.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text('Address'),
                            subtitle: Text(p.address),
                          ),
                        if (p.dateOfBirth.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.calendar_today_outlined),
                            title: const Text('Date of Birth'),
                            subtitle: Text(_fmtDob(p.dateOfBirth)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // PIN Security section
          const PinSetupWidget(),
          const SizedBox(height: 24),

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
    );
  }

  static String _fmtDob(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
