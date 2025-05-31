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
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      patientName: json['patients']['name'],
      date: json['date'],
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

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'notes': notes,
    };
  }
}

