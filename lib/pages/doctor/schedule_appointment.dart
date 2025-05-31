// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ScheduleAppointment extends StatefulWidget {
//   const ScheduleAppointment({super.key});

//   @override
//   State<ScheduleAppointment> createState() => _ScheduleAppointmentState();
// }

// class _ScheduleAppointmentState extends State<ScheduleAppointment> {
//   final _formKey = GlobalKey<FormState>();
//   String? _selectedPatientId;
//   DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
//   String? _selectedAppointmentType;
//   final _notesController = TextEditingController();
  
//   bool _isLoading = false;
//   bool _patientsLoading = false;
//   String? _errorMessage;
  
//   List<Map<String, dynamic>> _patients = [];
  
//   final List<String> _appointmentTypes = [
//     'Initial Consultation',
//     'Follow-up',
//     'Check-up',
//     'Emergency',
//     'Procedure',
//     'Vaccination',
//     'Other'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadPatients();
//   }

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   void _loadPatients() {
//     setState(() {
//       _patientsLoading = true;
//     });

//     // Mock patient data
//     Future.delayed(const Duration(milliseconds: 500), () {
//       setState(() {
//         _patients = [
//           {'id': 'pat1', 'name': 'John Doe'},
//           {'id': 'pat2', 'name': 'Jane Smith'},
//           {'id': 'pat3', 'name': 'Robert Johnson'},
//           {'id': 'pat4', 'name': 'Emily Davis'},
//           {'id': 'pat5', 'name': 'Michael Brown'},
//         ];
//         _patientsLoading = false;
//       });
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime,
//     );
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//       });
//     }
//   }

//   void _scheduleAppointment() {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedPatientId == null) {
//       setState(() {
//         _errorMessage = 'Please select a patient';
//       });
//       return;
//     }
//     if (_selectedAppointmentType == null) {
//       setState(() {
//         _errorMessage = 'Please select an appointment type';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     // Simulate appointment scheduling
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Appointment scheduled successfully'),
//         ),
//       );
      
//       Navigator.pop(context);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Schedule Appointment'),
//       ),
//       body: _patientsLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Schedule a new appointment',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     DropdownButtonFormField<String>(
//                       decoration: const InputDecoration(
//                         labelText: 'Select Patient',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.person),
//                       ),
//                       value: _selectedPatientId,
//                       items: _patients.map((patient) {
//                         return DropdownMenuItem(
//                           value: patient['id'],
//                           child: Text(patient['name']),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedPatientId = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: InkWell(
//                             onTap: () => _selectDate(context),
//                             child: InputDecorator(
//                               decoration: const InputDecoration(
//                                 labelText: 'Date',
//                                 border: OutlineInputBorder(),
//                                 prefixIcon: Icon(Icons.calendar_today),
//                               ),
//                               child: Text(
//                                 DateFormat('MMM dd, yyyy').format(_selectedDate),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: InkWell(
//                             onTap: () => _selectTime(context),
//                             child: InputDecorator(
//                               decoration: const InputDecoration(
//                                 labelText: 'Time',
//                                 border: OutlineInputBorder(),
//                                 prefixIcon: Icon(Icons.access_time),
//                               ),
//                               child: Text(
//                                 _selectedTime.format(context),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       decoration: const InputDecoration(
//                         labelText: 'Appointment Type',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.medical_services),
//                       ),
//                       value: _selectedAppointmentType,
//                       items: _appointmentTypes.map((type) {
//                         return DropdownMenuItem(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedAppointmentType = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _notesController,
//                       decoration: const InputDecoration(
//                         labelText: 'Notes',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.note),
//                         alignLabelWithHint: true,
//                       ),
//                       maxLines: 3,
//                     ),
//                     if (_errorMessage != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 16.0),
//                         child: Text(
//                           _errorMessage!,
//                           style: const TextStyle(
//                             color: Colors.red,
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _scheduleAppointment,
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Text('Schedule Appointment'),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

