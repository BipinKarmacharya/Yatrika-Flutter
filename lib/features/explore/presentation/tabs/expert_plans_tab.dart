import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/public_trip_card.dart';
import '../widgets/explore_grid_delegate.dart';

class ExpertPlansTab extends StatefulWidget {
  const ExpertPlansTab({super.key});

  @override
  State<ExpertPlansTab> createState() => _ExpertPlansTabState();
}

class _ExpertPlansTabState extends State<ExpertPlansTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid build-phase side effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItineraryProvider>().fetchExpertTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        final expertPlans = provider.expertTemplates;
        final isLoading = provider.isLoading && expertPlans.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        return RefreshIndicator(
          onRefresh: provider.fetchExpertTemplates,
          child: isMobile
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expertPlans.length,
                  itemBuilder: (context, index) {
                    final plan = expertPlans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PublicTripCard(itinerary: plan),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: ExploreGridDelegate.getDelegate(context, false),
                  itemCount: expertPlans.length,
                  itemBuilder: (context, index) {
                    final plan = expertPlans[index];
                    return PublicTripCard(itinerary: plan);
                  },
                ),
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
// import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
// import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
// import 'package:tour_guide/features/itinerary/presentation/widgets/public_trip_card.dart';
// import '../widgets/explore_grid_delegate.dart';

// class ExpertPlansTab extends StatefulWidget {
//   const ExpertPlansTab({super.key});

//   @override
//   State<ExpertPlansTab> createState() => _ExpertPlansTabState();
// }

// class _ExpertPlansTabState extends State<ExpertPlansTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   List<Itinerary> _expertPlans = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadExpertPlans();
//   }

//   Future<void> _loadExpertPlans() async {
//     setState(() => _isLoading = true);
//     try {
//       final data = await ItineraryService.getExpertTemplates();
//       final provider = context.read<ItineraryProvider>();

//       // Register these with provider so likes/saves are tracked globally
//       for (final plan in data) {
//         if (!provider.publicPlans.any((it) => it.id == plan.id)) {
//           provider.updateItineraryInAllLists(plan);
//         }
//       }
//       setState(() => _expertPlans = data);
//     } catch (e) {
//       debugPrint("Error: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Consumer<ItineraryProvider>(
//       builder: (context, provider, child) {
//         // Automatically sync the local list with updated provider states
//         final displayedPlans = provider.syncExpertPlans(_expertPlans);

//         if (_isLoading) return const Center(child: CircularProgressIndicator());

//         final screenWidth = MediaQuery.of(context).size.width;
//         final isMobile = screenWidth < 600;

//         return RefreshIndicator(
//           onRefresh: _loadExpertPlans,
//           child: isMobile
//               // ✅ LIST for mobile (dynamic height)
//               ? ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: displayedPlans.length,
//                   itemBuilder: (context, index) {
//                     final plan = displayedPlans[index];
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: PublicTripCard(itinerary: plan),
//                     );
//                   },
//                 )
//               // ✅ GRID only for tablet / desktop
//               : GridView.builder(
//                   padding: const EdgeInsets.all(16),
//                   gridDelegate: ExploreGridDelegate.getDelegate(context, false),
//                   itemCount: displayedPlans.length,
//                   itemBuilder: (context, index) {
//                     final plan = displayedPlans[index];
//                     return PublicTripCard(itinerary: plan);
//                   },
//                 ),
//         );
//       },
//     );
//   }
// }
