// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../../services/notification_service.dart';
// import 'comprehensive_patient_detials.dart';

// class AppointmentManagementPage extends StatefulWidget {
//   const AppointmentManagementPage({super.key});

//   @override
//   State<AppointmentManagementPage> createState() =>
//       _AppointmentManagementPageState();
// }

// class _AppointmentManagementPageState extends State<AppointmentManagementPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   String _selectedStatus = 'All';
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   bool _isLoading = false;

//   final List<String> _statusFilters = [
//     'All',
//     'pending',
//     'confirmed',
//     'cancelled',
//     'completed',
//   ];

//   @override
//   void initState() {
//     super.initState();
//   }

//   bool isSameDay(DateTime? a, DateTime? b) {
//     if (a == null || b == null) return false;
//     return a.year == b.year && a.month == b.month && a.day == b.day;
//   }

//   Future<void> _updateAppointmentStatus(
//       String appointmentId, String newStatus) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get appointment details
//       final appointmentDoc =
//           await _firestore.collection('appointments').doc(appointmentId).get();
//       if (!appointmentDoc.exists) return;

//       final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
//       final patientId = appointmentData['patientId'];
//       final patientName = appointmentData['patientName'];

//       // Handle different date formats
//       DateTime appointmentTime;
//       final timeData = appointmentData['appointmentTime'];
//       if (timeData is Timestamp) {
//         appointmentTime = timeData.toDate();
//       } else if (timeData is String) {
//         appointmentTime = DateTime.parse(timeData);
//       } else {
//         appointmentTime = DateTime.now();
//       }

//       // Update appointment status
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': newStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       // Create notification for patient
//       await NotificationService.createAppointmentStatusNotification(
//         patientId: patientId,
//         doctorName: user.displayName ?? 'Doctor',
//         appointmentId: appointmentId,
//         status: newStatus,
//         appointmentTime: appointmentTime,
//       );

//       if (!mounted) return;
//       _showSnackBar(
//         'Appointment status updated to ${newStatus.toUpperCase()}',
//         Colors.green,
//       );

//       // Haptic feedback
//       HapticFeedback.lightImpact();
//     } catch (e) {
//       if (!mounted) return;
//       _showSnackBar('Error updating appointment status: $e', Colors.red);
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
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'confirmed':
//         return Colors.blue[600]!;
//       case 'cancelled':
//         return Colors.red;
//       case 'completed':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Icons.schedule;
//       case 'confirmed':
//         return Icons.check_circle;
//       case 'cancelled':
//         return Icons.cancel;
//       case 'completed':
//         return Icons.done_all;
//       default:
//         return Icons.info;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = _auth.currentUser;
//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please log in again')),
//       );
//     }

//     final isSmallScreen = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue[50]!,
//               Colors.white,
//             ],
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Column(
//               children: [
//                 // Calendar View
//                 Container(
//                   margin: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: TableCalendar(
//                     firstDay: DateTime.utc(2020, 1, 1),
//                     lastDay: DateTime.utc(2100, 12, 31),
//                     focusedDay: _focusedDay,
//                     selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                     onDaySelected: (selectedDay, focusedDay) {
//                       setState(() {
//                         _selectedDay = selectedDay;
//                         _focusedDay = focusedDay;
//                       });
//                     },
//                     calendarStyle: CalendarStyle(
//                       todayDecoration: BoxDecoration(
//                         color: Colors.blue[200],
//                         shape: BoxShape.circle,
//                       ),
//                       selectedDecoration: BoxDecoration(
//                         color: Colors.blue[700],
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     headerStyle: HeaderStyle(
//                       formatButtonVisible: false,
//                       titleCentered: true,
//                       titleTextStyle: TextStyle(
//                         color: Colors.blue[900],
//                         fontWeight: FontWeight.bold,
//                         fontSize: isSmallScreen ? 16 : 18,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Status Filter
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.filter_list,
//                               color: Colors.blue[700], size: 20),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Filter by Status',
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 16 : 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: _statusFilters
//                             .map((status) => FilterChip(
//                                   label: Text(
//                                     status == 'All'
//                                         ? 'All'
//                                         : status.toUpperCase(),
//                                     style: TextStyle(
//                                       color: _selectedStatus == status
//                                           ? Colors.white
//                                           : Colors.blue[700],
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: isSmallScreen ? 12 : 14,
//                                     ),
//                                   ),
//                                   selected: _selectedStatus == status,
//                                   onSelected: (selected) {
//                                     setState(() {
//                                       _selectedStatus = status;
//                                     });
//                                   },
//                                   backgroundColor: Colors.blue[50],
//                                   selectedColor: Colors.blue[700],
//                                   checkmarkColor: Colors.white,
//                                   side: BorderSide(
//                                     color: _selectedStatus == status
//                                         ? Colors.blue[700]!
//                                         : Colors.blue[200]!,
//                                     width: 1,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                 ))
//                             .toList(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 // Appointments List
//                 SizedBox(
//                   height: MediaQuery.of(context).size.height * 0.7,
//                   child: _buildAppointmentsList(user.uid, isSmallScreen),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppointmentsList(String doctorId, bool isSmallScreen) {
//     Query query = _firestore
//         .collection('appointments')
//         .where('doctorId', isEqualTo: doctorId)
//         .orderBy('appointmentTime', descending: false);

//     if (_selectedStatus != 'All') {
//       query = query.where('status', isEqualTo: _selectedStatus);
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: Colors.blue),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error loading appointments',
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => setState(() {}),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No appointments found',
//                   style: const TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _selectedStatus == 'All'
//                       ? 'Appointments will appear here when patients book them'
//                       : 'No ${_selectedStatus.toLowerCase()} appointments',
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           );
//         }

