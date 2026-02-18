import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guide/core/api/api_client.dart';
import 'package:tour_guide/features/auth/data/models/user_model.dart';
import 'package:tour_guide/features/itinerary/data/models/itinerary.dart';
import 'package:tour_guide/features/itinerary/logic/itinerary_provider.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/itinerary/presentation/screens/itinerary_detail_screen.dart';
import 'package:tour_guide/features/itinerary/presentation/widgets/dialogs/trip_copy_dialog.dart';

class PublicTripCard extends StatefulWidget {
  final Itinerary itinerary;
  final bool compactMode;

  const PublicTripCard({
    super.key,
    required this.itinerary,
    this.compactMode = false,
  });

  @override
  State<PublicTripCard> createState() => _PublicTripCardState();
}

class _PublicTripCardState extends State<PublicTripCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final String _placeholderImg =
      "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers - ALL NOW ACCEPT Itinerary PARAMETER
  // ---------------------------------------------------------------------------

  bool _isOwnTrip(Itinerary itinerary) {
    final currentUserId = ApiClient.currentUserId;
    return currentUserId != null && itinerary.userId == currentUserId;
  }

  bool _isExpertTemplate(Itinerary itinerary) => itinerary.user == null;

  String _getUserName(UserModel? user) {
    if (user == null) return 'Expert';
    if (user.fullName.trim().isNotEmpty) return user.fullName;
    return user.username;
  }

  String _getUserInitials(UserModel? user) {
    if (user == null) return 'E';
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName![0]}${user.lastName![0]}';
    }
    if (user.firstName != null) return user.firstName![0];
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return 'U';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  List<String> _getTags(Itinerary itinerary) {
    if (itinerary.tags?.isNotEmpty == true) {
      return itinerary.tags!;
    }
    return ['Travel'];
  }

  // Helper to get latest itinerary from provider
  Itinerary _getLatestItinerary(ItineraryProvider provider, int id) {
    final index = provider.publicPlans.indexWhere((it) => it.id == id);
    if (index != -1) {
      return provider.publicPlans[index];
    }
    return widget.itinerary; // fallback to original
  }

  // ---------------------------------------------------------------------------
  // Actions - ALL NOW ACCEPT Itinerary PARAMETER OR USE LATEST
  // ---------------------------------------------------------------------------

  void _toggleLike(BuildContext context, int itineraryId) async {
    await context.read<ItineraryProvider>().toggleLike(
      itineraryId,
      context: context,
    );
  }

  void _toggleSave(
    BuildContext context,
    int itineraryId,
    bool isCurrentlySaved,
  ) async {
    final provider = context.read<ItineraryProvider>();
    if (isCurrentlySaved) {
      await provider.unsaveItinerary(itineraryId, context: context);
    } else {
      await provider.saveItinerary(itineraryId, context: context);
    }
  }

  void _copyTrip(BuildContext context, Itinerary itinerary) async {
    // This calls the dialog you just created
    await TripCopyHelper.showCopyWorkflow(context, itinerary);
  }

  void _navigateToDetail(
    BuildContext context,
    Itinerary itinerary, {
    bool editMode = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItineraryDetailScreen(itinerary: itinerary, isReadOnly: !editMode),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Components - ALL NOW ACCEPT Itinerary PARAMETER
  // ---------------------------------------------------------------------------

  Widget _buildImageSlider(Itinerary itinerary, List<String> images) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: widget.compactMode ? 160 : 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) =>
                    Image.network(_placeholderImg, fit: BoxFit.cover),
              ),
            ),
          ),
        ),

        // Budget Overlay
        if (itinerary.estimatedBudget != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money, color: Colors.white, size: 14),
                  Text(
                    itinerary.estimatedBudget!.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (itinerary.isAdminCreated)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Expert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Dot indicator for multiple images
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  width: _currentPage == i ? 16 : 4,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserRow(Itinerary itinerary) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: itinerary.user?.profileImage != null
              ? NetworkImage(itinerary.user!.profileImage!)
              : null,
          child: itinerary.user?.profileImage == null
              ? Text(
                  _getUserInitials(itinerary.user),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '@${_getUserName(itinerary.user)} · ${_formatDate(itinerary.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(Itinerary itinerary) {
    final tags = _getTags(itinerary);
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags
            .map(
              (t) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: Text(
                  '#$t',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Itinerary itinerary) {
    final isLiked = itinerary.isLikedByCurrentUser ?? false;
    final isSaved = itinerary.isSavedByCurrentUser ?? false;
    final isOwn = _isOwnTrip(itinerary);
    final copyCount = itinerary.copyCount ?? 0;
    final likeCount = itinerary.likeCount ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Like button with count
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () => _toggleLike(context, itinerary.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            if (likeCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '$likeCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLiked ? Colors.red : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        // Action buttons (Save/Copy/Edit)
        Row(
          children: [
            if (!isOwn)
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved
                      ? const Color(0xFF009688)
                      : Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () => _toggleSave(context, itinerary.id, isSaved),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

            if (!isOwn && (_isExpertTemplate(itinerary) || itinerary.isPublic))
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () => _copyTrip(context, itinerary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  if (copyCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '$copyCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

            if (isOwn)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: const Color(0xFF009688),
                  size: 20,
                ),
                onPressed: () =>
                    _navigateToDetail(context, itinerary, editMode: true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final images = widget.itinerary.images?.isNotEmpty == true
        ? widget.itinerary.images!
        : [_placeholderImg];

    return Consumer<ItineraryProvider>(
      builder: (context, provider, child) {
        // Get the LATEST version of this itinerary from provider
        final latestItinerary = _getLatestItinerary(
          provider,
          widget.itinerary.id,
        );

        // DEBUG PRINT - Check if data is updating
        print('🟣 REBUILDING Card ID: ${latestItinerary.id}');
        print('🟣 Liked: ${latestItinerary.isLikedByCurrentUser}');
        print('🟣 Like Count: ${latestItinerary.likeCount}');
        print('🟣 Provider publicPlans length: ${provider.publicPlans.length}');

        return GestureDetector(
          onTap: () => _navigateToDetail(context, latestItinerary),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSlider(latestItinerary, images),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestItinerary.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      if (latestItinerary.description?.isNotEmpty == true)
                        Text(
                          latestItinerary.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 10),
                      _buildUserRow(latestItinerary),
                      const SizedBox(height: 12),
                      _buildTags(latestItinerary),
                      const SizedBox(height: 12),
                      _buildActions(context, latestItinerary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}