import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart' as dart_quill;

import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../models/document.dart';
import '../utils/constants.dart';

class EditorScreen extends StatefulWidget {
  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final quill.QuillController _controller = quill.QuillController.basic();
  late String _documentId;
  Document? _document;
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  WebSocketChannel? _channel;
  Timer? _autoSaveTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

   

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveDocument();
    });
  }

  void _handleWebSocketDisconnected() {
    setState(() {
      _isConnected = false;
    });

    _reconnectTimer = Timer(const Duration(seconds: 3), _connectToWebSocket);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is String) {
      _documentId = args;
      _fetchDocument();
    }
  }

  Future<void> _fetchDocument() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _document = await Provider.of<DocumentProvider>(context, listen: false)
          .fetchDocument(_documentId);
      _titleController.text = _document?.title ?? '';

      if (_document?.content != null && _document!.content.isNotEmpty) {
        try {
          final json = jsonDecode(_document!.content);
          _controller.document = quill.Document.fromJson(json);

          _controller.changes.listen((event) {
            print("listenningnnnn");
  final delta = event.change;
  final source = event.source;

  if (source == quill.ChangeSource.local && _isConnected && _channel != null) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userID = authProvider.user?.id;

    if (userID != null) {
      _channel?.sink.add(jsonEncode({
        'action': 'delta',
        'documentId': _documentId,
        'userId': userID,
        'delta': delta.toJson(),
      }));
    }
  }
});
        } catch (e) {
          print('Error parsing document content: $e');
          _controller.document = quill.Document();
        }
      }

      _connectToWebSocket();


      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load document. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _connectToWebSocket() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userID = authProvider.user?.id;

    if (userID == null) return;

    _channel?.sink.close();

    try {
      final protocol = Uri.base.scheme == "https" ? "wss:" : "ws:";
      final wsUrl =
          '${protocol}//${ApiConstants.baseUrl.replaceAll('http://', '').replaceAll('https://', '')}/ws';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.sink.add(jsonEncode({
        'action': 'join',
        'documentId': _documentId,
        'userId': userID,
      }));

      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);
  print("called delta_update $data");
            if (data['action'] == 'delta_update' && data['userId'] != userID) {
                print("called delta_update inside if $data");

              try {
                final remoteDelta = dart_quill.Delta.fromJson(data['delta']);
                final currSelection = _controller.selection;
  _controller.compose(
  remoteDelta,
  currSelection.isValid ? currSelection : TextSelection.collapsed(offset: 0),
  quill.ChangeSource.remote,
);
            } catch (e) {
              
              print('Error applying remote delta: $e');
            }
          }
        },
        onDone: _handleWebSocketDisconnected,
        onError: (e) {
          print('WebSocket error: $e');
          _handleWebSocketDisconnected();
        },
      );
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _reconnectTimer = Timer(const Duration(seconds: 3), _connectToWebSocket);
    }
  }

  Future<void> _saveDocument() async {
    if (_document == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final content = jsonEncode(_controller.document.toDelta().toJson());

      await Provider.of<DocumentProvider>(context, listen: false)
          .updateDocument(
        _documentId,
        _titleController.text,
        content,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isConnected && _channel != null) {
        _channel?.sink.add(jsonEncode({
          'action': 'update',
          'documentId': _documentId,
          'userId': authProvider.user?.id,
          'content': content,
        }));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save document. Please try again.')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _shareDocument() async {
    if (_document == null) return;

    String? email;
    String permission = 'view';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Share Document'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter email to share with',
                  ),
                  onChanged: (value) {
                    email = value;
                  },
                ),
                SizedBox(height: 16),
                DropdownButton<String>(
                  value: permission,
                  items: [
                    DropdownMenuItem(
                      child: Text('View only'),
                      value: 'view',
                    ),
                    DropdownMenuItem(
                      child: Text('Can edit'),
                      value: 'edit',
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      permission = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Share'),
            onPressed: () async {
              if (email != null && email!.isNotEmpty) {
                Navigator.of(context).pop();
                try {
                  await Provider.of<DocumentProvider>(context, listen: false)
                      .shareDocument(_documentId, email!, permission);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Document shared successfully')),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to share document. Please try again.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateShareableLink() async {
    if (_document == null) return;

    try {
      final link = await Provider.of<DocumentProvider>(context, listen: false)
          .generateShareableLink(_documentId);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Shareable Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anyone with this link can view this document:'),
              SizedBox(height: 12),
              SelectableText(link),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate link. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _autoSaveTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await _saveDocument();
            Navigator.of(context).pop();
          },
        ),
        title: _isLoading
            ? Center(child: LinearProgressIndicator())
            : TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Untitled Document',
                ),
                onChanged: (_) {
                  _saveDocument();
                },
              ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Saved'),
            ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: Icon(Icons.link),
            onPressed: _generateShareableLink,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              EditorToolbar(controller: _controller),
              Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: quill.QuillEditor(
                    controller: _controller,
                    scrollController: ScrollController(),
                    focusNode: FocusNode(),
                  ),
                ),
              ),
            ]),
    );
  }
}
