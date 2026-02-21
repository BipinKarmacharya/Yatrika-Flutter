import 'package:flutter/material.dart';
import 'package:tour_guide/features/plan/data/service/ml_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../itinerary/presentation/screens/itinerary_screen.dart';

class PlanWithAIScreen extends StatefulWidget {
  const PlanWithAIScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PlanWithAIScreen> createState() => _PlanWithAIScreenState();
}

class _PlanWithAIScreenState extends State<PlanWithAIScreen> {
  // Controllers for text fields
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _datesController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  // final TextEditingController _travelersController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  // final TextEditingController _paceController = TextEditingController();
  // final TextEditingController _notesController = TextEditingController();

  // State variables
  String? _selectedDestination;
  DateTime? _selectedTripDate;
  TimeOfDay? _selectedTripTime;
  final Set<String> _selectedVibes = {};
  bool _isLoading = false;

  // Static data
  final List<String> _suggestedDestinations = [
    'Kathmandu',
    'Pokhara',
    'Chitwan',
    'Butwal',
  ];
  final List<String> _vibeOptions = [
    'Food',
    'Nature',
    'Culture',
    'Adventure',
    'Nightlife',
    'Family',
  ];
  final List<String> _budgetOptions = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    // Pre‑fill date/time for reminder demo (5 minutes from now)
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
    _daysController.dispose();
    _datesController.dispose();
    _timeController.dispose();
    // _travelersController.dispose();
    _budgetController.dispose();
    // _paceController.dispose();
    // _notesController.dispose();
    super.dispose();
  }

  // ---------- AI Generation ----------
  Future<void> _generateItinerary() async {
    // Basic validation
    if (_destinationController.text.isEmpty) {
      _showError('Please enter a destination');
      return;
    }
    if (_daysController.text.isEmpty ||
        int.tryParse(_daysController.text) == null) {
      _showError('Please enter a valid number of days');
      return;
    }
    if (_selectedVibes.isEmpty) {
      _showError('Please select at least one vibe');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final DateTime tripStartDate = _selectedTripDate ?? DateTime.now();
      final result = await MLService.getPrediction(
        city: _destinationController.text,
        budget: _budgetController.text.isEmpty
            ? 'Medium'
            : _budgetController.text,
        interests: _selectedVibes.map((v) => v.toLowerCase()).toList(),
        days: int.parse(_daysController.text),
      );

      if (!mounted) return;

      // Navigate to ItineraryScreen with real data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItineraryScreen(
            itinerary: result,
            startDate: tripStartDate,
            budget: _budgetController.text.isEmpty
                ? 'Medium'
                : _budgetController.text,
            selectedVibes: _selectedVibes.toList(),
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ---------- Date/Time Pickers ----------
  Future<void> _pickTripDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTripDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _updateDateController(picked);
      });
    }
  }

  void _updateDateController(DateTime picked) {
    _selectedTripDate = picked;
    // Short format: "Feb 20, 2026" or "20 Feb 2026"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    _datesController.text =
        "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
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

  // ---------- UI Build ----------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDestinationSearch(),
                        const SizedBox(height: 14),
                        _buildSuggestedDestinations(),
                        const SizedBox(height: 20),
                        _buildTripBasics(),
                        const SizedBox(height: 16),
                        _buildVibeSection(),
                        const SizedBox(height: 20),
                        _buildGenerateButton(),
                        const SizedBox(height: 14),
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onBack != null
                ? widget.onBack!()
                : Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.text, size: 24),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan with AI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Text(
                'Tell us your vibe and constraints',
                style: TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDestinationSearch() {
    return Container(
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
                hintStyle: TextStyle(color: AppColors.subtext, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.mic_none, color: AppColors.subtext, size: 22),
        ],
      ),
    );
  }

  Widget _buildSuggestedDestinations() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _suggestedDestinations.map((destination) {
        final isSelected = _selectedDestination == destination;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDestination = isSelected ? null : destination;
              if (!isSelected) _destinationController.text = destination;
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
    );
  }

  Widget _buildTripBasics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 14),
          // Row 1: Days + Budget (dropdown)
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _daysController,
                  hint: 'Number of Days',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _budgetController.text.isEmpty
                          ? null
                          : _budgetController.text,
                      hint: const Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subtext,
                        ),
                      ),
                      isExpanded: true,
                      items: _budgetOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _budgetController.text = val!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Date + Time
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _datesController,
                  hint: 'Start date',
                  readOnly: true,
                  onTap: () => _pickTripDate(context),
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _timeController,
                  hint: 'Start time',
                  readOnly: true,
                  onTap: () => _pickTripTime(context),
                  suffixIcon: Icons.schedule_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildVibeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateItinerary,
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
    );
  }
}

// Reusable input field widget (supports read‑only, taps, and suffix icons)
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.subtext, fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 0,
            ),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, size: 18, color: AppColors.subtext),
          ),
        ),
      ),
    );
  }
}
