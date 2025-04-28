import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../models/document.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load documents. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewDocument(BuildContext context) async {
    final TextEditingController _titleController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create New Document',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey[850],
          content: TextField(
            controller: _titleController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter document title...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.title, color: Colors.grey[400]),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                if (_titleController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  
                  try {
                    final newDoc = await Provider.of<DocumentProvider>(context, listen: false)
                        .createDocument(_titleController.text.trim());
                        
                    Navigator.of(context).pushNamed(
                      '/editor',
                      arguments: newDoc.id,
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create document. Please try again.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a document title'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final documents = documentProvider.documents;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[850],
        title: Text(
          'My Documents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchDocuments,
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[700],
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
                onTap: () {
                  Future.delayed(
                    const Duration(seconds: 0),
                    () {
                      authProvider.logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  );
                },
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No documents yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create your first document to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Create New Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => _createNewDocument(context),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDocuments,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                          child: Text(
                            'Recent Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: documents.length,
                            itemBuilder: (ctx, index) {
                              final doc = documents[index];
                              // Format the document date
                              final formattedDate = DateFormat('MMM d, y').format(
                                doc.lastModified ?? DateTime.now(),
                              );
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    '/editor',
                                    arguments: doc.id,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Colorful top header
                                      Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              _getDocumentColor(doc.id),
                                              _getDocumentColor(doc.id).withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _getDocumentIcon(doc.title),
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[400],
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Container(
                                              height: 2,
                                              width: 40,
                                              color: _getDocumentColor(doc.id).withOpacity(0.7),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewDocument(context),
        label: Text('New Document'),
        icon: Icon(Icons.add),
        elevation: 4,
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
  
  // Helper method to generate a consistent color based on document ID
  Color _getDocumentColor(String id) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.indigo,
      Colors.red,
    ];
    
    // Use the hashCode of the ID to pick a color
    final colorIndex = id.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }
  
  // Helper method to choose an icon based on document title
  IconData _getDocumentIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    
    if (lowercaseTitle.contains('report') || lowercaseTitle.contains('summary')) {
      return Icons.assessment;
    } else if (lowercaseTitle.contains('plan') || lowercaseTitle.contains('schedule')) {
      return Icons.calendar_today;
    } else if (lowercaseTitle.contains('list') || lowercaseTitle.contains('todo')) {
      return Icons.checklist;
    } else if (lowercaseTitle.contains('note')) {
      return Icons.note;
    } else if (lowercaseTitle.contains('letter') || lowercaseTitle.contains('email')) {
      return Icons.email;
    } else if (lowercaseTitle.contains('presentation')) {
      return Icons.slideshow;
    } else if (lowercaseTitle.contains('budget') || lowercaseTitle.contains('finance')) {
      return Icons.attach_money;
    } else {
      return Icons.article;
    }
  }
}