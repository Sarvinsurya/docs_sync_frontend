import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
   String _userId;
   String _userName;
  Function(dynamic)? _onMessageCallback;
  Function(String)? _onErrorCallback;
  Function()? _onConnectedCallback;
  Function()? _onDisconnectedCallback;
  String? _currentDocumentId;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  
  factory WebSocketService({
    required String userId,
    required String userName,
  }) {
    _instance._userId = userId;
    _instance._userName = userName;
    return _instance;
  }
  
  WebSocketService._internal() : _userId = '', _userName = '';
  
  bool get isConnected => _channel != null;
  
  void connect() {
    if (_channel != null || _isReconnecting) return;
    
    final wsUrl = _getWebSocketUrl();
    
    try {
      if (kIsWeb) {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      } else {
        _channel = IOWebSocketChannel.connect(wsUrl);
      }
      
      _channel!.stream.listen(
        (message) {
          if (_onMessageCallback != null) {
            try {
              final data = jsonDecode(message);
              _onMessageCallback!(data);
            } catch (e) {
              print('Error parsing WebSocket message: $e');
              if (_onErrorCallback != null) {
                _onErrorCallback!('Error parsing message: $e');
              }
            }
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (_onErrorCallback != null) {
            _onErrorCallback!('Connection error: $error');
          }
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnect();
        },
      );
      
      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      
      if (_onConnectedCallback != null) {
        _onConnectedCallback!();
      }
      
      // If we were previously connected to a document, rejoin it
      if (_currentDocumentId != null) {
        joinDocument(_currentDocumentId!);
      }
    } catch (e) {
      print('Error establishing WebSocket connection: $e');
      if (_onErrorCallback != null) {
        _onErrorCallback!('Connection failed: $e');
      }
      _scheduleReconnect();
    }
  }
  
  void _handleDisconnect() {
    final wasConnected = _channel != null;
    _channel = null;
    
    if (wasConnected && _onDisconnectedCallback != null) {
      _onDisconnectedCallback!();
    }
    
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _isReconnecting = true;
    _reconnectAttempts++;
    
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final backoffSeconds = (1 << (_reconnectAttempts - 1)).clamp(1, 16);
    print('Scheduling reconnect attempt $_reconnectAttempts in $backoffSeconds seconds');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      _isReconnecting = false;
      connect();
    });
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;
    
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
      _channel = null;
    }
    
    _currentDocumentId = null;
  }
  
  void joinDocument(String documentId) {
    _currentDocumentId = documentId;
    
    if (_channel == null) {
      connect();
      return;
    }
    
    final message = {
      'action': 'join',
      'documentId': documentId,
      'userId': _userId,
      'userName': _userName,
    };
    
    _sendMessage(message);
  }
  
  void sendTextUpdate(String content) {
    if (_currentDocumentId == null) return;
    
    final message = {
      'action': 'update',
      'documentId': _currentDocumentId,
      'userId': _userId,
      'userName': _userName,
      'content': content,
    };
    
    _sendMessage(message);
  }
  
  void sendRichTextUpdate(Map<String, dynamic> delta) {
    if (_currentDocumentId == null) return;
    
    final message = {
      'action': 'update',
      'documentId': _currentDocumentId,
      'userId': _userId,
      'userName': _userName,
      'isRichText': true,
      'richTextDelta': delta,
    };
    
    _sendMessage(message);
  }
  
  void sendHtmlUpdate(String htmlContent) {
    if (_currentDocumentId == null) return;
    
    final message = {
      'action': 'update',
      'documentId': _currentDocumentId,
      'userId': _userId,
      'userName': _userName,
      'htmlContent': htmlContent,
    };
    
    _sendMessage(message);
  }
  
  void sendCursorPosition(Map<String, dynamic> position, Map<String, dynamic>? selection) {
    if (_currentDocumentId == null) return;
    
    final message = {
      'action': 'cursor_position',
      'documentId': _currentDocumentId,
      'userId': _userId,
      'userName': _userName,
      'cursorPosition': position,
      'selection': selection,
    };
    
    _sendMessage(message);
  }
  
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      connect();
      // Queue message to be sent once connection is established
      // For simplicity, we'll just log for now, but you could implement a proper queue system
      print('Cannot send message, not connected. Will connect first.');
      return;
    }
    
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending message: $e');
      if (_onErrorCallback != null) {
        _onErrorCallback!('Failed to send message: $e');
      }
      _handleDisconnect();
    }
  }
  
  void onMessage(Function(dynamic) callback) {
    _onMessageCallback = callback;
  }
  
  void onError(Function(String) callback) {
    _onErrorCallback = callback;
  }
  
  void onConnected(Function() callback) {
    _onConnectedCallback = callback;
  }
  
  void onDisconnected(Function() callback) {
    _onDisconnectedCallback = callback;
  }
  
  String _getWebSocketUrl() {
    if (kIsWeb) {
      // For web, determine protocol based on the window location
      final protocol = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      // Use the same port as the server
      return '$protocol://${Uri.base.host}/ws';
    } else {
      // For mobile apps, determine based on environment
      // In production this would come from a config or environment variable
      const String serverHost = '0.0.0.0'; // Use your actual server address
      const int serverPort = 8000;
      return 'ws://$serverHost:$serverPort/ws';
    }
  }
  
  // Clean up resources
  void dispose() {
    disconnect();
    _reconnectTimer?.cancel();
    _onMessageCallback = null;
    _onErrorCallback = null;
    _onConnectedCallback = null;
    _onDisconnectedCallback = null;
  }
}