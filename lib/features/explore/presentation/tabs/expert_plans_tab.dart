import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/data/services/itinerary_service.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/public_trip_card.dart';
import '../widgets/explore_grid_delegate.dart';

class ExpertPlansTab extends StatefulWidget {
  const ExpertPlansTab({super.key});

  @override
  State<ExpertPlansTab> createState() => _ExpertPlansTabState();
}

class _ExpertPlansTabState extends State<ExpertPlansTab> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  List<Itinerary> _expertPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpertPlans();
  }

  Future<void> _loadExpertPlans() async {
    setState(() => _isLoading = true);
    try {
      final data = await ItineraryService.getExpertTemplates();
      final provider = context.read<ItineraryProvider>();
      
      // Register these with provider so likes/saves are tracked globally
      for (final plan in data) {
        if (!provider.publicPlans.any((it) => it.id == plan.id)) {
          provider.updateItineraryInAllLists(plan);
        }
      }
      setState(() => _expertPlans = data);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        // Automatically sync the local list with updated provider states
        final displayedPlans = provider.syncExpertPlans(_expertPlans);

        if (_isLoading) return const Center(child: CircularProgressIndicator());

        return RefreshIndicator(
          onRefresh: _loadExpertPlans,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: ExploreGridDelegate.getDelegate(context, false),
            itemCount: displayedPlans.length,
            itemBuilder: (context, index) {
              final plan = displayedPlans[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItineraryDetailScreen(itinerary: plan, isReadOnly: true),
                  ),
                ),
                child: PublicTripCard(itinerary: plan),
              );
            },
          ),
        );
      },
    );
  }
}