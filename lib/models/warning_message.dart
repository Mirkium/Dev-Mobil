import 'package:cloud_firestore/cloud_firestore.dart';

class WarningMessage {
  const WarningMessage({
    required this.id,
    required this.active,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final bool active;
  final String message;
  final Timestamp createdAt;

  static WarningMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WarningMessage(
      id: doc.id,
      active: (data['active'] as bool?) ?? false,
      message: (data['message'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }
}

