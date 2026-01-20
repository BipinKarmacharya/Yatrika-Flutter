import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum OfflineMapStatus {
  notDownloaded,
  queued,
  downloading,
  downloaded,
  updateAvailable,
}

class OfflineMapArea {
  const OfflineMapArea({
    required this.name,
    required this.detail,
    required this.sizeGb,
    required this.status,
    this.progress = 0,
  });

  final String name;
  final String detail;
  final double sizeGb;
  final OfflineMapStatus status;
  final double progress;

  bool get isCached =>
      status == OfflineMapStatus.downloaded ||
      status == OfflineMapStatus.updateAvailable;

  OfflineMapArea copyWith({
    String? name,
    String? detail,
    double? sizeGb,
    OfflineMapStatus? status,
    double? progress,
  }) {
    return OfflineMapArea(
      name: name ?? this.name,
      detail: detail ?? this.detail,
      sizeGb: sizeGb ?? this.sizeGb,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  static const double _storageBudgetGb = 6.0;

  late List<OfflineMapArea> _areas;

  @override
  void initState() {
    super.initState();
    _areas = [
      const OfflineMapArea(
        name: 'Lisbon',
        detail: 'City center + Sintra rail',
        sizeGb: 0.82,
        status: OfflineMapStatus.downloaded,
      ),
      const OfflineMapArea(
        name: 'Kyoto Metro',
        detail: 'Transit, temples, trails',
        sizeGb: 0.64,
        status: OfflineMapStatus.updateAvailable,
      ),
      const OfflineMapArea(
        name: 'Patagonia',
        detail: 'El Chalten + Torres route',
        sizeGb: 1.20,
        status: OfflineMapStatus.downloading,
        progress: 0.35,
      ),
      const OfflineMapArea(
        name: 'Cape Town',
        detail: 'City bowl + Cape Peninsula',
        sizeGb: 0.48,
        status: OfflineMapStatus.notDownloaded,
      ),
    ];
  }

  double get _downloadedTotal =>
      _areas.where((a) => a.isCached).fold(0, (sum, a) => sum + a.sizeGb);

  int get _activeDownloads => _areas
      .where((a) =>
          a.status == OfflineMapStatus.downloading ||
          a.status == OfflineMapStatus.queued)
      .length;

  void _updateArea(int index, OfflineMapArea area) {
    if (index < 0 || index >= _areas.length) return;
    setState(() {
      _areas[index] = area;
    });
  }

  void _handlePrimary(OfflineMapArea area) {
    final index = _areas.indexOf(area);
    if (index == -1) return;

    final next = switch (area.status) {
      OfflineMapStatus.notDownloaded => area.copyWith(
          status: OfflineMapStatus.downloading,
          progress: 0.12,
        ),
      OfflineMapStatus.queued => area.copyWith(
          status: OfflineMapStatus.downloading,
          progress: 0.08,
        ),
      OfflineMapStatus.downloading =>
          area.copyWith(status: OfflineMapStatus.downloaded, progress: 1),
      OfflineMapStatus.downloaded =>
          area.copyWith(status: OfflineMapStatus.notDownloaded, progress: 0),
      OfflineMapStatus.updateAvailable => area.copyWith(
          status: OfflineMapStatus.downloading,
          progress: 0.18,
        ),
    };

    _updateArea(index, next);
  }

  void _handleSecondary(OfflineMapArea area) {
    final index = _areas.indexOf(area);
    if (index == -1) return;

    final next = switch (area.status) {
      OfflineMapStatus.notDownloaded =>
          area.copyWith(status: OfflineMapStatus.queued, progress: 0),
      OfflineMapStatus.queued =>
          area.copyWith(status: OfflineMapStatus.notDownloaded, progress: 0),
      OfflineMapStatus.downloading =>
          area.copyWith(status: OfflineMapStatus.notDownloaded, progress: 0),
      OfflineMapStatus.downloaded => area,
      OfflineMapStatus.updateAvailable =>
          area.copyWith(status: OfflineMapStatus.downloaded, progress: 1),
    };

    _updateArea(index, next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.map_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Offline maps',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Download areas you need before you travel. We keep them fresh and ready even without signal.',
                style: TextStyle(color: AppColors.subtext, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _StorageSummaryCard(
                downloadedGb: _downloadedTotal,
                capacityGb: _storageBudgetGb,
                activeDownloads: _activeDownloads,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Pill(text: 'Download on Wi‑Fi'),
                  _Pill(text: 'Auto-refresh transit'),
                  _Pill(text: 'Keep background on'),
                ],
              ),
              const SizedBox(height: 16),
              ..._areas.map(
                (area) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OfflineMapCard(
                    area: area,
                    onPrimaryTap: () => _handlePrimary(area),
                    onSecondaryTap: () => _handleSecondary(area),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineMapCard extends StatelessWidget {
  const OfflineMapCard({
    super.key,
    required this.area,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final OfflineMapArea area;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  Color get _accent {
    return switch (area.status) {
      OfflineMapStatus.downloaded => AppColors.primary,
      OfflineMapStatus.updateAvailable => const Color(0xFF1D4ED8),
      OfflineMapStatus.downloading => const Color(0xFFF59E0B),
      OfflineMapStatus.queued => const Color(0xFF6B7280),
      OfflineMapStatus.notDownloaded => const Color(0xFF94A3B8),
    };
  }

  String get _statusLabel {
    return switch (area.status) {
      OfflineMapStatus.downloaded => 'Offline ready',
      OfflineMapStatus.updateAvailable => 'Update available',
      OfflineMapStatus.downloading => 'Downloading',
      OfflineMapStatus.queued => 'Queued',
      OfflineMapStatus.notDownloaded => 'Not downloaded',
    };
  }

  String get _primaryLabel {
    return switch (area.status) {
      OfflineMapStatus.downloaded => 'Remove',
      OfflineMapStatus.updateAvailable => 'Update now',
      OfflineMapStatus.downloading => 'Mark complete',
      OfflineMapStatus.queued => 'Start now',
      OfflineMapStatus.notDownloaded => 'Download',
    };
  }

  String get _secondaryLabel {
    return switch (area.status) {
      OfflineMapStatus.downloaded => 'Keep',
      OfflineMapStatus.updateAvailable => 'Later',
      OfflineMapStatus.downloading => 'Cancel',
      OfflineMapStatus.queued => 'Cancel',
      OfflineMapStatus.notDownloaded => 'Queue',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map_outlined, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      area.detail,
                      style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(label: _statusLabel, color: _accent),
                        const SizedBox(width: 10),
                        Text(
                          '${area.sizeGb.toStringAsFixed(2)} GB',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSecondaryTap,
                icon: const Icon(Icons.more_horiz, color: AppColors.subtext),
                tooltip: _secondaryLabel,
              ),
            ],
          ),
          if (area.status == OfflineMapStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: area.progress.clamp(0, 1),
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onPrimaryTap,
                  child: Text(
                    _primaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _accent.withValues(alpha: 0.45)),
                  ),
                  onPressed: onSecondaryTap,
                  child: Text(
                    _secondaryLabel,
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageSummaryCard extends StatelessWidget {
  const _StorageSummaryCard({
    required this.downloadedGb,
    required this.capacityGb,
    required this.activeDownloads,
  });

  final double downloadedGb;
  final double capacityGb;
  final int activeDownloads;

  @override
  Widget build(BuildContext context) {
    final used = downloadedGb.clamp(0.0, capacityGb);
    final progress = capacityGb == 0 ? 0.0 : (used / capacityGb).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Offline storage',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                '${used.toStringAsFixed(2)} / ${capacityGb.toStringAsFixed(1)} GB',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                activeDownloads > 0 ? Icons.cloud_download : Icons.offline_pin,
                color:
                    activeDownloads > 0 ? const Color(0xFFF59E0B) : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                activeDownloads > 0
                    ? '$activeDownloads download${activeDownloads > 1 ? 's' : ''} in queue'
                    : 'Ready to use offline',
                style: const TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.offline_pin, size: 16, color: AppColors.subtext),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
