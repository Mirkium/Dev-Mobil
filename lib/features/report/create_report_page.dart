import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../services/firebase/reports_repo.dart';
import '../../services/location/location_service.dart';
import '../../services/notification_service.dart';

class CreateReportPage extends ConsumerStatefulWidget {
  const CreateReportPage({super.key});

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  static const int _maxRawImageBytes = 700 * 1024;

  final _picker = ImagePicker();
  final _locationService = LocationService();

  File? _imageFile;
  String? _locationText;
  double? _lat;
  double? _lng;
  double? _accuracy;

  final _categoryController = TextEditingController(text: 'Road');
  final _descriptionController = TextEditingController();
  int _severity = 3;

  bool _busy = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 55,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (xfile == null) return;
      setState(() => _imageFile = File(xfile.path));
      if (mounted) {
        NotificationService.showSuccess(context, 'Photo captured!');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition(context: context);
      if (pos == null) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _accuracy = pos.accuracy;
        _locationText =
            'Lat: ${pos.latitude.toStringAsFixed(6)}  Lng: ${pos.longitude.toStringAsFixed(6)}  (±${pos.accuracy.toStringAsFixed(0)}m)';
      });
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Location captured successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  String _readableSubmitError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'unavailable') {
        return 'Network unavailable. Check your internet connection and retry.';
      }
      if (error.code == 'permission-denied') {
        return 'Permission denied by Firestore rules. Verify your account and rules configuration.';
      }
      if (error.code == 'failed-precondition') {
        return 'Firestore precondition failed. Please retry in a few seconds.';
      }
      return error.message ?? error.code;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  bool get _canSubmit {
    return _imageFile != null &&
        _lat != null &&
        _lng != null &&
        _categoryController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in.');
      if (!user.emailVerified) throw Exception('Email not verified.');

      final reportId = const Uuid().v4();

      // Convert image to base64
      final bytes = await _imageFile!.readAsBytes();
      if (bytes.lengthInBytes > _maxRawImageBytes) {
        throw Exception(
          'Image is too large for Firestore storage. Please retake the photo closer to the subject.',
        );
      }
      final base64Image = base64Encode(bytes);
      if (base64Image.length > 950000) {
        throw Exception(
          'Encoded image exceeds Firestore document limit. Please retake with a simpler/lower-detail image.',
        );
      }

      final data = <String, dynamic>{
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'images': base64Image,
        'location': GeoPoint(_lat!, _lng!),
        'accuracyMeters': _accuracy ?? 0,
        'title': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref
          .read(reportsRepoProvider)
          .createReport(reportId: reportId, data: data);

      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Report submitted successfully!',
        );
      }

      setState(() {
        _imageFile = null;
        _lat = null;
        _lng = null;
        _accuracy = null;
        _locationText = null;
        _descriptionController.clear();
        _severity = 3;
      });
    } catch (e) {
      if (mounted) {
        final message = _readableSubmitError(e);
        NotificationService.showError(context, message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'New Report',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Photo + Location Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _takePicture,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Take photo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy ? null : _getLocation,
                          icon: const Icon(Icons.location_on),
                          label: const Text('Get location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Photo preview
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No photo yet',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Location display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationText ?? 'Location not set',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Severity Level: $_severity',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _severity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _severity.toString(),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _severity = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: (_busy || !_canSubmit) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Report', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: All images are stored securely as base64 in Firestore (no Firebase Storage costs). Location and description help categorize reported issues.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
