class Prescription {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String date;
  final List<Medication> medications;
  final String? instructions;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.medications,
    this.instructions,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    List<Medication> meds = [];
    if (json['medications'] != null) {
      meds = (json['medications'] as List)
          .map((med) => Medication.fromJson(med))
          .toList();
    }

    return Prescription(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? json['doctorId'] ?? '',
      patientId: json['patient_id'] ?? json['patientId'] ?? '',
      patientName:
          json['patientName'] ?? json['patients']?['name'] ?? 'Unknown Patient',
      date: json['date'] ?? '',
      medications: meds,
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'date': date,
      'medications': medications.map((med) => med.toJson()).toList(),
      'instructions': instructions,
    };
  }
}

class MedicationLog {
  final String medicationName;
  final DateTime date;
  final String time; // e.g., '08:00'
  final bool taken;
  final String? notes;

  MedicationLog({
    required this.medicationName,
    required this.date,
    required this.time,
    required this.taken,
    this.notes,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      medicationName: json['medicationName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: json['time'] ?? '',
      taken: json['taken'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'date': date.toIso8601String(),
      'time': time,
      'taken': taken,
      'notes': notes,
    };
  }
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;
  final List<String>? times; // e.g., ['08:00', '14:00']

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
    this.times,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<String>? timesList;
    if (json['times'] != null) {
      timesList = List<String>.from(json['times']);
    }
    return Medication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      notes: json['notes'],
      times: timesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'notes': notes,
      'times': times,
    };
  }
}
