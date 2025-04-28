class Document {
  final String id;
  final String title;
  final String content;
  final String owner;
  final List<SharedUser> sharedWith;
  final ShareableLink? shareableLink;
  final DateTime lastModified;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.title,
    this.content = '',
    required this.owner,
    this.sharedWith = const [],
    this.shareableLink,
    required this.lastModified,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'],
      title: json['title'],
      content: json['content'] ?? '',
      owner: json['owner'],
      sharedWith: json['sharedWith'] != null
          ? List<SharedUser>.from(
              json['sharedWith'].map((x) => SharedUser.fromJson(x)))
          : [],
      shareableLink: json['shareableLink'] != null
          ? ShareableLink.fromJson(json['shareableLink'])
          : null,
      lastModified: DateTime.parse(json['lastModified']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'owner': owner,
      'sharedWith': sharedWith.map((x) => x.toJson()).toList(),
      'shareableLink': shareableLink?.toJson(),
      'lastModified': lastModified.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SharedUser {
  final String userId;
  final String permission;

  SharedUser({
    required this.userId,
    required this.permission,
  });

  factory SharedUser.fromJson(Map<String, dynamic> json) {
    return SharedUser(
      userId: json['userId'],
      permission: json['permission'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'permission': permission,
    };
  }
}

class ShareableLink {
  final String token;
  final bool isActive;

  ShareableLink({
    required this.token,
    required this.isActive,
  });

  factory ShareableLink.fromJson(Map<String, dynamic> json) {
    return ShareableLink(
      token: json['token'] ?? '', // Default to an empty string if null
      isActive: json['isActive'] ?? false, // Default to false if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'isActive': isActive,
    };
  }
}
