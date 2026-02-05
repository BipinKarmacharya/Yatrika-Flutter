import 'package:flutter/material.dart';

class ExploreGridDelegate {
  static SliverGridDelegateWithFixedCrossAxisCount getDelegate(BuildContext context, bool isDest) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio = isDest ? 0.7 : 1.3;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
      childAspectRatio = isDest ? 0.65 : 1.2;
    } else {
      crossAxisCount = 3;
      childAspectRatio = isDest ? 0.6 : 1.1;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }
}