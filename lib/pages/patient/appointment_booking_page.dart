// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import '../../services/notification_service.dart';

// class AppointmentBookingPage extends StatefulWidget {
//   final String doctorId;
//   final String doctorName;
//   final String doctorSpecialization;

//   const AppointmentBookingPage({
//     super.key,
//     required this.doctorId,
//     required this.doctorName,
//     required this.doctorSpecialization,
//   });

//   @override
//   State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
// }

// class _AppointmentBookingPageState extends State<AppointmentBookingPage>
//     with TickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
//   String _selectedAppointmentType = 'Consultation';
//   String _selectedDuration = '30 minutes';
//   final TextEditingController _notesController = TextEditingController();
//   bool _isLoading = false;

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   final List<String> _appointmentTypes = [
//     'Consultation',
//     'Follow-up',
//     'Emergency',
//     'Routine Check-up',
//     'Specialist Consultation',
//     'Telemedicine',
//   ];

//   final List<String> _durations = [
//     '15 minutes',
//     '30 minutes',
//     '45 minutes',
//     '1 hour',
//     '1.5 hours',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 90)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.teal[700]!,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _selectTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.teal[700]!,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//       });
//     }
//   }

//   Future<void> _bookAppointment() async {
//     if (!mounted) return;

//     final user = _auth.currentUser;
//     if (user == null) {
//       _showSnackBar('You must be logged in to book an appointment', Colors.red);
//       return;
//     }

//     // Check if the selected time is in the past
//     final appointmentDateTime = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//       _selectedTime.hour,
//       _selectedTime.minute,
//     );

//     if (appointmentDateTime.isBefore(DateTime.now())) {
//       _showSnackBar('Please select a future date and time', Colors.orange);
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Get patient name
//       final patientDoc =
//           await _firestore.collection('patients').doc(user.uid).get();
//       final patientName = patientDoc.exists
//           ? (patientDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Patient'
//           : 'Patient';

//       // Create appointment
//       final appointmentRef = await _firestore.collection('appointments').add({
//         'doctorId': widget.doctorId,
//         'patientId': user.uid,
//         'patientName': patientName,
//         'doctorName': widget.doctorName,
//         'doctorSpecialization': widget.doctorSpecialization,
//         'appointmentTime': appointmentDateTime.toIso8601String(),
//         'appointmentType': _selectedAppointmentType,
//         'duration': _selectedDuration,
//         'status': 'pending',
//         'notes': _notesController.text.trim(),
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       // Create notification for doctor
//       await NotificationService.createAppointmentNotification(
//         doctorId: widget.doctorId,
//         patientName: patientName,
//         appointmentId: appointmentRef.id,
//         appointmentTime: appointmentDateTime,
//       );

//       if (!mounted) return;

//       _showSnackBar(
//         'Appointment booked successfully with Dr. ${widget.doctorName}! 🎉',
//         Colors.green,
//       );

//       // Haptic feedback
//       HapticFeedback.lightImpact();

//       // Navigate back after a short delay
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           Navigator.pop(context);
//         }
//       });
//     } catch (e) {
//       if (!mounted) return;
//       _showSnackBar('Failed to book appointment: $e', Colors.red);
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               color == Colors.green ? Icons.check_circle : Icons.error_outline,
//               color: Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 message,
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         margin: const EdgeInsets.all(16),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.teal[50] ?? Colors.teal,
//               Colors.white,
//               Colors.teal[25] ?? Colors.teal,
//             ],
//             stops: const [0.0, 0.6, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Enhanced Header
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.teal[100] ?? Colors.teal,
//                       Colors.teal[50] ?? Colors.teal
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(32),
//                     bottomRight: Radius.circular(32),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.teal.withOpacity(0.15),
//                       blurRadius: 20,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           onTap: () => Navigator.pop(context),
//                           borderRadius: BorderRadius.circular(16),
//                           child: Container(
//                             padding: const EdgeInsets.all(12),
//                             child: Icon(Icons.arrow_back_ios_new,
//                                 color: Colors.teal[700], size: 20),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Book Appointment',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineSmall
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.teal[900],
//                                   fontSize: 24,
//                                 ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'with Dr. ${widget.doctorName}',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyMedium
//                                 ?.copyWith(
//                                   color: Colors.teal[700],
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         Icons.calendar_today,
//                         color: Colors.teal[700],
//                         size: 32,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(24),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Doctor Info Card
//                         _buildDoctorInfoCard(),
//                         const SizedBox(height: 24),

//                         // Date & Time Selection
//                         _buildDateTimeSection(),
//                         const SizedBox(height: 24),

//                         // Appointment Type Selection
//                         _buildAppointmentTypeSection(),
//                         const SizedBox(height: 24),

//                         // Duration Selection
//                         _buildDurationSection(),
//                         const SizedBox(height: 24),

//                         // Notes Section
//                         _buildNotesSection(),
//                         const SizedBox(height: 32),

//                         // Book Appointment Button
//                         _buildBookButton(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDoctorInfoCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.teal[100],
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Icon(
//               Icons.medical_services,
//               color: Colors.teal[700],
//               size: 40,
//             ),
//           ),
//           const SizedBox(width: 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Dr. ${widget.doctorName}',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   widget.doctorSpecialization,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(Icons.star,
//                         color: Colors.amber[600] ?? Colors.amber, size: 16),
//                     const SizedBox(width: 4),
//                     Text(
//                       '4.8 (120 reviews)',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateTimeSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.calendar_today, color: Colors.teal[700], size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Date & Time',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal[700],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildDateTimeButton(
//                   'Date',
//                   DateFormat('MMM dd, yyyy').format(_selectedDate),
//                   Icons.calendar_month,
//                   _selectDate,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildDateTimeButton(
//                   'Time',
//                   _selectedTime.format(context),
//                   Icons.access_time,
//                   _selectTime,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateTimeButton(
//       String label, String value, IconData icon, VoidCallback onTap) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[200] ?? Colors.grey),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Icon(icon, color: Colors.teal[600], size: 24),
//                 const SizedBox(height: 8),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppointmentTypeSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.medical_services, color: Colors.teal[700], size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Appointment Type',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal[700],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children: _appointmentTypes
//                 .map((type) => _buildSelectionChip(
//                       type,
//                       _selectedAppointmentType == type,
//                       (value) =>
//                           setState(() => _selectedAppointmentType = value),
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDurationSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.timer, color: Colors.teal[700], size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Duration',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal[700],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children: _durations
//                 .map((duration) => _buildSelectionChip(
//                       duration,
//                       _selectedDuration == duration,
//                       (value) => setState(() => _selectedDuration = value),
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSelectionChip(
//       String label, bool isSelected, Function(String) onSelected) {
//     return FilterChip(
//       label: Text(
//         label,
//         style: TextStyle(
//           color: isSelected ? Colors.white : Colors.teal[700],
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       selected: isSelected,
//       onSelected: (selected) => onSelected(label),
//       backgroundColor: Colors.teal[50],
//       selectedColor: Colors.teal[700],
//       checkmarkColor: Colors.white,
//       side: BorderSide(
//         color: isSelected
//             ? (Colors.teal[700] ?? Colors.teal)
//             : (Colors.teal[200] ?? Colors.teal),
//         width: 1,
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//     );
//   }

//   Widget _buildNotesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.note, color: Colors.teal[700], size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'Additional Notes (Optional)',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal[700],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _notesController,
//             maxLines: 4,
//             decoration: InputDecoration(
//               hintText: 'Describe your symptoms or any specific concerns...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: BorderSide(
//                     color: Colors.teal[700] ?? Colors.teal, width: 2),
//               ),
//               filled: true,
//               fillColor: Colors.grey[50],
//               contentPadding: const EdgeInsets.all(16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBookButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 60,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _bookAppointment,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.teal,
//           foregroundColor: Colors.white,
//           elevation: 6,
//           shadowColor: Colors.teal.withOpacity(0.4),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//         child: _isLoading
//             ? Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2.5,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   const Text(
//                     'Booking...',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.calendar_today, size: 24),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Book Appointment',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }
