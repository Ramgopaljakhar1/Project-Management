import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';

class DashboardController extends ChangeNotifier {
  Map<String, dynamic>? selectedPriority;
  List<Map<String, dynamic>> priorityList = [];
  List<Map<String, dynamic>> projectList = [];
  String? selectedProjectId;
  String? selectedProjectName;
  File? uploadedFile;
  int maxFileSize = 25 * 1024 * 1024;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController detailsController = TextEditingController();

  void setSelectedProject(String? projectId, String? projectName) {
    selectedProjectId = projectId;
    selectedProjectName = projectName;
    notifyListeners();
  }

  Future<void> fetchProjectList() async {
    try {
      final response = await ApiService.get(
        ApiConstants.ProjectList,
        headers: {'Content-Type': 'application/json'},
      );

      if (response != null && response['lookup'] != null) {
        final lookupDetails = response['lookup']['lookup_det_id'] as List;

        projectList =
            lookupDetails
                .where(
                  (item) =>
                      item['status'] == 'Active' || item['status'] == 'active',
                )
                .map<Map<String, dynamic>>(
                  (item) => {
                    'id': item['lookup_det_id'].toString(),
                    'name': item['lookup_det_desc_en'],
                  },
                )
                .toList();

        notifyListeners();
        debugPrint('✅ Project List---->>: $projectList');
      }
    } catch (e) {
      debugPrint('❌ Error fetching project list: $e');
      rethrow;
    }

    void setSelectedProject(String? projectId, String? projectName) {
      selectedProjectId = projectId;
      selectedProjectName = projectName;
      notifyListeners();
    }
  }

  Future<void> fetchAndPrintPriorities() async {
    try {
      final priorities = await priority();
      debugPrint('📋 All Priority Values from API:');
      for (var p in priorities) {
        debugPrint(
          '➡ ID: ${p['id']}, Name: ${p['name']}, Value: ${p['value']}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching priorities: $e');
    }
  }

  void selectPriority(String priorityValue) {
    if (priorityValue.isEmpty) return;

    // Reset all priorities first
    for (var p in priorityList) {
      p['isSelected'] = false;
    }

    // Find and select the new priority
    final selected = priorityList.firstWhere(
      (p) =>
          (p['value'] ?? '').toString().toLowerCase() ==
          priorityValue.toLowerCase(),
      orElse: () => {},
    );

    if (selected.isNotEmpty) {
      selected['isSelected'] = true;
      selectedPriority = selected;
      debugPrint(
        'Selected Priority: ${selected['name']} (${selected['value']})',
      );
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> priority() async {
    final Uri url = Uri.parse(
      'http://210.89.42.219:8083/api/lookup-det/by-code/SEV/',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['lookup'] != null &&
            decoded['lookup']['lookup_det_id'] != null) {
          priorityList =
              (decoded['lookup']['lookup_det_id'] as List)
                  .where(
                    (item) =>
                        item['status']?.toString().toLowerCase() == 'active',
                  )
                  .map<Map<String, dynamic>>(
                    (item) => {
                      'id': item['lookup_det_id'].toString(),
                      'value': item['lookup_det_value'],
                      'name': item['lookup_det_desc_en'],
                      'isSelected': false,
                    },
                  )
                  .toList();

          notifyListeners();
          return priorityList;
        }
      }
    } catch (e) {
      debugPrint('Error fetching priorities: $e');
    }
    return [];
  }
  Future<File?> pickAndUploadFile(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        if (fileSize > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File size exceeds 25 MB limit')),
          );
          return null;
        }
        uploadedFile = file;
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: ${e.toString()}')),
      );
    }
  }

  void deleteUploadedFile() {
    uploadedFile = null;
    notifyListeners();
  }

  Future<String?> getFileBase64() async {
    if (uploadedFile == null) return null;

    try {
      final bytes = await uploadedFile!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting file to base64: $e');
      return null;
    }
  }

  void resetForm() {
    detailsController.clear();
    selectedProjectId = null;
    selectedProjectName = null;
    selectedPriority = null;
    uploadedFile = null;
    notifyListeners();
  }




  Future<void> pickImageFromCamera(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        uploadedFile = File(photo.path);
        // agar Provider/GetX use kar rahe ho to yaha notify/update karna hoga
        debugPrint("📸 Camera image selected: ${uploadedFile!.path}");
      }
    } catch (e) {
      debugPrint("❌ Camera error: $e");
    }
  }


}
