// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class PrescriptionPage extends StatefulWidget {
//   const PrescriptionPage({super.key});

//   @override
//   State<PrescriptionPage> createState() => _PrescriptionPageState();
// }

// class _PrescriptionPageState extends State<PrescriptionPage> {
//   final _formKey = GlobalKey<FormState>();
//   String? _selectedPatientId;
//   final _instructionsController = TextEditingController();
  
//   bool _isLoading = false;
//   bool _patientsLoading = false;
//   String? _errorMessage;
  
//   List<Map<String, dynamic>> _patients = [];
//   List<MedicationInput> _medications = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadPatients();
//     // Add initial medication input
//     _medications.add(MedicationInput());
//   }

//   @override
//   void dispose() {
//     _instructionsController.dispose();
//     for (var med in _medications) {
//       med.dispose();
//     }
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

//   void _addMedication() {
//     setState(() {
//       _medications.add(MedicationInput());
//     });
//   }

//   void _removeMedication(int index) {
//     if (_medications.length > 1) {
//       setState(() {
//         _medications[index].dispose();
//         _medications.removeAt(index);
//       });
//     }
//   }

//   void _savePrescription() {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedPatientId == null) {
//       setState(() {
//         _errorMessage = 'Please select a patient';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     // Simulate prescription saving
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Prescription saved successfully'),
//         ),
//       );
      
//       Navigator.pop(context);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Write Prescription'),
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
//                       'Create a new prescription',
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
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Medications',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ..._medications.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final medication = entry.value;
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 16),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'Medication ${index + 1}',
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   if (_medications.length > 1)
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, color: Colors.red),
//                                       onPressed: () => _removeMedication(index),
//                                     ),
//                                 ],
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: medication.nameController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Medication Name',
//                                   border: OutlineInputBorder(),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter medication name';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: TextFormField(
//                                       controller: medication.dosageController,
//                                       decoration: const InputDecoration(
//                                         labelText: 'Dosage',
//                                         border: OutlineInputBorder(),
//                                       ),
//                                       validator: (value) {
//                                         if (value == null || value.isEmpty) {
//                                           return 'Please enter dosage';
//                                         }
//                                         return null;
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: TextFormField(
//                                       controller: medication.frequencyController,
//                                       decoration: const InputDecoration(
//                                         labelText: 'Frequency',
//                                         border: OutlineInputBorder(),
//                                       ),
//                                       validator: (value) {
//                                         if (value == null || value.isEmpty) {
//                                           return 'Please enter frequency';
//                                         }
//                                         return null;
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: medication.durationController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Duration',
//                                   border: OutlineInputBorder(),
//                                 ),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter duration';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               TextFormField(
//                                 controller: medication.notesController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Notes (Optional)',
//                                   border: OutlineInputBorder(),
//                                   alignLabelWithHint: true,
//                                 ),
//                                 maxLines: 2,
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                     Center(
//                       child: ElevatedButton.icon(
//                         onPressed: _addMedication,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add Medication'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     TextFormField(
//                       controller: _instructionsController,
//                       decoration: const InputDecoration(
//                         labelText: 'Additional Instructions',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                       ),
//                       maxLines: 4,
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
//                         onPressed: _isLoading ? null : _savePrescription,
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
//                               : const Text('Save Prescription'),
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

// class MedicationInput {
//   final nameController = TextEditingController();
//   final dosageController = TextEditingController();
//   final frequencyController = TextEditingController();
//   final durationController = TextEditingController();
//   final notesController = TextEditingController();

//   void dispose() {
//     nameController.dispose();
//     dosageController.dispose();
//     frequencyController.dispose();
//     durationController.dispose();
//     notesController.dispose();
//   }
// }

