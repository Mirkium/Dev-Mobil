import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

class StorageRepo {
  StorageRepo(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadReportImage({
    required String storagePath,
    required File file,
  }) async {
    final ref = _storage.ref(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}

final storageRepoProvider = Provider<StorageRepo>((ref) {
  return StorageRepo(ref.watch(firebaseStorageProvider));
});

