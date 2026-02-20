import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tour_guide/core/services/local_notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key}); // Removed onProfileTap since it's in BottomNav

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  int _dueCount = 0;
  List<ScheduledNotification> _dueItems = const [];
  List<ScheduledNotification> _upcomingItems = const [];
  Timer? _pollTimer;
  bool _isProcessingDue = false;

  @override
  void initState() {
    super.initState();
    _refreshNotificationStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshNotificationStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotificationStatus() async {
    if (_isProcessingDue || !mounted) return;
    _isProcessingDue = true;
    try {
      final refreshedDue =
          await LocalNotificationService.getDueScheduledNotifications();
      final refreshedUpcoming =
          await LocalNotificationService.getUpcomingScheduledNotifications();

      if (mounted) {
        setState(() {
          _dueItems = refreshedDue;
          _upcomingItems = refreshedUpcoming;
          _dueCount = refreshedDue.length;
        });
      }
    } finally {
      _isProcessingDue = false;
    }
  }


  Future<void> _showUpcomingSchedules(BuildContext context) async {
    await _refreshNotificationStatus();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => _UpcomingNotificationsDialog(
        dueItems: _dueItems,
        upcomingItems: _upcomingItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Branding & Location (The "Smart" part)
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.map_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Explore",
                    style: TextStyle(color: AppColors.subtext, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Text(
                        "Butwal, Nepal",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // 2. Action Icons (Notifications & Language)
          Row(
            children: [
              _buildNotificationIcon(),
              const SizedBox(width: 8),
              _buildLanguageIcon(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () => _showUpcomingSchedules(context),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
            if (_dueCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    // border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageIcon() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Icon(
        Icons.translate_rounded,
        size: 20,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _UpcomingNotificationsDialog extends StatefulWidget {
  const _UpcomingNotificationsDialog({
    required this.dueItems,
    required this.upcomingItems,
  });

  final List<ScheduledNotification> dueItems;
  final List<ScheduledNotification> upcomingItems;

  @override
  State<_UpcomingNotificationsDialog> createState() =>
      _UpcomingNotificationsDialogState();
}

class _UpcomingNotificationsDialogState
    extends State<_UpcomingNotificationsDialog> {
  late List<ScheduledNotification> _dueItems;
  late List<ScheduledNotification> _upcomingItems;

  @override
  void initState() {
    super.initState();
    _dueItems = List<ScheduledNotification>.from(widget.dueItems);
    _upcomingItems = List<ScheduledNotification>.from(widget.upcomingItems);
    _startTicker();
  }

  void _startTicker() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        final now = DateTime.now();
        _upcomingItems = _upcomingItems
            .where((i) => i.scheduledAt.isAfter(now))
            .toList();
        _dueItems = _dueItems
            .where(
              (i) => !i.scheduledAt.isBefore(
                now.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
      });
      return mounted;
    });
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Due now';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [..._dueItems, ..._upcomingItems];

    return AlertDialog(
      title: const Text('Upcoming Notifications'),
      content: SizedBox(
        width: 320,
        child: allItems.isEmpty
            ? const Text('No scheduled notifications yet.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: allItems.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  final isDue = index < _dueItems.length;
                  final remaining = item.scheduledAt.difference(DateTime.now());
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(item.body, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        isDue ? 'Due' : 'In ${_formatRemaining(remaining)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}