import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../domain/record_models.dart';
import 'record_provider.dart';
import 'record_type_helper.dart';

/// Standalone record list — kept for direct navigation if needed.
class RecordListScreen extends StatelessWidget {
  final String clientId;
  final String clientName;

  const RecordListScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecordProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('$clientName — Records')),
      body:
          prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.records.isEmpty
              ? Center(
                child: Text(
                  'No records found.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: prov.records.length,
                itemBuilder: (_, i) => _RecordTile(record: prov.records[i]),
              ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final MedicalRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final info = RecordTypeHelper.getInfo(record.recordType);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: info.color.withAlpha(25),
          child: Icon(info.icon, color: info.color, size: 20),
        ),
        title: Text(
          record.recordType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          record.details,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          DateFormatter.formatDate(record.eventDate),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}
