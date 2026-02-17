import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tour_guide/core/services/local_notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

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
      const Duration(seconds: 1),
      (_) => _refreshNotificationStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotificationStatus() async {
    if (_isProcessingDue) return;
    _isProcessingDue = true;
    try {
      final refreshedDue =
          await LocalNotificationService.getDueScheduledNotifications();
      final refreshedUpcoming =
          await LocalNotificationService.getUpcomingScheduledNotifications();

      if (!mounted) return;
      setState(() {
        _dueItems = refreshedDue;
        _upcomingItems = refreshedUpcoming;
        _dueCount = refreshedDue.length;
      });
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 220,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.stroke),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF86909C), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search places, trips, people',
                      style: TextStyle(color: Color(0xFF86909C), fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showUpcomingSchedules(context),
            onLongPress: () async {
              final info = await LocalNotificationService.getDebugInfo();
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Notification Debug'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enabled: ${info.notificationsEnabled}'),
                      Text('Exact alarm allowed: ${info.exactAlarmAllowed}'),
                      Text('Pending in plugin: ${info.pendingNotificationCount}'),
                      Text('Stored upcoming: ${info.storedUpcomingCount}'),
                      Text(
                        'Next upcoming: ${info.nextUpcomingAt?.toLocal().toString() ?? 'None'}',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.stroke),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: Color(0xFF606F81),
                    ),
                  ),
                  if (_dueCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _dueCount > 99 ? '99+' : '$_dueCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Icon(
              Icons.language,
              size: 20,
              color: Color(0xFF606F81),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
              ),
            ),
          ),
        ],
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
            .where((i) =>
                !i.scheduledAt.isBefore(now.subtract(const Duration(days: 1))))
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
