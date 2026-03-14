import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dwgvpcmlq';
  static const String _uploadPreset = 'wj4wksux';

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  Future<String> uploadImage({
    required String filePath,
    required String folder,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Image file not found');
    }

    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload succeeded without secure_url');
    }

    return secureUrl;
  }
}
