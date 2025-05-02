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
  bool? _isBritishCitizen;
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

  @override
  void initState() {
    super.initState();
    _fetchCitizenshipStatus();
  }

 Future<void> _fetchCitizenshipStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.driverProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Improved parsing with better error handling
        if (responseData is Map<String, dynamic>) {
          setState(() {
            _isBritishCitizen = responseData['is_british_citizen'] as bool? ?? false;
          });
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Failed to load citizenship status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching citizenship status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _fetchCitizenshipStatus,
            ),
          ),
        );
      }
      // Default to false if there's an error
      setState(() {
        _isBritishCitizen = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<File?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
      return null;
    }
  }

  Future<bool> _uploadDocument({
    required String documentType,
    required File frontImage,
    required File backImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final uri = Uri.parse(ApiConfig.driverDocumentUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['document_type'] = documentType;
      
      request.files.add(await http.MultipartFile.fromPath(
        'front_image',
        frontImage.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'back_image',
        backImage.path,
      ));
      
      final response = await request.send();
      
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

  Future<void> _submitAllDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all required documents are uploaded
      if (_idFront == null || _idBack == null ||
          (_isBritishCitizen! && (_passportFront == null || _passportBack == null)) ||
          (!_isBritishCitizen! && (_rightToWorkUKFront == null || _rightToWorkUKBack == null)) ||
          _addressProofFront == null || _addressProofBack == null ||
          _vehicleInsuranceFront == null || _vehicleInsuranceBack == null ||
          _drivingLicenseFront == null || _drivingLicenseBack == null) {
        throw Exception('Please upload all required documents');
      }

      // Upload documents in sequence
      final uploads = [
        _uploadDocument(
          documentType: 'IDENTITY',
          frontImage: _idFront!,
          backImage: _idBack!,
        ),
        _isBritishCitizen!
            ? _uploadDocument(
                documentType: 'PASSPORT',
                frontImage: _passportFront!,
                backImage: _passportBack!,
              )
            : _uploadDocument(
                documentType: 'RIGHT_TO_WORK',
                frontImage: _rightToWorkUKFront!,
                backImage: _rightToWorkUKBack!,
              ),
        _uploadDocument(
          documentType: 'ADDRESS',
          frontImage: _addressProofFront!,
          backImage: _addressProofBack!,
        ),
        _uploadDocument(
          documentType: 'INSURANCE',
          frontImage: _vehicleInsuranceFront!,
          backImage: _vehicleInsuranceBack!,
        ),
        _uploadDocument(
          documentType: 'LICENSE',
          frontImage: _drivingLicenseFront!,
          backImage: _drivingLicenseBack!,
        ),
      ];

      final results = await Future.wait(uploads);
      if (results.contains(false)) {
        throw Exception('Some documents failed to upload');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All documents submitted successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DocumentVerificationPendingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                  if (file != null && mounted) {
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
                  if (file != null && mounted) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCitizenshipStatus,
            tooltip: 'Refresh citizenship status',
          ),
        ],
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
                  onFrontUploaded: (file) => setState(() => _idFront = file),
                  onBackUploaded: (file) => setState(() => _idBack = file),
                ),
                
                const SizedBox(height: 16),
                
                // Conditional document based on citizenship status
                if (_isBritishCitizen == null)
                  const Center(child: CircularProgressIndicator())
                else if (_isBritishCitizen!)
                  _buildDocumentUpload(
                    title: 'British Passport',
                    frontFile: _passportFront,
                    backFile: _passportBack,
                    onFrontUploaded: (file) => setState(() => _passportFront = file),
                    onBackUploaded: (file) => setState(() => _passportBack = file),
                  )
                else
                  _buildDocumentUpload(
                    title: 'Right to Work UK',
                    frontFile: _rightToWorkUKFront,
                    backFile: _rightToWorkUKBack,
                    onFrontUploaded: (file) => setState(() => _rightToWorkUKFront = file),
                    onBackUploaded: (file) => setState(() => _rightToWorkUKBack = file),
                  ),
                
                // Proof of Address
                _buildDocumentUpload(
                  title: 'Proof of Address',
                  frontFile: _addressProofFront,
                  backFile: _addressProofBack,
                  onFrontUploaded: (file) => setState(() => _addressProofFront = file),
                  onBackUploaded: (file) => setState(() => _addressProofBack = file),
                ),
                
                // Vehicle Insurance
                _buildDocumentUpload(
                  title: 'Vehicle Insurance',
                  frontFile: _vehicleInsuranceFront,
                  backFile: _vehicleInsuranceBack,
                  onFrontUploaded: (file) => setState(() => _vehicleInsuranceFront = file),
                  onBackUploaded: (file) => setState(() => _vehicleInsuranceBack = file),
                ),
                
                // Driving License
                _buildDocumentUpload(
                  title: 'Driving License',
                  frontFile: _drivingLicenseFront,
                  backFile: _drivingLicenseBack,
                  onFrontUploaded: (file) => setState(() => _drivingLicenseFront = file),
                  onBackUploaded: (file) => setState(() => _drivingLicenseBack = file),
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isBritishCitizen == null
                        ? null
                        : _submitAllDocuments,
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