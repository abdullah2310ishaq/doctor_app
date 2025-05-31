// import 'package:flutter/material.dart';
// import 'package:doctor_app/main.dart';
// import 'package:doctor_app/models/appointment.dart';
// import 'package:doctor_app/models/prescription.dart';
// import 'package:doctor_app/models/diet_plan.dart';
// import 'package:intl/intl.dart';

// class PatientDetail extends StatefulWidget {
//   final String patientId;
//   final String patientName;

//   const PatientDetail({
//     super.key,
//     required this.patientId,
//     required this.patientName,
//   });

//   @override
//   State<PatientDetail> createState() => _PatientDetailState();
// }

// class _PatientDetailState extends State<PatientDetail>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   Map<String, dynamic>? _patientData;
//   List<Appointment> _appointments = [];
//   List<Prescription> _prescriptions = [];
//   List<DietPlan> _dietPlans = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _loadPatientData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPatientData() async {
//     try {
//       // Load patient details
//       final patientData = await supabase
//           .from('patients')
//           .select()
//           .eq('id', widget.patientId)
//           .single();

//       // Load appointments
//       final appointmentsData = await supabase
//           .from('appointments')
//           .select('*, patients(*)')
//           .eq('patient_id', widget.patientId)
//           .order('appointment_time', ascending: false);

//       // Load prescriptions
//       final prescriptionsData = await supabase
//           .from('prescriptions')
//           .select('*, patients(*)')
//           .eq('patient_id', widget.patientId)
//           .order('date', ascending: false);

//       // Load diet plans
//       final dietPlansData = await supabase
//           .from('diet_plans')
//           .select('*, patients(*)')
//           .eq('patient_id', widget.patientId)
//           .order('start_date', ascending: false);

//       if (mounted) {
//         setState(() {
//           _patientData = patientData;
//           _appointments = (appointmentsData as List)
//               .map((item) => Appointment.fromJson(item))
//               .toList();
//           _prescriptions = (prescriptionsData as List)
//               .map((item) => Prescription.fromJson(item))
//               .toList();
//           _dietPlans = (dietPlansData as List)
//               .map((item) => DietPlan.fromJson(item))
//               .toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to load patient data'),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.patientName),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Profile'),
//             Tab(text: 'Appointments'),
//             Tab(text: 'Prescriptions'),
//             Tab(text: 'Diet Plans'),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildProfileTab(),
//                 _buildAppointmentsTab(),
//                 _buildPrescriptionsTab(),
//                 _buildDietPlansTab(),
//               ],
//             ),
//     );
//   }

