import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_drivers/Model/api_config.dart';
import 'dart:convert';

import 'package:taskova_drivers/View/Homepage/admin_approval.dart';

class DocumentRegistrationPage extends StatefulWidget {
  const DocumentRegistrationPage({Key? key}) : super(key: key);

  @override
  State<DocumentRegistrationPage> createState() => _DocumentRegistrationPageState();
}

class _DocumentRegistrationPageState extends State<DocumentRegistrationPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isBritishCitizen = false;
  bool _isLoading = false;
  
  // Store image files
  File? _idFront;
  File? _idBack;
  File? _passportFront;
  File? _passportBack;
  File? _rightToWorkUKFront;
  File? _rightToWorkUKBack;
  File? _addressProofFront;
  File? _addressProofBack;
  File? _vehicleInsuranceFront;
  File? _vehicleInsuranceBack;
  File? _drivingLicenseFront;
  File? _drivingLicenseBack;

  // Function to pick image
  Future<File?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Function to upload document to the API
  Future<bool> _uploadDocument({
    required String documentType,
    required File frontImage,
    required File backImage,
  }) async {
    try {
      // Get access token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // Create multipart request
      final uri = Uri.parse(ApiConfig.driverDocumentUrl);
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $accessToken';
      
      // Add document type
      request.fields['document_type'] = documentType;
      
      // Add front image
      request.files.add(await http.MultipartFile.fromPath(
        'front_image',
        frontImage.path,
      ));
      
      // Add back image
      request.files.add(await http.MultipartFile.fromPath(
        'back_image',
        backImage.path,
      ));
      
      // Send request
      final response = await request.send();
      
      // Check response
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Document uploaded successfully: $documentType');
        return true;
      } else {
        final responseString = await response.stream.bytesToString();
        debugPrint('Failed to upload document: $documentType. Status: ${response.statusCode}, Body: $responseString');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return false;
    }
  }

  // Function to upload all documents
  Future<void> _submitAllDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload Proof of Identity
      bool success = await _uploadDocument(
        documentType: 'IDENTITY',
        frontImage: _idFront!,
        backImage: _idBack!,
      );
      
      if (!success) throw Exception('Failed to upload identity document');
      
      // Upload British Passport or Right to Work UK based on citizenship
      if (_isBritishCitizen) {
        success = await _uploadDocument(
          documentType: 'PASSPORT',
          frontImage: _passportFront!,
          backImage: _passportBack!,
        );
        if (!success) throw Exception('Failed to upload passport document');
      } else {
        success = await _uploadDocument(
          documentType: 'RIGHT_TO_WORK',
          frontImage: _rightToWorkUKFront!,
          backImage: _rightToWorkUKBack!,
        );
        if (!success) throw Exception('Failed to upload right to work document');
      }
      
      // Upload Proof of Address
      success = await _uploadDocument(
        documentType: 'ADDRESS',
        frontImage: _addressProofFront!,
        backImage: _addressProofBack!,
      );
      if (!success) throw Exception('Failed to upload address proof document');
      
      // Upload Vehicle Insurance
      success = await _uploadDocument(
        documentType: 'INSURANCE',
        frontImage: _vehicleInsuranceFront!,
        backImage: _vehicleInsuranceBack!,
      );
      if (!success) throw Exception('Failed to upload insurance document');
      
      // Upload Driving License
      success = await _uploadDocument(
        documentType: 'LICENSE',
        frontImage: _drivingLicenseFront!,
        backImage: _drivingLicenseBack!,
      );
      if (!success) throw Exception('Failed to upload driving license document');
      
      // All documents uploaded successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All documents submitted successfully!')),
      );
      
      // Navigate to the next screen or home screen
      // Navigator.of(context).pushReplacementNamed('/home');
      Navigator.push(context, MaterialPageRoute(builder: (context)=>DocumentVerificationPendingScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to upload document with front and back sides
  Widget _buildDocumentUpload({
    required String title,
    required File? frontFile,
    required File? backFile,
    required Function(File?) onFrontUploaded,
    required Function(File?) onBackUploaded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final file = await _pickImage();
                  if (file != null) {
                    onFrontUploaded(file);
                  }
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: frontFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            frontFile,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 32),
                              SizedBox(height: 4),
                              Text('Front Side'),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final file = await _pickImage();
                  if (file != null) {
                    onBackUploaded(file);
                  }
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: backFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            backFile,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 32),
                              SizedBox(height: 4),
                              Text('Back Side'),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Registration'),
        backgroundColor: Colors.blue[700],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please upload the following documents to complete your registration',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                // Proof of Identity
                _buildDocumentUpload(
                  title: 'Proof of Identity',
                  frontFile: _idFront,
                  backFile: _idBack,
                  onFrontUploaded: (file) {
                    setState(() {
                      _idFront = file;
                    });
                  },
                  onBackUploaded: (file) {
                    setState(() {
                      _idBack = file;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // British Citizen Toggle
                Row(
                  children: [
                    const Text(
                      'Are you a British Citizen?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isBritishCitizen,
                      onChanged: (value) {
                        setState(() {
                          _isBritishCitizen = value;
                        });
                      },
                      activeColor: Colors.blue[700],
                    ),
                  ],
                ),
                
                // Show British Passport or Right to Work UK based on citizenship
                if (_isBritishCitizen)
                  _buildDocumentUpload(
                    title: 'British Passport',
                    frontFile: _passportFront,
                    backFile: _passportBack,
                    onFrontUploaded: (file) {
                      setState(() {
                        _passportFront = file;
                      });
                    },
                    onBackUploaded: (file) {
                      setState(() {
                        _passportBack = file;
                      });
                    },
                  )
                else
                  _buildDocumentUpload(
                    title: 'Right to Work UK',
                    frontFile: _rightToWorkUKFront,
                    backFile: _rightToWorkUKBack,
                    onFrontUploaded: (file) {
                      setState(() {
                        _rightToWorkUKFront = file;
                      });
                    },
                    onBackUploaded: (file) {
                      setState(() {
                        _rightToWorkUKBack = file;
                      });
                    },
                  ),
                
                // Proof of Address
                _buildDocumentUpload(
                  title: 'Proof of Address',
                  frontFile: _addressProofFront,
                  backFile: _addressProofBack,
                  onFrontUploaded: (file) {
                    setState(() {
                      _addressProofFront = file;
                    });
                  },
                  onBackUploaded: (file) {
                    setState(() {
                      _addressProofBack = file;
                    });
                  },
                ),
                
                // Proof of Vehicle Insurance
                _buildDocumentUpload(
                  title: 'Proof of Vehicle Insurance',
                  frontFile: _vehicleInsuranceFront,
                  backFile: _vehicleInsuranceBack,
                  onFrontUploaded: (file) {
                    setState(() {
                      _vehicleInsuranceFront = file;
                    });
                  },
                  onBackUploaded: (file) {
                    setState(() {
                      _vehicleInsuranceBack = file;
                    });
                  },
                ),
                
                // Driving License
                _buildDocumentUpload(
                  title: 'Driving License',
                  frontFile: _drivingLicenseFront,
                  backFile: _drivingLicenseBack,
                  onFrontUploaded: (file) {
                    setState(() {
                      _drivingLicenseFront = file;
                    });
                  },
                  onBackUploaded: (file) {
                    setState(() {
                      _drivingLicenseBack = file;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                      ? null 
                      : () {
                          // Validate if all required documents are uploaded
                          bool isValid = _idFront != null && _idBack != null;
                          
                          if (_isBritishCitizen) {
                            isValid = isValid && _passportFront != null && _passportBack != null;
                          } else {
                            isValid = isValid && _rightToWorkUKFront != null && _rightToWorkUKBack != null;
                          }
                          
                          isValid = isValid && 
                            _addressProofFront != null && 
                            _addressProofBack != null &&
                            _vehicleInsuranceFront != null && 
                            _vehicleInsuranceBack != null &&
                            _drivingLicenseFront != null && 
                            _drivingLicenseBack != null;
                          
                          if (isValid) {
                            _submitAllDocuments();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please upload all required documents')),
                            );
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isLoading ? 'Submitting...' : 'Submit Documents',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}