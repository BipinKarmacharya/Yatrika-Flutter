import 'package:flutter/material.dart';
import 'package:tour_guide/core/services/local_notification_service.dart';
import '../../../../core/theme/app_colors.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  Future<void> _scheduleReminder(BuildContext context) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (selectedDate == null || !context.mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        now.add(const Duration(minutes: 5)),
      ),
    );

    if (selectedTime == null || !context.mounted) {
      return;
    }

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledAt.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future time for the reminder.'),
        ),
      );
      return;
    }

    final isScheduled = await LocalNotificationService.scheduleReminder(
      title: 'Yatrika Reminder',
      body: 'Your reminder time has arrived.',
      scheduledAt: scheduledAt,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isScheduled
              ? 'Reminder set for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)}'
              : 'Could not schedule reminder on this platform.',
        ),
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
              child: Row(
                children: const [
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
            onTap: () => _scheduleReminder(context),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.stroke),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: Color(0xFF606F81),
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
            onTap: onProfileTap,
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
