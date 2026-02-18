import 'package:flutter/material.dart';

class ExploreGridDelegate {
  static SliverGridDelegate getDelegate(
      BuildContext context, bool isDest) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    if (!isDest) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      );
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 0.7,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
    );
  }
}