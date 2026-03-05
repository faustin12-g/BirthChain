import 'package:flutter/material.dart';

class RecordTypeHelper {
  static const types = [
    'Diagnosis',
    'Medication',
    'Vaccination',
    'Lab Result',
    'Procedure',
    'Other',
  ];

  static ({IconData icon, Color color}) getInfo(String type) {
    switch (type) {
      case 'Diagnosis':
        return (icon: Icons.medical_services, color: const Color(0xFFE53935));
      case 'Medication':
        return (icon: Icons.medication, color: const Color(0xFFF57C00));
      case 'Vaccination':
        return (icon: Icons.vaccines, color: const Color(0xFF43A047));
      case 'Lab Result':
        return (icon: Icons.science, color: const Color(0xFF1E88E5));
      case 'Procedure':
        return (icon: Icons.healing, color: const Color(0xFF8E24AA));
      default:
        return (icon: Icons.description, color: const Color(0xFF757575));
    }
  }
}
