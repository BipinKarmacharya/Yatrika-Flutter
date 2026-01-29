import 'package:flutter/material.dart';

class AddActivityDialog extends StatefulWidget {
  final List<dynamic> availableDestinations;
  final Function(Map<String, dynamic>) onDestinationSelected;

  const AddActivityDialog({
    super.key,
    required this.availableDestinations,
    required this.onDestinationSelected,
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  List<dynamic> _filteredDestinations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredDestinations = List.from(widget.availableDestinations);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDestinations = widget.availableDestinations
          .where((d) => d['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search Destination"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Search...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _filteredDestinations.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(_filteredDestinations[i]['name']),
                onTap: () {
                  widget.onDestinationSelected(_filteredDestinations[i]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}