import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ProfileRegistrationPage extends StatefulWidget {
  @override
  _ProfileRegistrationPageState createState() => _ProfileRegistrationPageState();
}

class _ProfileRegistrationPageState extends State<ProfileRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  
  File? _imageFile;
  final picker = ImagePicker();
  
  // For preferred working area
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSearching = false;
  
  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
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
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a profile picture')),
        );
        return;
      }
      
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a preferred working area')),
        );
        return;
      }
      
      // Collect all form data
      final userData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'preferredWorkingArea': _selectedAddress,
        'latitude': _latitude,
        'longitude': _longitude,
        // You'd handle the image file separately, typically upload it to storage
      };
      
      // Here you would send the data to your backend
      print('Submitting user data: $userData');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile registration successful!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Registration'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
}