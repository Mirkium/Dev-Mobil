import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/report.dart';
import '../../models/warning_message.dart';
import 'firestore_refs.dart';

class ReportsRepo {
  ReportsRepo(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');
  CollectionReference<Map<String, dynamic>> get _warnings =>
      _firestore.collection('warnings');

  Future<void> createReport({
    required String reportId,
    required Map<String, dynamic> data,
  }) async {
    await _reports.doc(reportId).set(data);
  }

  Stream<List<Report>> streamMyReports(String userId) {
    return _reports.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final reports = snap.docs.map(Report.fromDoc).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Stream<List<Report>> streamAllReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Report.fromDoc).toList());
  }

  Stream<List<WarningMessage>> streamActiveWarnings() {
    return _warnings
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WarningMessage.fromDoc).toList());
  }
}

final reportsRepoProvider = Provider<ReportsRepo>((ref) {
  return ReportsRepo(ref.watch(firestoreProvider));
});
