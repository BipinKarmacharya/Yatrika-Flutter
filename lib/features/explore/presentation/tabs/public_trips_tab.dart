import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import '../widgets/explore_grid_delegate.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/public_trip_card.dart';

class PublicTripsTab extends StatefulWidget {
  const PublicTripsTab({super.key});

  @override
  State<PublicTripsTab> createState() => _PublicTripsTabState();
}

class _PublicTripsTabState extends State<PublicTripsTab> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Fetch once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItineraryProvider>().fetchPublicPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        if (provider.isPublicLoading && provider.publicPlans.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.publicPlans.isEmpty) {
          return const Center(child: Text("No public trips found."));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPublicPlans(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: ExploreGridDelegate.getDelegate(context, false),
            itemCount: provider.publicPlans.length,
            itemBuilder: (context, index) {
              final trip = provider.publicPlans[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ItineraryDetailScreen(itinerary: trip),
                  ),
                ),
                child: PublicTripCard(itinerary: trip),
              );
            },
          ),
        );
      },
    );
  }
}
