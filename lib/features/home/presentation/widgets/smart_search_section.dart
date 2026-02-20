import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'smart_search_bar.dart'; // The simple bar widget we made earlier

class SmartSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isProcessing;
  final Function(String) onSearch;

  const SmartSearchSection({
    super.key, 
    required this.controller, 
    required this.isProcessing, 
    required this.onSearch
  });

  @override
  Widget build(BuildContext context) {
    final prompts = ["🏔️ Trekking", "🧘 Yoga", "🍲 Food", "📸 Photo"];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SmartSearchBar(
            controller: controller,
            isProcessing: isProcessing,
            onSubmitted: onSearch,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: prompts.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(prompts[i]),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.stroke),
                onPressed: () => onSearch("Plan a ${prompts[i]} trip"),
              ),
            ),
          ),
        ),
      ],
    );
  }
}