import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  const Report({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.imageBase64,
    required this.location,
    required this.accuracyMeters,
    required this.category,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userEmail;
  final String imageBase64;
  final GeoPoint location;
  final double accuracyMeters;
  final String category;
  final String description;
  final int severity;
  final String status;
  final Timestamp createdAt;

  static Report fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Report(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      userEmail: (data['userEmail'] ?? '') as String,
      imageBase64: (data['images'] ?? '') as String,
      location: (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
      accuracyMeters: ((data['location'] != null
              ? (data['accuracyMeters'] ?? 0)
              : 0) as num)
          .toDouble(),
      category: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      severity: ((data['status'] == 'critical' ? 5 : 3) as num).toInt(),
      status: (data['status'] ?? 'new') as String,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'images': imageBase64,
      'location': location,
      'accuracyMeters': accuracyMeters,
      'title': category,
      'description': description,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

