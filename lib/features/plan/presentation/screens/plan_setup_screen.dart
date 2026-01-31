import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/plan/logic/trip_creator_provider.dart';
// We will create this next
import 'manual_itinerary_builder_screen.dart'; 

class PlanSetupScreen extends StatefulWidget {
  const PlanSetupScreen({super.key});

  @override
  State<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends State<PlanSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int _totalDays = 1;
  String _selectedTheme = 'Adventure';

  final List<String> _themes = ['Adventure', 'Cultural', 'Relaxation', 'Food', 'Nature'];

  void _proceedToBuilder() {
    if (_formKey.currentState!.validate()) {
      // 1. Initialize the draft in our Provider
      context.read<TripCreatorProvider>().initNewTrip(
            title: _titleController.text,
            description: _descController.text,
            totalDays: _totalDays,
            theme: _selectedTheme,
          );

      // 2. Navigate to the actual builder screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManualItineraryBuilderScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plan New Trip")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text("Where are we going?", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Trip Title",
                hintText: "e.g., Summer in Pokhara",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Please enter a title" : null,
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _selectedTheme,
              decoration: const InputDecoration(labelText: "Theme", border: OutlineInputBorder()),
              items: _themes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTheme = v!),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Duration (Days): ", style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _totalDays > 1 ? _totalDays-- : null),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text("$_totalDays", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _totalDays++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _proceedToBuilder,
              child: const Text("Start Planning", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}