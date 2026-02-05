import 'package:flutter/material.dart';

class HomeShimmer extends StatelessWidget {
  final bool isLarge;
  const HomeShimmer({super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLarge ? 280 : 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.only(left: 16),
        itemBuilder: (context, index) => Container(
          width: isLarge ? 260 : 180,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}