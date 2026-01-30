import 'package:flutter/material.dart';

class DestinationPickerField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final String hint;
  final bool readOnly;

  const DestinationPickerField({
    super.key,
    required this.controller,
    required this.onTap,
    this.hint = "Select Destination",
    this.readOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF8391A1),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF35C2C1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}