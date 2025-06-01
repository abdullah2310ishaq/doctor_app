// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class PatientProfilePage extends StatefulWidget {
//   const PatientProfilePage({super.key});

//   @override
//   State<PatientProfilePage> createState() => _PatientProfilePageState();
// }

// class _PatientProfilePageState extends State<PatientProfilePage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   Map<String, dynamic>? _patientData;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPatientProfile();
//   }

//   void _loadPatientProfile() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     try {
//       final doc = await _firestore.collection('patients').doc(user.uid).get();
//       if (doc.exists) {
//         setState(() {
//           _patientData = doc.data();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading patient profile: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // Helper method to safely convert any data type to string
//   String _safeToString(dynamic value) {
//     if (value == null) return 'Not provided';
//     if (value is String) return value.isEmpty ? 'Not provided' : value;
//     if (value is List) {
//       if (value.isEmpty) return 'None';
//       return value.join(', ');
//     }
//     if (value is Map) {
//       return value.toString();
//     }
//     return value.toString();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Profile'),
//         backgroundColor: Colors.blue[50],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _patientData == null
//               ? const Center(child: Text('No profile data found'))
//               : SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Profile Header
//                       _buildProfileHeader(),
//                       const SizedBox(height: 24),
                      
//                       // Personal Information
//                       _buildPersonalInfo(),
//                       const SizedBox(height: 24),
                      
//                       // Medical Information
//                       _buildMedicalInfo(),
//                       const SizedBox(height: 24),
                      
//                       // Emergency Contact
//                       _buildEmergencyContact(),
//                       const SizedBox(height: 24),
                      
//                       // Recent Activity
//                       _buildRecentActivity(),
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     final fullName = _safeToString(_patientData!['fullName']);
//     final email = _safeToString(_patientData!['email']);
//     final profileCompleted = _patientData!['profileCompleted'] as bool? ?? false;
    
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 40,
//               backgroundColor: Colors.blue[100],
//               child: Text(
//                 fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'P',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue[800],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     fullName,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     email,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: profileCompleted
//                           ? Colors.green[100]
//                           : Colors.orange[100],
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       profileCompleted
//                           ? 'Profile Complete'
//                           : 'Profile Incomplete',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: profileCompleted
//                             ? Colors.green[800]
//                             : Colors.orange[800],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPersonalInfo() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Personal Information',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow('Date of Birth', _safeToString(_patientData!['dateOfBirth'])),
//             _buildInfoRow('Gender', _safeToString(_patientData!['gender'])),
//             _buildInfoRow('Phone', _safeToString(_patientData!['phone'])),
//             _buildInfoRow('Address', _safeToString(_patientData!['address'])),
//             _buildInfoRow('Blood Group', _safeToString(_patientData!['bloodGroup'])),
//             _buildInfoRow('Height', _safeToString(_patientData!['height'])),
//             _buildInfoRow('Weight', _safeToString(_patientData!['weight'])),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMedicalInfo() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Medical Information',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow('Medical History', _safeToString(_patientData!['medicalHistory'])),
//             _buildInfoRow('Current Medications', _safeToString(_patientData!['currentMedications'])),
//             _buildInfoRow('Allergies', _safeToString(_patientData!['allergies'])),
//             _buildInfoRow('Chronic Conditions', _safeToString(_patientData!['chronicConditions'])),
//             _buildInfoRow('Previous Surgeries', _safeToString(_patientData!['previousSurgeries'])),
//             _buildInfoRow('Family Medical History', _safeToString(_patientData!['familyMedicalHistory'])),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmergencyContact() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Emergency Contact',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow('Contact Name', _safeToString(_patientData!['emergencyContactName'])),
//             _buildInfoRow('Relationship', _safeToString(_patientData!['emergencyContactRelationship'])),
//             _buildInfoRow('Phone Number', _safeToString(_patientData!['emergencyContactPhone'])),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivity() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Activity',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Recent Prescriptions
//             StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('prescriptions')
//                   .where('patientId', isEqualTo: _auth.currentUser?.uid)
//                   .orderBy('createdAt', descending: true)
//                   .limit(3)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Text('No recent prescriptions');
//                 }
                
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Recent Prescriptions:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     ...snapshot.data!.docs.map((doc) {
//                       final data = doc.data() as Map<String, dynamic>;
//                       try {
//                         final date = DateTime.parse(data['date']);
//                         final medications = data['medications'] as List? ?? [];
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 4.0),
//                           child: Text(
//                             '• ${DateFormat('MMM dd, yyyy').format(date)} - ${medications.length} medications',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                         );
//                       } catch (e) {
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 4.0),
//                           child: Text(
//                             '• Prescription record',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                         );
//                       }
//                     }).toList(),
//                   ],
//                 );
//               },
//             ),
            
//             const SizedBox(height: 16),
            
//             // Recent Diet Plans
//             StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('diet_plans')
//                   .where('patientId', isEqualTo: _auth.currentUser?.uid)
//                   .orderBy('createdAt', descending: true)
//                   .limit(3)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Text('No recent diet plans');
//                 }
                
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Recent Diet Plans:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     ...snapshot.data!.docs.map((doc) {
//                       final data = doc.data() as Map<String, dynamic>;
//                       try {
//                         final startDate = DateTime.parse(data['startDate']);
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 4.0),
//                           child: Text(
//                             '• ${DateFormat('MMM dd, yyyy').format(startDate)} - Diet plan created',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                         );
//                       } catch (e) {
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 4.0),
//                           child: Text(
//                             '• Diet plan record',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                         );
//                       }
//                     }).toList(),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
