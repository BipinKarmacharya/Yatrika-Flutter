import 'package:flutter/material.dart';
import '../tabs/destination_tab.dart';
import '../tabs/expert_plans_tab.dart';
import '../tabs/public_trips_tab.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Explore',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF009688),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF009688),
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Destinations"),
              Tab(text: "Expert Plans"),
              Tab(text: "Community"),
            ],
          ),
        ),
        // TabBarView allows the user to swipe left/right between the tabs
        body: const TabBarView(
          children: [
            DestinationTab(),
            ExpertPlansTab(),
            PublicTripsTab(),
          ],
        ),
      ),
    );
  }
}