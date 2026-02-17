 







import 'package:flutter/material.dart';
import 'package:tour_guide/core/services/local_notification_service.dart';

import '../../../../core/theme/app_colors.dart';
import 'itinerary_screen.dart';

class PlanWithAIScreen extends StatefulWidget {
  const PlanWithAIScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PlanWithAIScreen> createState() => _PlanWithAIScreenState();
}

class _PlanWithAIScreenState extends State<PlanWithAIScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _datesController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _travelersController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _paceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedDestination;
  DateTime? _selectedTripDate;
  TimeOfDay? _selectedTripTime;
  final Set<String> _selectedVibes = {};

  final List<String> _suggestedDestinations = ['Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini'];
  final List<String> _vibeOptions = ['Food', 'Nature', 'Culture', 'Adventure', 'Nightlife', 'Family'];

  @override
  void initState() {
    super.initState();
    // Pre-fill a valid upcoming date/time so reminder scheduling has usable values.
    final initial = DateTime.now().add(const Duration(minutes: 5));
    _selectedTripDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTripTime = TimeOfDay.fromDateTime(initial);
    _datesController.text =
        '${_selectedTripDate!.year}-${_selectedTripDate!.month.toString().padLeft(2, '0')}-${_selectedTripDate!.day.toString().padLeft(2, '0')}';
    _timeController.text =
        '${_selectedTripTime!.hour.toString().padLeft(2, '0')}:${_selectedTripTime!.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _datesController.dispose();
    _timeController.dispose();
    _travelersController.dispose();
    _budgetController.dispose();
    _paceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: AppColors.text, size: 24),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan with AI',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Tell us your vibe and constraints',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search destination
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.subtext, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _destinationController,
                              decoration: const InputDecoration(
                                hintText: 'Where do you want to go?',
                                hintStyle: TextStyle(
                                  color: AppColors.subtext,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const Icon(Icons.mic_none, color: AppColors.subtext, size: 22),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Suggested destinations
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _suggestedDestinations.map((destination) {
                        final isSelected = _selectedDestination == destination;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDestination = isSelected ? null : destination;
                              if (!isSelected) {
                                _destinationController.text = destination;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE6F6EE) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.stroke,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: isSelected ? AppColors.primary : AppColors.subtext,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  destination,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.primary : AppColors.text,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Trip basics section
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          const Text(
                            'Trip basics',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _InputField(
                                  controller: _datesController,
                                  hint: 'Trip start date',
                                  readOnly: true,
                                  onTap: () => _pickTripDate(context),
                                  suffixIcon: Icons.calendar_today_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InputField(
                                  controller: _timeController,
                                  hint: 'Trip time',
                                  readOnly: true,
                                  onTap: () => _pickTripTime(context),
                                  suffixIcon: Icons.schedule_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _InputField(
                                  controller: _travelersController,
                                  hint: 'Travelers',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InputField(
                                  controller: _budgetController,
                                  hint: 'Budget',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _paceController,
                            hint: 'Pace (relaxed • mixed • packed)',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Your vibe section
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          const Text(
                            'Your vibe',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _vibeOptions.map((vibe) {
                              final isSelected = _selectedVibes.contains(vibe);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedVibes.remove(vibe);
                                    } else {
                                      _selectedVibes.add(vibe);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE6F6EE) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.stroke,
                                    ),
                                  ),
                                  child: Text(
                                    vibe,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.text,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.stroke),
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Anything we should know? (diet, mobility, must-sees)',
                                hintStyle: TextStyle(
                                  color: AppColors.subtext,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedTripDate == null || _selectedTripTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select trip date and time first.'),
                              ),
                            );
                            return;
                          }
                          try {
                            await _scheduleTripDateReminder(context);
                          } catch (e) {
                            debugPrint('Reminder scheduling failed: $e');
                          }
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ItineraryScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Generate itinerary',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tip text
                    const Text(
                      'Tip: Start by choosing a destination above. We\'ll tailor days, routes, and time slots to match your vibe.',
                      style: TextStyle(
                        color: AppColors.subtext,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTripDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTripDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;

    setState(() {
      _selectedTripDate = picked;
      _datesController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickTripTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTripTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked == null) return;

    setState(() {
      _selectedTripTime = picked;
      _timeController.text = picked.format(context);
    });
  }

  Future<void> _scheduleTripDateReminder(BuildContext context) async {
    try {
      if (_selectedTripDate == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select trip date to set reminder.'),
            ),
          );
        }
        return;
      }

      await LocalNotificationService.requestPermissions();

      final now = DateTime.now();
      final destination =
          _destinationController.text.trim().isEmpty
              ? 'your destination'
              : _destinationController.text.trim();

      final selectedTime =
          _selectedTripTime ?? const TimeOfDay(hour: 9, minute: 0);

      DateTime tripStart = DateTime(
        _selectedTripDate!.year,
        _selectedTripDate!.month,
        _selectedTripDate!.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (tripStart.isBefore(now)) {
        tripStart = now.add(const Duration(minutes: 1));
      }

      int scheduledCount = 0;
      final reminderOffsets = <Duration>[
        const Duration(days: 1),
        const Duration(minutes: 60),
        const Duration(minutes: 10),
        Duration.zero,
      ];

      for (final offset in reminderOffsets) {
        final scheduledAt = tripStart.subtract(offset);
        if (!scheduledAt.isAfter(now)) {
          continue;
        }

        String body;
        if (offset.inDays >= 1) {
          body = 'Your trip to $destination starts tomorrow.';
        } else if (offset == Duration.zero) {
          body = 'Your trip to $destination starts now.';
        } else {
          body = 'Your trip to $destination starts in ${offset.inMinutes} minutes.';
        }

        final scheduled = await LocalNotificationService.scheduleReminder(
          title: 'Yatrika Trip Reminder',
          body: body,
          scheduledAt: scheduledAt,
        );
        if (scheduled) {
          scheduledCount += 1;
        }
      }

      if (!context.mounted) return;

      if (scheduledCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not schedule reminder. Check notification permission.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$scheduledCount reminders scheduled before trip start.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Trip reminder setup failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification setup failed: $e'),
          ),
        );
      }
    }
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.subtext,
              fontSize: 13,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, size: 18, color: AppColors.subtext),
          ),
        ),
      ),
    );
  }
}