//         // Filter by selected day if any
//         final docs = _selectedDay == null
//             ? snapshot.data!.docs
//             : snapshot.data!.docs.where((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 final timeData = data['appointmentTime'];
//                 DateTime appointmentTime;

//                 if (timeData is Timestamp) {
//                   appointmentTime = timeData.toDate();
//                 } else if (timeData is String) {
//                   appointmentTime = DateTime.parse(timeData);
//                 } else {
//                   appointmentTime = DateTime.now();
//                 }

//                 return isSameDay(appointmentTime, _selectedDay);
//               }).toList();

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           itemCount: docs.length,
//           itemBuilder: (context, index) {
//             final doc = docs[index];
//             final data = doc.data() as Map<String, dynamic>;
//             return GestureDetector(
//               onTap: () {
//                 final patientId = data['patientId'] ?? '';
//                 final patientName = data['patientName'] ?? '';
//                 if (patientId.isNotEmpty) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ComprehensivePatientDetails(
//                         patientId: patientId,
//                         patientName: patientName,
//                       ),
//                     ),
//                   );
//                 }
//               },
//               child: _buildAppointmentCard(doc.id, data, isSmallScreen),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildAppointmentCard(
//       String appointmentId, Map<String, dynamic> data, bool isSmallScreen) {
//     // Handle different date formats
//     DateTime appointmentTime;
//     final timeData = data['appointmentTime'];
//     if (timeData is Timestamp) {
//       appointmentTime = timeData.toDate();
//     } else if (timeData is String) {
//       try {
//         appointmentTime = DateTime.parse(timeData);
//       } catch (_) {
//         appointmentTime = DateTime.now();
//       }
//     } else {
//       appointmentTime = DateTime.now();
//     }

//     final status = data['status'] ?? 'pending';
//     final patientName = data['patientName'] ?? 'Unknown Patient';
//     final appointmentType = data['appointmentType'] ?? 'Consultation';
//     final duration = data['duration'] ?? '30 minutes';
//     final notes = data['notes'] ?? '';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with patient info and status
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: isSmallScreen ? 40 : 50,
//                   height: isSmallScreen ? 40 : 50,
//                   decoration: BoxDecoration(
//                     color: Colors.blue[100],
//                     borderRadius:
//                         BorderRadius.circular(isSmallScreen ? 20 : 25),
//                   ),
//                   child: Icon(
//                     Icons.person,
//                     color: Colors.blue[700],
//                     size: isSmallScreen ? 20 : 24,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         patientName,
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 16 : 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         appointmentType,
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 12 : 14,
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.w500,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   constraints: const BoxConstraints(maxWidth: 90),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(status).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: _getStatusColor(status)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         _getStatusIcon(status),
//                         color: _getStatusColor(status),
//                         size: isSmallScreen ? 12 : 14,
//                       ),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           status.toUpperCase(),
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 10 : 12,
//                             fontWeight: FontWeight.bold,
//                             color: _getStatusColor(status),
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Appointment details
//             Wrap(
//               spacing: 16,
//               runSpacing: 8,
//               children: [
//                 _buildDetailItem(
//                   Icons.calendar_today,
//                   DateFormat('MMM dd, yyyy, h:mm a').format(appointmentTime),
//                   isSmallScreen,
//                 ),
//                 _buildDetailItem(
//                   Icons.timer,
//                   duration,
//                   isSmallScreen,
//                 ),
//               ],
//             ),

//             // Notes section
//             if (notes.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[200] ?? Colors.grey),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.note, size: 16, color: Colors.grey[600]),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Patient Notes',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 12 : 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       notes,
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 12 : 14,
//                         color: Colors.grey[600],
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             const SizedBox(height: 12),

//             // Action buttons
//             if (status == 'pending') ...[
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () =>
//                           _updateAppointmentStatus(appointmentId, 'confirmed'),
//                       icon: const Icon(Icons.check_circle_outline, size: 16),
//                       label: const Text('Confirm'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.green,
//                         side: BorderSide(color: Colors.green),
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () =>
//                           _updateAppointmentStatus(appointmentId, 'cancelled'),
//                       icon: const Icon(Icons.cancel_outlined, size: 16),
//                       label: const Text('Cancel'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: BorderSide(color: Colors.red),
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ] else if (status == 'confirmed') ...[
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: () =>
//                       _updateAppointmentStatus(appointmentId, 'completed'),
//                   icon: const Icon(Icons.done_all, size: 16),
//                   label: const Text('Mark Complete'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailItem(IconData icon, String text, bool isSmallScreen) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 12 : 14,
//             color: Colors.grey[700],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }
