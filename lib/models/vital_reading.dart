import 'package:cloud_firestore/cloud_firestore.dart';

class VitalReading {
  final String id;
  final String patientId;
  final double? systolicBP;
  final double? diastolicBP;
  final double? sugarLevel;
  final DateTime recordedAt;
  final String? notes;

  VitalReading({
    required this.id,
    required this.patientId,
    this.systolicBP,
    this.diastolicBP,
    this.sugarLevel,
    required this.recordedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'sugarLevel': sugarLevel,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'notes': notes,
    };
  }

  factory VitalReading.fromMap(String id, Map<String, dynamic> map) {
    return VitalReading(
      id: id,
      patientId: map['patientId'] ?? '',
      systolicBP: map['systolicBP']?.toDouble(),
      diastolicBP: map['diastolicBP']?.toDouble(),
      sugarLevel: map['sugarLevel']?.toDouble(),
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      notes: map['notes'],
    );
  }

  factory VitalReading.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VitalReading.fromMap(doc.id, data);
  }
}
