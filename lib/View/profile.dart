import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:taskova_drivers/Model/api_config.dart';

class ProfileRegistrationPage extends StatefulWidget {
  @override
  _ProfileRegistrationPageState createState() => _ProfileRegistrationPageState();
}

class _ProfileRegistrationPageState extends State<ProfileRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  
  bool _isBritishCitizen = false;
  bool _hasCriminalHistory = false;
  File? _imageFile;
  final picker = ImagePicker();
  
  // For preferred working area
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSearching = false;
  bool _isSubmitting = false;
  
  // For showing detailed error messages
  String? _errorMessage;
  
  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }
  
  Future<void> _searchByPostcode(String postcode) async {
    if (postcode.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _selectedAddress = null;
      _latitude = null;
      _longitude = null;
    });
    
    try {
      // Using geocoding package to search by postcode
      List<Location> locations = await locationFromAddress(postcode);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude, 
          location.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          setState(() {
            _selectedAddress = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}';
            _latitude = location.latitude;
            _longitude = location.longitude;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching postcode: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Submit form using multipart/form-data
  Future<void> _submitMultipartForm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Authentication token not found. Please login again.');
      }
      
      // Create multipart request
      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });
      
      // Debug print token
      print('Access Token: $accessToken');
      
      // Add form fields as multipart fields
      request.fields['name'] = _nameController.text;
      request.fields['phone_number'] = _phoneController.text;
      request.fields['email'] = _emailController.text;
      request.fields['address'] = _addressController.text;
      request.fields['preferred_working_area'] = _postcodeController.text;
      request.fields['preferred_working_address'] = _selectedAddress ?? '';
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();
      request.fields['is_british_citizen'] = _isBritishCitizen ? 'true' : 'false';
      request.fields['has_criminal_history'] = _hasCriminalHistory ? 'true' : 'false';
      
      // Debug print all fields
      print('Request Fields:');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });
      
      // Add image file with correct content type
      if (_imageFile != null) {
        final fileName = _imageFile!.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        
        final multipartFile = await http.MultipartFile.fromPath(
          'profile_picture',
          _imageFile!.path,
          contentType: MediaType('image', extension),
          filename: fileName,
        );
        
        request.files.add(multipartFile);
        
        // Debug print file info
        print('Image File:');
        print('  Name: $fileName');
        print('  Content-Type: ${MediaType('image', extension)}');
        print('  Size: ${await _imageFile!.length()} bytes');
      }
      
      // Debug print request details
      print('Request URL: ${request.url}');
      print('Request Method: ${request.method}');
      print('Request Headers: ${request.headers}');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out. Please check your connection.');
        },
      );
      
      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug print response
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile registered successfully!')),
        );
        Navigator.pop(context);
      } else {
        // Error
        setState(() {
          try {
            final responseData = json.decode(response.body);
            if (responseData is Map<String, dynamic>) {
              // Handle different error formats
              if (responseData.containsKey('detail')) {
                _errorMessage = responseData['detail'];
              } else {
                // Format field errors
                final List<String> errors = [];
                responseData.forEach((key, value) {
                  if (value is List && value.isNotEmpty) {
                    errors.add('$key: ${value.join(', ')}');
                  } else if (value is String) {
                    errors.add('$key: $value');
                  }
                });
                _errorMessage = errors.isNotEmpty ? errors.join('\n') : 'Unknown error occurred';
              }
            } else {
              _errorMessage = 'Server returned an unexpected response format';
            }
          } catch (e) {
            _errorMessage = 'Failed to parse server response: ${e.toString()}';
          }
        });
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
      print('Exception during form submission: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a profile picture')),
        );
        return;
      }
      
      if (_selectedAddress == null || _latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a preferred working area')),
        );
        return;
      }
      
      await _submitMultipartForm();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Registration'),
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting profile information...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error message display
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registration Failed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ],
                        ),
                      ),
                    
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null 
                                ? FileImage(_imageFile!) 
                                : null,
                            child: _imageFile == null
                                ? Icon(Icons.person, size: 70, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: _getImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // British Citizen Toggle
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Are you a British Citizen?',
                              style: TextStyle(fontSize: 16),
                            ),
                            Switch(
                              value: _isBritishCitizen,
                              onChanged: (value) {
                                setState(() {
                                  _isBritishCitizen = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Criminal History Checkbox
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Do you have any criminal history?',
                              style: TextStyle(fontSize: 16),
                            ),
                            Switch(
                              value: _hasCriminalHistory,
                              onChanged: (value) {
                                setState(() {
                                  _hasCriminalHistory = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Preferred Working Area Section
                    Text(
                      'Preferred Working Area',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Postcode Search Field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postcodeController,
                            decoration: InputDecoration(
                              labelText: 'Search by Postcode',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _searchByPostcode(_postcodeController.text),
                          child: Text('Search'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Search Result Display
                    if (_isSearching)
                      Center(child: CircularProgressIndicator())
                    else if (_selectedAddress != null)
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Working Area:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(_selectedAddress!),
                              SizedBox(height: 8),
                              Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
                              Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
                            ],
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 30),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Register Profile',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}

// Custom exception class
class TimeoutException implements Exception {
  final String? message;
  TimeoutException(this.message);
  
  @override
  String toString() {
    return message ?? 'Request timed out';
  }
}