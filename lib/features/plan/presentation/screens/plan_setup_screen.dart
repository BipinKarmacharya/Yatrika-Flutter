import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/plan/logic/trip_creator_provider.dart';
import 'manual_itinerary_builder_screen.dart';

class PlanSetupScreen extends StatefulWidget {
  const PlanSetupScreen({super.key});

  @override
  State<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends State<PlanSetupScreen> {
  DateTime? _startDate;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int _totalDays = 3; // Default to 3 for better UX
  String _selectedTheme = 'Adventure';

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Adventure', 'icon': Icons.terrain},
    {'name': 'Cultural', 'icon': Icons.museum},
    {'name': 'Relaxation', 'icon': Icons.spa},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Nature', 'icon': Icons.wb_sunny},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Plan New Trip", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: "Basics",
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: "Trip Title",
                      hint: "e.g., Summer in Pokhara",
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 16),
                    _buildThemeDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: "Schedule",
                child: Column(
                  children: [
                    _buildDatePicker(),
                    const Divider(height: 32),
                    _buildDurationPicker(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Create Memories", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const Text("Where to next?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400])),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildThemeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTheme,
      decoration: InputDecoration(
        labelText: "Trip Theme",
        prefixIcon: const Icon(Icons.palette, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: _themes.map((t) => DropdownMenuItem<String>(
        value: t['name'],
        child: Row(children: [Icon(t['icon'], size: 20), const SizedBox(width: 8), Text(t['name'])]),
      )).toList(),
      onChanged: (v) => setState(() => _selectedTheme = v!),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) setState(() => _startDate = picked);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_month, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Departure Date", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_startDate == null ? "Not set" : "${_startDate!.day} ${_getMonth(_startDate!.month)} ${_startDate!.year}"),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDurationPicker() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.timer, color: Colors.orange),
        ),
        const SizedBox(width: 16),
        const Text("Duration", style: TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        _counterButton(Icons.remove, () => setState(() => _totalDays > 1 ? _totalDays-- : null)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("$_totalDays Days", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        _counterButton(Icons.add, () => setState(() => _totalDays++)),
      ],
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!)),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        onPressed: _proceedToBuilder,
        child: const Text("Plan Activities →", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _proceedToBuilder() {
    if (_formKey.currentState!.validate()) {
      context.read<TripCreatorProvider>().initNewTrip(
        title: _titleController.text,
        description: _descController.text,
        totalDays: _totalDays,
        theme: _selectedTheme,
        startDate: _startDate,
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualItineraryBuilderScreen()));
    }
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}