import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/logout_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email ?? '';
          _isLoading = false;
        });
        final doctorDoc =
            await _firestore.collection('doctors').doc(user.uid).get();
        if (doctorDoc.exists) {
          final data = doctorDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = data['fullName'] ?? 'Doctor';
            _userRole = 'Doctor';
          });
        } else {
          final patientDoc =
              await _firestore.collection('patients').doc(user.uid).get();
          if (patientDoc.exists) {
            final data = patientDoc.data() as Map<String, dynamic>;
            setState(() {
              _userName = data['fullName'] ?? 'Patient';
              _userRole = 'Patient';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileUpdateDialog() {
    String? selectedBloodGroup;
    final bloodGroups = [
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
      'Unknown'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Blood Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please select your blood group:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: bloodGroups.map((String bloodGroup) {
                  return DropdownMenuItem<String>(
                    value: bloodGroup,
                    child: Text(bloodGroup),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBloodGroup = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select blood group';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedBloodGroup != null) {
                  final user = _auth.currentUser;
                  if (user != null) {
                    try {
                      await _firestore
                          .collection('patients')
                          .doc(user.uid)
                          .update({
                        'bloodGroup': selectedBloodGroup,
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Blood group updated to $selectedBloodGroup'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating blood group: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String roleMessage = '';
    String islamicMessage = '';
    IconData roleIcon = Icons.person;
    Color roleColor = Colors.blue[700]!;

    if (_userRole == 'Doctor') {
      roleMessage = 'You are logged in as a Doctor.';
      islamicMessage =
          '"Whoever saves one [life] - it is as if he had saved mankind entirely."\n(Qur’an 5:32)';
      roleIcon = Icons.medical_services;
      roleColor = Colors.blue[800]!;
    } else if (_userRole == 'Patient') {
      roleMessage = 'You are logged in as a Patient.';
      islamicMessage =
          '"And when I am ill, it is He (Allah) who cures me."\n(Qur’an 26:80)';
      roleIcon = Icons.person;
      roleColor = Colors.blue[700]!;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      roleIcon,
                      color: roleColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userRole,
                      style: TextStyle(
                          fontSize: 13,
                          color: roleColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    roleMessage,
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      islamicMessage,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  if (_userRole == 'Patient') ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.bloodtype, color: Colors.red[700]),
                        title: const Text('Update Blood Group'),
                        subtitle: const Text('Change your blood group'),
                        onTap: () {
                          _showProfileUpdateDialog();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  LogoutButton(
                    customText: 'Sign Out',
                    customIcon: Icons.logout_rounded,
                    backgroundColor: Colors.red[600],
                    onLogoutComplete: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
