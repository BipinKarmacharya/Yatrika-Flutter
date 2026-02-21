import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class DaySelector extends StatelessWidget {
  final int totalDays;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final DateTime? startDate; // ADDED: Optional start date

  const DaySelector({
    super.key,
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
    this.startDate, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced to accommodate text better
      height: 70, // Slightly increased height for two lines of text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalDays,
        itemBuilder: (context, index) {
          int dayNumber = index + 1;
          bool isSelected = selectedDay == dayNumber;
          
          // Calculate Date Logic
          String topText = "Day";
          String bottomText = "$dayNumber";

          if (startDate != null) {
            final date = startDate!.add(Duration(days: index));
            final weekdays = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
            topText = weekdays[date.weekday];
            bottomText = "${date.day}";
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onDaySelected(dayNumber),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60, // Fixed width looks better for circular/square bubbles
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                      : [],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topText,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      bottomText,
                      style: TextStyle(
                        fontSize: 18,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}