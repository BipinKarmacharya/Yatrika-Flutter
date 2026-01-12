import 'package:flutter/material.dart';

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
  final TextEditingController _travelersController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _paceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedDestination;
  final Set<String> _selectedVibes = {};

  final List<String> _suggestedDestinations = ['Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini'];
  final List<String> _vibeOptions = ['Food', 'Nature', 'Culture', 'Adventure', 'Nightlife', 'Family'];

  @override
  void dispose() {
    _destinationController.dispose();
    _datesController.dispose();
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
                                  hint: 'Dates (flexible ok)',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InputField(
                                  controller: _travelersController,
                                  hint: 'Travelers',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _InputField(
                                  controller: _budgetController,
                                  hint: 'Budget',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InputField(
                                  controller: _paceController,
                                  hint: 'Pace (relaxed • mixed • packed)',
                                ),
                              ),
                            ],
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
                        onPressed: () {
                          debugPrint('Generate button tapped');
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
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.subtext,
              fontSize: 13,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
