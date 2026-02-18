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
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedDestination;
  bool _isLoading = false;
  final Set<String> _selectedVibes = {};

  final List<String> _suggestedDestinations = ['Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini'];
  final List<String> _vibeOptions = ['Nature', 'Culture', 'Adventure', 'Food', 'Nightlife', 'Family'];
  final List<String> _budgetOptions = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _destinationController.dispose();
    _daysController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    // Basic Validation
    if (_destinationController.text.isEmpty) {
      _showError('Please enter a destination');
      return;
    }
    if (_daysController.text.isEmpty || int.tryParse(_daysController.text) == null) {
      _showError('Please enter a valid number of days');
      return;
    }
    if (_selectedVibes.isEmpty) {
      _showError('Please select at least one vibe');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await MLService.getPrediction(
        city: _destinationController.text,
        budget: _budgetController.text.isEmpty ? "Medium" : _budgetController.text,
        interests: _selectedVibes.toList(),
        days: int.parse(_daysController.text),
      );

      if (!mounted) return;

      // Navigate to ItineraryScreen with real data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItineraryScreen(
            itineraryData: result,
            city: _destinationController.text,
            days: int.parse(_daysController.text),
            budget: _budgetController.text.isEmpty ? "Medium" : _budgetController.text,
            interests: _selectedVibes.toList(),
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
                          'Tip: We\'ll tailor days, routes, and time slots to match your vibe.',
                          style: TextStyle(color: AppColors.subtext, fontSize: 13),
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
            onTap: () => widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.text, size: 24),
                Text('Back', style: TextStyle(color: AppColors.text, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan with AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Tell us your vibe and constraints', style: TextStyle(color: AppColors.subtext, fontSize: 13)),
            ],
          ),
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
              ),
            ),
          ),
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
              _destinationController.text = isSelected ? "" : destination;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE6F6EE) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.stroke),
            ),
            child: Text(
              destination,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.text,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip basics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _InputField(controller: _daysController, hint: 'Number of Days', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _budgetController.text.isEmpty ? null : _budgetController.text,
                      hint: const Text("Budget", style: TextStyle(fontSize: 13, color: AppColors.subtext)),
                      isExpanded: true,
                      items: _budgetOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setState(() => _budgetController.text = val!),
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

  Widget _buildVibeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your vibe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _vibeOptions.map((vibe) {
              final isSelected = _selectedVibes.contains(vibe.toLowerCase());
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected ? _selectedVibes.remove(vibe.toLowerCase()) : _selectedVibes.add(vibe.toLowerCase());
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE6F6EE) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.stroke),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Generate itinerary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.controller, required this.hint, this.keyboardType});
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.subtext, fontSize: 13),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}