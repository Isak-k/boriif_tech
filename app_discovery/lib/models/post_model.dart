import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String code;
  final String title;
  final String shortDescription;
  final String description;
  final String? imageUrl;
  final String? imagePath;
  final String postType; // 'app', 'article', 'job'
  final String categoryId;
  final String? playStoreUrl;
  final String? externalUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final int viewsCount;
  final int likesCount;
  final bool isFavorite;

  Post({
    required this.id,
    this.code = '',
    required this.title,
    required this.shortDescription,
    required this.description,
    this.imageUrl,
    this.imagePath,
    required this.postType,
    required this.categoryId,
    this.playStoreUrl,
    this.externalUrl,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isFavorite = false,
  });

  /// Convert Firestore document to Post model
  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final docId = doc.id;
    final fallbackCode = docId.length >= 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();
    return Post(
      id: docId,
      code: (data['code'] as String?)?.isNotEmpty == true ? (data['code'] as String) : fallbackCode,
      title: data['title'] as String? ?? '',
      shortDescription: data['shortDescription'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      postType: data['postType'] as String? ?? 'article',
      categoryId: data['categoryId'] as String? ?? '',
      playStoreUrl: data['playStoreUrl'] as String?,
      externalUrl: data['externalUrl'] as String?,
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      viewsCount: (data['viewsCount'] as int?) ?? 0,
      likesCount: (data['likesCount'] as int?) ?? ((data['favoritesCount'] as int?) ?? 0),
    );
  }

  /// Convert Post to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    final postCode = code.isNotEmpty
        ? code
        : (id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase());
    return {
      'code': postCode,
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'postType': postType,
      'categoryId': categoryId,
      'playStoreUrl': playStoreUrl,
      'externalUrl': externalUrl,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
    };
  }

  /// Convert to local JSON Map for offline storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code.isNotEmpty ? code : (id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()),
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'postType': postType,
      'categoryId': categoryId,
      'playStoreUrl': playStoreUrl,
      'externalUrl': externalUrl,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'isFavorite': isFavorite,
    };
  }

  /// Build from local JSON Map for offline storage
  factory Post.fromMap(Map<String, dynamic> map, [String? idOverride]) {
    final docId = idOverride ?? (map['id'] as String? ?? '');
    final fallbackCode = docId.length >= 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();
    return Post(
      id: docId,
      code: (map['code'] as String?)?.isNotEmpty == true ? (map['code'] as String) : fallbackCode,
      title: map['title'] as String? ?? '',
      shortDescription: map['shortDescription'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      postType: map['postType'] as String? ?? 'article',
      categoryId: map['categoryId'] as String? ?? '',
      playStoreUrl: map['playStoreUrl'] as String?,
      externalUrl: map['externalUrl'] as String?,
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: map['createdAt'] != null ? (DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()) : DateTime.now(),
      publishedAt: map['publishedAt'] != null ? DateTime.tryParse(map['publishedAt'] as String) : null,
      viewsCount: (map['viewsCount'] as int?) ?? 0,
      likesCount: (map['likesCount'] as int?) ?? 0,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
    );
  }

  /// Create a copy with modified fields
  Post copyWith({
    String? id,
    String? code,
    String? title,
    String? shortDescription,
    String? description,
    String? imageUrl,
    String? imagePath,
    String? postType,
    String? categoryId,
    String? playStoreUrl,
    String? externalUrl,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    int? viewsCount,
    int? likesCount,
    bool? isFavorite,
  }) {
    return Post(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      postType: postType ?? this.postType,
      categoryId: categoryId ?? this.categoryId,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
