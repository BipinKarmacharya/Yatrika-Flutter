import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/plan_screen_controller.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/plan_screen/widgets/destination_picker_field.dart';

class ManualTripBottomSheet extends StatefulWidget {
  final PlanScreenController controller;
  final VoidCallback onTripCreated;

  const ManualTripBottomSheet({
    super.key,
    required this.controller,
    required this.onTripCreated,
  });

  @override
  State<ManualTripBottomSheet> createState() => _ManualTripBottomSheetState();
}

class _ManualTripBottomSheetState extends State<ManualTripBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Detailed Trip',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Title
                  const Text(
                    'Trip Title',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(_titleController, 'e.g., Summer Vacation 2024'),
                  const SizedBox(height: 16),

                  // Destination
                  const Text(
                    'Destination',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DestinationPickerField(
                    controller: widget.controller.destinationController,
                    onTap: () => _onPickDestination(),
                  ),
                  const SizedBox(height: 16),

                  // Dates and Travelers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Number of Days',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              widget.controller.datesController,
                              'e.g., 7',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Travelers',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              widget.controller.travelersController,
                              'e.g., 2',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Budget
                  const Text(
                    'Budget (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    widget.controller.budgetController,
                    'e.g., 1500',
                    prefixIcon: Icons.attach_money_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Add any special requirements or notes...',
                        hintStyle: TextStyle(color: AppColors.subtext),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createDetailedTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Itinerary',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: AppColors.subtext, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.subtext),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDetailedTrip() async {
    if (_validateForm()) {
      await widget.controller.createDetailedTrip(
        title: _titleController.text,
        destination: widget.controller.destinationController.text,
        totalDays: int.tryParse(widget.controller.datesController.text),
        travelers: int.tryParse(widget.controller.travelersController.text),
        budget: double.tryParse(widget.controller.budgetController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      widget.onTripCreated();
    }
  }

  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trip title')),
      );
      return false;
    }

    if (widget.controller.destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return false;
    }

    return true;
  }

  void _onPickDestination() {
    // Implement destination picker logic here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Destination'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDestinationTile('Paris, France'),
              _buildDestinationTile('Tokyo, Japan'),
              _buildDestinationTile('Bali, Indonesia'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationTile(String destination) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(destination),
      onTap: () {
        Navigator.pop(context);
        widget.controller.destinationController.text = destination;
      },
    );
  }
}