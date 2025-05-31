class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String appointmentTime;
  final String? appointmentType;
  final String? notes;
  final String status;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.appointmentTime,
    this.appointmentType,
    this.notes,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      patientName: json['patients']['name'],
      appointmentTime: json['appointment_time'],
      appointmentType: json['appointment_type'],
      notes: json['notes'],
      status: json['status'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'appointment_time': appointmentTime,
      'appointment_type': appointmentType,
      'notes': notes,
      'status': status,
    };
  }
}

