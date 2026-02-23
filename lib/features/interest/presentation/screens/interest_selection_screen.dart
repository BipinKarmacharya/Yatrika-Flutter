import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({
    super.key,
    this.onSkip,
    this.onContinue,
    this.initialSelections = const [],
  });

  final VoidCallback? onSkip;
  final ValueChanged<List<String>>? onContinue;
  final List<String> initialSelections;

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  static const List<_InterestOption> _options = [
    _InterestOption('Adventure', Icons.hiking_rounded),
    _InterestOption('Hiking & Trekking', Icons.terrain_rounded),
    _InterestOption('Cultural Tours', Icons.account_balance_rounded),
    _InterestOption('Spiritual Sites', Icons.self_improvement_rounded),
    _InterestOption('Food & Cuisine', Icons.restaurant_rounded),
    _InterestOption('Wildlife Safari', Icons.pets_rounded),
    _InterestOption('Photography', Icons.camera_alt_rounded),
    _InterestOption('Road Trips', Icons.alt_route_rounded),
    _InterestOption('Beach Escape', Icons.beach_access_rounded),
    _InterestOption('Luxury Stay', Icons.hotel_rounded),
    _InterestOption('City Exploration', Icons.location_city_rounded),
    _InterestOption('Festivals & Events', Icons.celebration_rounded),
  ];

  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelections.toSet();
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }
    Navigator.maybePop(context);
  }

  void _handleContinue() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose at least one interest.')),
      );
      return;
    }

    final selectedList = _selected.toList()..sort();
    if (widget.onContinue != null) {
      widget.onContinue!(selectedList);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${selectedList.length} interests')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton(onPressed: _handleSkip, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose Your Interests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selected.isEmpty
                    ? 'Pick your tourist interests to personalize your travel experience.'
                    : '${_selected.length} selected',
                style: const TextStyle(fontSize: 14, color: AppColors.subtext),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _options.map((option) {
                      final selected = _selected.contains(option.label);
                      return FilterChip(
                        showCheckmark: false,
                        selected: selected,
                        onSelected: (_) => _toggle(option.label),
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: selected
                              ? AppColors.primary
                              : Colors.white,
                          child: Icon(
                            option.icon,
                            size: 15,
                            color: selected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        label: Text(
                          option.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.text,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFE8F8EF),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.stroke,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _InterestOption {
  const _InterestOption(this.label, this.icon);

  final String label;
  final IconData icon;
}
