import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/appointment.dart';
import '../models/consultation.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import '../utils/session_manager.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final branch = await SessionManager.getBranchName();
    return branch != null ? {'X-Branch-Name': branch} : {};
  }
  // Use centralized configuration from constants.dart
  static const String baseUrl = ApiConfig.baseUrl;

  /// Centralized logic to convert a server path (possibly from Windows/XAMPP) 
  /// into a valid, reachable network URL.
  static String sanitizeImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    
    // 1. Normalize separators (Windows \ to Web /)
    String sanitized = path.replaceAll('\\', '/');
    
    // 2. Strip absolute server markers if present
    if (sanitized.contains('htdocs/')) {
      sanitized = sanitized.split('htdocs/').last;
    }
    
    // 3. Ensure no leading slash for concatenation
    if (sanitized.startsWith('/')) sanitized = sanitized.substring(1);
    
    // 4. Derive domain and combine
    String domain = baseUrl.split('/medinote').first;
    if (domain.endsWith('/')) domain = domain.substring(0, domain.length - 1);
    
    return "$domain/$sanitized";
  }

  Future<Map<String, dynamic>> updatePassword(String identifier, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_password.php"),
        headers: await _getHeaders(),
        body: {
          'identifier': identifier,
          'new_password': newPassword,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"success": false, "error": "Server error: ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password, String branch) async {
    try {
      dev.log("Attempting login at: $baseUrl/login.php", name: "ApiService");
      
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        body: {
          "username": username,
          "password": password,
          "branch": branch,
        },
      ).timeout(const Duration(seconds: 30));

      await SessionManager.saveSessionData(branch, null);

      String responseBody = response.body.trim();
      dev.log("Server Response (Status: ${response.statusCode}): $responseBody", name: "ApiService");
      
      if (responseBody.isEmpty) {
        return {
          "user": null, 
          "error": "Server returned absolutely NO data (Status: ${response.statusCode}). "
                   "Check if Apache/PHP is running on ${ApiConfig.machineIp}."
        };
      }

      try {
        final data = json.decode(responseBody);
        if (response.statusCode == 200) {
          if (data['status'] == 'success') {
            return {"user": User.fromJson(data['user']), "error": null};
          } else {
            return {
              "user": null, 
              "error": "${data['message'] ?? "Login failed."}\n\n-- Debug Info --\nUsername sent: '$username'\nBranch sent: '$branch'\nEndpoint: $baseUrl/login.php\nRaw Response: $responseBody"
            };
          }
        } else {
          return {"user": null, "error": "Server error (${response.statusCode})"};
        }
      } catch (e) {
        dev.log("JSON Parsing Error: $e. Response: $responseBody", name: "ApiService");
        // SHOW RAW RESPONSE DIRECTLY FOR DEBUGGING
        String debugMsg = responseBody.length > 300 
            ? responseBody.substring(0, 300) + "..." 
            : responseBody;
        return {"user": null, "error": "Debug Server Error: \n\n$debugMsg"};
      }
    } on SocketException catch (e) {
      dev.log("SocketException: $e", name: "ApiService");
      return {
        "user": null, 
        "error": "Cannot reach server at ${ApiConfig.machineIp}. \n\n"
                 "1. Ensure XAMPP is running.\n"
                 "2. Ensure your phone and PC are on the SAME Wi-Fi.\n"
                 "3. Check your Windows Firewall."
      };
    } on http.ClientException catch (e) {
       dev.log("ClientException: $e", name: "ApiService");
       return {"user": null, "error": "Network client error. Please check your connection."};
    } catch (e) {
      dev.log("General Error: $e", name: "ApiService");
      return {"user": null, "error": "Connection error: $e"};
    }
  }

  Future<List<Appointment>> getAppointments(String doctorId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_appointments.php?doctor_id=$doctorId"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        
        // Defensive Parsing: Extract only the content between the first { and last }
        if (responseBody.contains('{') && responseBody.contains('}')) {
          try {
            int startIndex = responseBody.indexOf('{');
            int endIndex = responseBody.lastIndexOf('}');
            responseBody = responseBody.substring(startIndex, endIndex + 1);
          } catch (e) {
            dev.log("Parsing Error: $e", name: "ApiService/getAppointments");
          }
        }
        
        final data = json.decode(responseBody);
        if (data['status'] == 'success') {
          return (data['appointments'] as List)
              .map((a) => Appointment.fromJson(a))
              .toList();
        }
      } else {
        dev.log("Server error: ${response.statusCode}", name: "ApiService/getAppointments");
      }
    } catch (e) {
      dev.log("Get appointments error: $e", name: "ApiService/getAppointments");
    }
    return [];
  }

  Future<Map<String, dynamic>> savePrescription({
    required String patientName,
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required String followUpDate,
    required List<File> imageFiles,
    String? vitalSigns,
    String? clinicalNotes,
    String? labData,
    String? rxData,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/save_prescription.php"),
      );
      request.headers.addAll(await _getHeaders());

      request.fields['patient_id'] = patientId;
      request.fields['patient_name'] = patientName;
      request.fields['doctor_id'] = doctorId;
      request.fields['appointment_id'] = appointmentId;
      request.fields['follow_up_date'] = followUpDate;
      
      if (vitalSigns != null) request.fields['vital_signs'] = vitalSigns;
      if (clinicalNotes != null) request.fields['clinical_notes'] = clinicalNotes;
      if (labData != null) request.fields['lab_data'] = labData;
      if (rxData != null) request.fields['rx_data'] = rxData;

      for (var file in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'prescription_images[]', // Array-style field name for PHP
            file.path,
          ),
        );
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      var response = await http.Response.fromStream(streamedResponse);
      
      dev.log("Save Response [${response.statusCode}]: ${response.body}", name: "ApiService");

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return {"success": result['status'] == 'success', "message": result['message'] ?? "Unknown success"};
        } catch (e) {
          dev.log("JSON Parse Error: $e", name: "ApiService");
          return {"success": false, "message": "Invalid response from server."};
        }
      } else {
        try {
          final result = json.decode(response.body);
          return {"success": false, "message": result['message'] ?? "Server error: ${response.statusCode}"};
        } catch (e) {
          return {"success": false, "message": "Server error: ${response.statusCode}"};
        }
      }
    } catch (e) {
      dev.log("Save prescription error: $e", name: "ApiService");
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateProfilePhoto(String doctorId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/update_profile_photo.php"),
      );
      request.headers.addAll(await _getHeaders());

      request.fields['doctor_id'] = doctorId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ),
      );

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"status": "error", "message": "Server error: ${response.statusCode}"};
    } catch (e) {
      dev.log("Update profile photo error: $e", name: "ApiService");
      return {"status": "error", "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDoctorProfile({
    required String doctorId,
    required String fullName,
    required String gender,
    required String mobileNumber,
    required String qualification,
    required String specialization,
    required String experienceYears,
    required String availableDays,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_doctor_profile.php"),
        headers: await _getHeaders(),
        body: {
          'doctor_id': doctorId,
          'full_name': fullName,
          'gender': gender,
          'mobile_number': mobileNumber,
          'qualification': qualification,
          'specialization': specialization,
          'experience_years': experienceYears,
          'available_days': availableDays,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"status": "error", "message": "Server error: ${response.statusCode}"};
    } catch (e) {
      dev.log("Update doctor profile error: $e", name: "ApiService");
      return {"status": "error", "message": e.toString()};
    }
  }

  Future<List<ConsultationRecord>> getPrescriptions({
    String? appointmentId, 
    String? patientId, 
    String? doctorId, 
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    final raw = await getPrescriptionsRaw(
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      startDate: startDate,
      endDate: endDate,
    );
    return raw.map((p) => ConsultationRecord.fromJson(p)).toList();
  }

  Future<List<Map<String, dynamic>>> getPrescriptionsRaw({
    String? appointmentId, 
    String? patientId, 
    String? doctorId, 
    DateTime? startDate, 
    DateTime? endDate
  }) async {
    try {
      List<String> queryParams = [];
      if (appointmentId != null) queryParams.add("appointment_id=$appointmentId");
      if (patientId != null) queryParams.add("patient_id=$patientId");
      if (doctorId != null) queryParams.add("doctor_id=$doctorId");
      if (startDate != null && endDate != null) {
        final DateFormat df = DateFormat('yyyy-MM-dd');
        queryParams.add("start_date=${df.format(startDate)}");
        queryParams.add("end_date=${df.format(endDate)}");
      }
      
      String url = "$baseUrl/get_prescriptions.php" + (queryParams.isNotEmpty ? "?" + queryParams.join("&") : "");
      
      final response = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['prescriptions']);
        }
      }
    } catch (e) {
      dev.log("Get prescriptions error: $e", name: "ApiService");
    }
    return [];
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_patient_details.php?patient_id=$patientId"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"status": "error", "message": "Server error: ${response.statusCode}"};
    } catch (e) {
      dev.log("Get patient details error: $e", name: "ApiService");
      return {"status": "error", "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePatientDetails({
    required String patientId,
    String? title,
    String? firstName,
    String? lastName,
    String? sex,
    String? age,
    String? bloodGroup,
    String? phone,
    String? aadhar,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_patient.php"),
        headers: await _getHeaders(),
        body: {
          'patient_id': patientId,
          if (title != null) 'title': title,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (sex != null) 'sex': sex,
          if (age != null) 'age': age,
          if (bloodGroup != null) 'blood_group': bloodGroup,
          if (phone != null) 'phone': phone,
          if (aadhar != null) 'aadhar': aadhar,
          if (address != null) 'address': address,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"status": "error", "message": "Update server error: ${response.statusCode}"};
    } catch (e) {
      dev.log("Update patient details error: $e", name: "ApiService");
      return {"status": "error", "message": e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getAllLabServices() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_services.php"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['services']);
        }
      }
    } catch (e) {
      dev.log("Get all lab services error: $e", name: "ApiService");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/search_medicines.php?q=${Uri.encodeComponent(query)}"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['medicines']);
        }
      }
    } catch (e) {
      dev.log("Search medicines error: $e", name: "ApiService");
    }
    return [];
  }
}
