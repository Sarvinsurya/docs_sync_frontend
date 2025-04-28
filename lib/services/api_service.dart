import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/document.dart';
import '../utils/constants.dart';
class ApiService {
  final String baseUrl = ApiConstants.baseUrl;
   String? token ;

  ApiService({this.token});
  // Headers with authentication
  Map<String, String> get headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization' : 'Bearer $token',
    };
    
    return headers;
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['message'] ?? 'An error occurred';
      throw Exception(errorMessage);
    }
  }

  // Documents API calls
  Future<List<Document>> fetchDocuments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/documents'),
      headers: headers,
    );
    
    final data = _handleResponse(response);    
    if (data['success'] && data['data'] != null) {
      return (data['data'] as List)
          .map((doc) => Document.fromJson(doc))
          .toList();
    }
    
    return [];
  }

  Future<Document> fetchDocument(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/documents/$id'),
      headers: headers,
    );
       

    
    final data = _handleResponse(response);
    
    if (data['success'] && data['data'] != null) {
      return Document.fromJson(data['data']);
    }
    
    throw Exception('Failed to load document');
  }

  Future<Document> createDocument(String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/documents'),
      headers: headers,
      body: json.encode({
        'title': title,

      }),
    );
    
    final data = _handleResponse(response);
    
    if (data['success'] && data['data'] != null) {
      return Document.fromJson(data['data']);
    }
    
    throw Exception('Failed to create document');
  }

  Future<Document> updateDocument(String id, String title, String content) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/documents/$id'),
      headers: headers,
      body: json.encode({
        'title': title,
        'content': content,
      }),
    );
    
    final data = _handleResponse(response);
    
    if (data['success'] && data['data'] != null) {
      return Document.fromJson(data['data']);
    }
    
    throw Exception('Failed to update document');
  }

  Future<void> deleteDocument(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/documents/$id'),
      headers: headers,
    );
    
    _handleResponse(response);
  }

  Future<Document> shareDocument(String id, String email, String permission) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/documents/$id/share'),
      headers: headers,
      body: json.encode({
        'email': email,
        'permission': permission,
      }),
    );
    
    final data = _handleResponse(response);
    
    if (data['success'] && data['data'] != null) {
      return Document.fromJson(data['data']);
    }
    
    throw Exception('Failed to share document');
  }

  Future<String> generateShareableLink(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/documents/$id/share'),
      headers: headers,
      body: json.encode({
        'generateLink': true,
      }),
    );
    
    final data = _handleResponse(response);
    
    if (data['success'] && data['shareableLink'] != null) {
      return data['shareableLink'];
    }
    
    throw Exception('Failed to generate shareable link');
  }
}
