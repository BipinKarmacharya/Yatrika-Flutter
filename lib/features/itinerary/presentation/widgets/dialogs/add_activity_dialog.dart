import 'package:flutter/material.dart';

class AddActivityDialog extends StatefulWidget {
  final List<dynamic> availableDestinations;
  final Function(Map<String, dynamic> data) onDestinationSelected;

  const AddActivityDialog({
    super.key,
    required this.availableDestinations,
    required this.onDestinationSelected,
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  Map<String, dynamic>? _selectedDestination;
  String _activityType = "VISIT"; // Default type
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _notesController = TextEditingController();
  final List<String> _types = ["VISIT", "MEAL", "TRANSPORT", "HOTEL", "OTHER"];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_selectedDestination == null ? "Select Destination" : "Activity Details"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedDestination == null) ...[
              // Search UI
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Search destinations..."),
                onChanged: (value) {
                  setState(() { /* Implement search filtering as you had before */ });
                },
              ),
              const SizedBox(height: 10),
              ...widget.availableDestinations.take(5).map((d) => ListTile(
                title: Text(d['name']),
                onTap: () => setState(() => _selectedDestination = d),
              )),
            ] else ...[
              // Configuration UI
              ListTile(
                title: Text(_selectedDestination!['name']),
                subtitle: const Text("Selected Location"),
                trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _selectedDestination = null)),
              ),
              DropdownButtonFormField<String>(
                initialValue: _activityType,
                decoration: const InputDecoration(labelText: "Activity Type"),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _activityType = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Start Time"),
                trailing: Text(_startTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: _startTime);
                  if (time != null) setState(() => _startTime = time);
                },
              ),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes (Optional)"),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        if (_selectedDestination != null)
          ElevatedButton(
            onPressed: () {
              // Format time to HH:mm:ss for Backend
              final formattedTime = "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00";
              
              widget.onDestinationSelected({
                'destination': _selectedDestination,
                'activityType': _activityType,
                'startTime': formattedTime,
                'notes': _notesController.text,
              });
              Navigator.pop(context);
            },
            child: const Text("Add to Plan"),
          ),
      ],
    );
  }
}