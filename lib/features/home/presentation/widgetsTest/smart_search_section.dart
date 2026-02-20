import 'package:flutter/material.dart';
import '../widgets/smart_search_bar.dart';

class SmartSearchSection extends StatefulWidget {
  final bool isProcessing;
  final Function(String) onSearch;

  const SmartSearchSection({super.key, required this.isProcessing, required this.onSearch});

  @override
  State<SmartSearchSection> createState() => _SmartSearchSectionState();
}

class _SmartSearchSectionState extends State<SmartSearchSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SmartSearchBar(
            controller: _controller,
            isProcessing: widget.isProcessing,
            onSubmitted: widget.onSearch,
          ),
        ),
        _buildChips(),
      ],
    );
  }

  Widget _buildChips() {
    final prompts = ["🏔️ Trekking", "🧘 Yoga", "🍲 Food", "📸 Photo"];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(prompts[i]),
            backgroundColor: Colors.white,
            onPressed: () => widget.onSearch("Plan a ${prompts[i]} trip"),
          ),
        ),
      ),
    );
  }
}