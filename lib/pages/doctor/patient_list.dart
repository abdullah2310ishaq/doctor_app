// import 'package:flutter/material.dart';
// import 'package:doctor_app/main.dart';
// import 'package:doctor_app/pages/doctor/schedule_appointment.dart';
// import 'package:doctor_app/pages/doctor/prescription_page.dart';
// import 'package:doctor_app/pages/doctor/diet_plan_page.dart';
// import 'package:doctor_app/pages/doctor/patient_detail.dart';

// class PatientList extends StatefulWidget {
//   const PatientList({super.key});

//   @override
//   State<PatientList> createState() => _PatientListState();
// }

// class _PatientListState extends State<PatientList> {
//   List<Map<String, dynamic>> _patients = [];
//   List<Map<String, dynamic>> _filteredPatients = [];
//   bool _isLoading = true;
//   final _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadPatients();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPatients() async {
//     try {
//       final doctorId = supabase.auth.currentUser!.id;
//       final data = await supabase.from('patients').select().order('name');

//       if (mounted) {
//         setState(() {
//           _patients = List<Map<String, dynamic>>.from(data);
//           _filteredPatients = _patients;
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
//             content: Text('Failed to load patients'),
//           ),
//         );
//       }
//     }
//   }

//   void _filterPatients(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredPatients = _patients;
//       } else {
//         _filteredPatients = _patients
//             .where((patient) => patient['name']
//                 .toString()
//                 .toLowerCase()
//                 .contains(query.toLowerCase()))
//             .toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient List'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: const InputDecoration(
//                       labelText: 'Search Patients',
//                       prefixIcon: Icon(Icons.search),
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: _filterPatients,
//                   ),
//                 ),
//                 Expanded(
//                   child: _filteredPatients.isEmpty
//                       ? const Center(
//                           child: Text(
//                             'No patients found',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         )
//                       : ListView.builder(
//                           itemCount: _filteredPatients.length,
//                           itemBuilder: (context, index) {
//                             final patient = _filteredPatients[index];
//                             return PatientCard(
//                               patient: patient,
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => PatientDetail(
//                                       patientId: patient['id'],
//                                       patientName: patient['name'],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

// class PatientCard extends StatelessWidget {
//   final Map<String, dynamic> patient;
//   final VoidCallback onTap;

//   const PatientCard({
//     super.key,
//     required this.patient,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.blue,
//                     child: Text(
//                       patient['name'][0].toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           patient['name'],
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Age: ${patient['age']} | Gender: ${patient['gender']}',
//                           style: const TextStyle(
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Icon(Icons.chevron_right),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _ActionButton(
//                     icon: Icons.calendar_today,
//                     label: 'Schedule',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const ScheduleAppointment(),
//                         ),
//                       );
//                     },
//                   ),
//                   _ActionButton(
//                     icon: Icons.medical_services,
//                     label: 'Prescribe',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const PrescriptionPage(),
//                         ),
//                       );
//                     },
//                   ),
//                   _ActionButton(
//                     icon: Icons.restaurant_menu,
//                     label: 'Diet Plan',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const DietPlanPage(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _ActionButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.blue),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
