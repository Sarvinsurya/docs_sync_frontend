import 'package:flutter/foundation.dart';

import '../models/document.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];
  final AuthService _authService = AuthService(); // Instance of AuthService

  List<Document> get documents => [..._documents];

  // Fetch all documents for the current user
  Future<void> fetchDocuments() async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);  
      final docs = await apiService.fetchDocuments();
      _documents = docs;
      notifyListeners();
    } catch (error) {
      print('Error fetching documents: $error'); // Debug log

      throw error;
    }
  }

  // Fetch a single document by ID
  Future<Document> fetchDocument(String id) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      final document = await apiService.fetchDocument(id);

      // Update document in local list if it exists
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index >= 0) {
        _documents[index] = document;
        notifyListeners();
      }

      return document;
    } catch (error) {
      throw error;
    }
  }

  // Create a new document
  Future<Document> createDocument(String title) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      final newDocument = await apiService.createDocument(title);

      _documents.add(newDocument);
      notifyListeners();

      return newDocument;
    } catch (error) {
      throw error;
    }
  }

  // Update an existing document
  Future<Document> updateDocument(String id, String title, String content) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      final updatedDocument = await apiService.updateDocument(id, title, content);

      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index >= 0) {
        _documents[index] = updatedDocument;
        notifyListeners();
      }

      return updatedDocument;
    } catch (error) {
      throw error;
    }
  }

  // Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      await apiService.deleteDocument(id);

      _documents.removeWhere((doc) => doc.id == id);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  // Share a document with another user
  Future<Document> shareDocument(String id, String email, String permission) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      final updatedDocument = await apiService.shareDocument(id, email, permission);

      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index >= 0) {
        _documents[index] = updatedDocument;
        notifyListeners();
      }

      return updatedDocument;
    } catch (error) {
      throw error;
    }
  }

  // Generate a shareable link for a document
  Future<String> generateShareableLink(String id) async {
    try {
      final token = await _authService.getStoredToken(); // Fetch token internally
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final apiService = ApiService(token: token);
      return await apiService.generateShareableLink(id);
    } catch (error) {
      throw error;
    }
  }
}
