import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/report.dart';
import '../../services/firebase/reports_repo.dart';
import '../history/report_detail_page.dart';

final allReportsProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(reportsRepoProvider).streamAllReports();
});

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsProvider);
    final warningsAsync = ref.watch(activeWarningsProvider);

    return SafeArea(
      child: Column(
        children: [
          warningsAsync.when(
            data: (warnings) {
              if (warnings.isEmpty) return const SizedBox.shrink();
              final msg = warnings.first.message.trim();
              if (msg.isEmpty) return const SizedBox.shrink();
              return MaterialBanner(
                content: Text(msg),
                actions: const [],
              );
            },
            error: (error, stackTrace) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                final center = _centerFromReports(reports) ?? const LatLng(48.8566, 2.3522);
                final markers = reports
                    .map(
                      (r) => Marker(
                        point: LatLng(r.location.latitude, r.location.longitude),
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: r.category,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportDetailPage(report: r),
                            ),
                          ),
                          icon: Icon(
                            Icons.location_pin,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    )
                    .toList();

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.degraded_points_app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
              error: (e, _) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  LatLng? _centerFromReports(List<Report> reports) {
    if (reports.isEmpty) return null;
    final r = reports.first;
    return LatLng(r.location.latitude, r.location.longitude);
  }
}

final activeWarningsProvider = StreamProvider((ref) {
  return ref.watch(reportsRepoProvider).streamActiveWarnings();
});