//   Widget _buildProfileTab() {
//     if (_patientData == null) {
//       return const Center(
//         child: Text('No patient data available'),
//       );
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Personal Information',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildInfoRow('Name', _patientData!['name']),
//                   _buildInfoRow('Age', _patientData!['age'].toString()),
//                   _buildInfoRow('Gender', _patientData!['gender']),
//                   _buildInfoRow('Phone', _patientData!['phone']),
//                   if (_patientData!['email'] != null)
//                     _buildInfoRow('Email', _patientData!['email']),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Medical History',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   if (_patientData!['medical_history'] != null &&
//                       _patientData!['medical_history'].isNotEmpty)
//                     Text(_patientData!['medical_history'])
//                   else
//                     const Text(
//                       'No medical history available',
//                       style: TextStyle(
//                         color: Colors.grey,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Patient Summary',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSummaryRow(
//                       'Appointments', _appointments.length.toString()),
//                   _buildSummaryRow(
//                       'Prescriptions', _prescriptions.length.toString()),
//                   _buildSummaryRow('Diet Plans', _dietPlans.length.toString()),
//                   _buildSummaryRow(
//                     'Last Visit',
//                     _appointments.isNotEmpty
//                         ? DateFormat('MMM dd, yyyy').format(
//                             DateTime.parse(_appointments.first.appointmentTime))
//                         : 'No visits yet',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppointmentsTab() {
//     if (_appointments.isEmpty) {
//       return const Center(
//         child: Text('No appointments available'),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16.0),
//       itemCount: _appointments.length,
//       itemBuilder: (context, index) {
//         final appointment = _appointments[index];
//         final appointmentDate = DateTime.parse(appointment.appointmentTime);

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16.0),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       DateFormat('MMM dd, yyyy').format(appointmentDate),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: appointment.status == 'completed'
//                             ? Colors.green[100]
//                             : appointment.status == 'cancelled'
//                                 ? Colors.red[100]
//                                 : Colors.blue[100],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         appointment.status.toUpperCase(),
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: appointment.status == 'completed'
//                               ? Colors.green[800]
//                               : appointment.status == 'cancelled'
//                                   ? Colors.red[800]
//                                   : Colors.blue[800],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Time: ${DateFormat('hh:mm a').format(appointmentDate)}',
//                   style: const TextStyle(
//                     color: Colors.grey,
//                   ),
//                 ),
//                 if (appointment.appointmentType != null) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     'Type: ${appointment.appointmentType}',
//                     style: const TextStyle(
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//                 if (appointment.notes != null &&
//                     appointment.notes!.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Notes:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(appointment.notes!),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPrescriptionsTab() {
//     if (_prescriptions.isEmpty) {
//       return const Center(
//         child: Text('No prescriptions available'),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16.0),
//       itemCount: _prescriptions.length,
//       itemBuilder: (context, index) {
//         final prescription = _prescriptions[index];
//         final prescriptionDate = DateTime.parse(prescription.date);

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16.0),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Prescription - ${DateFormat('MMM dd, yyyy').format(prescriptionDate)}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Medications:',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 ...prescription.medications.map((medication) {
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           medication.name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text('Dosage: ${medication.dosage}'),
//                         Text('Frequency: ${medication.frequency}'),
//                         Text('Duration: ${medication.duration}'),
//                         if (medication.notes != null &&
//                             medication.notes!.isNotEmpty) ...[
//                           const SizedBox(height: 4),
//                           Text('Notes: ${medication.notes}'),
//                         ],
//                       ],
//                     ),
//                   );
//                 }).toList(),
//                 if (prescription.instructions != null &&
//                     prescription.instructions!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Instructions:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(prescription.instructions!),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDietPlansTab() {
//     if (_dietPlans.isEmpty) {
//       return const Center(
//         child: Text('No diet plans available'),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16.0),
//       itemCount: _dietPlans.length,
//       itemBuilder: (context, index) {
//         final dietPlan = _dietPlans[index];
//         final startDate = DateTime.parse(dietPlan.startDate);
//         final endDate =
//             dietPlan.endDate != null ? DateTime.parse(dietPlan.endDate!) : null;

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16.0),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Diet Plan - ${DateFormat('MMM dd, yyyy').format(startDate)}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Duration: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate) : 'Ongoing'}',
//                   style: const TextStyle(
//                     color: Colors.grey,
//                   ),
//                 ),
//                 if (dietPlan.restrictions != null &&
//                     dietPlan.restrictions!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Dietary Restrictions:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: dietPlan.restrictions!.map((restriction) {
//                       return Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange[100],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           restriction,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.orange[800],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Meals:',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 ...dietPlan.meals.map((meal) {
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Text(
//                               meal.type,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             if (meal.time != null && meal.time!.isNotEmpty) ...[
//                               const SizedBox(width: 8),
//                               Text(
//                                 '(${meal.time})',
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Text(meal.name),
//                         if (meal.description != null &&
//                             meal.description!.isNotEmpty)
//                           Text(meal.description!),
//                         if (meal.portionSize != null &&
//                             meal.portionSize!.isNotEmpty)
//                           Text('Portion: ${meal.portionSize}'),
//                         if (meal.ingredients != null &&
//                             meal.ingredients!.isNotEmpty) ...[
//                           const SizedBox(height: 4),
//                           const Text(
//                             'Ingredients:',
//                             style: TextStyle(
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                           ...meal.ingredients!.map((ingredient) {
//                             return Text('• $ingredient');
//                           }).toList(),
//                         ],
//                       ],
//                     ),
//                   );
//                 }).toList(),
//                 if (dietPlan.nutritionGuidelines != null &&
//                     dietPlan.nutritionGuidelines!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Nutrition Guidelines:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(dietPlan.nutritionGuidelines!),
//                 ],
//                 if (dietPlan.additionalInstructions != null &&
//                     dietPlan.additionalInstructions!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Additional Instructions:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(dietPlan.additionalInstructions!),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
