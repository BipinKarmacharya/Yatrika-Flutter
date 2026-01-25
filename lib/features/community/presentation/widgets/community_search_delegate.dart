import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import 'package:tour_guide/features/community/presentation/widgets/community_post_feed_card.dart';

class CommunitySearchDelegate extends SearchDelegate {
  Timer? _debounce;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  // This runs when the user hits "Enter" on keyboard
  @override
  Widget buildResults(BuildContext context) {
    // Trigger the search immediately on enter
    context.read<CommunityProvider>().searchPosts(query);
    return _buildSearchResults(context);
  }

  // This runs as the user types (Suggestions)
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Search for destinations or stories..."));
    }

    // --- DEBOUNCE LOGIC ---
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<CommunityProvider>().searchPosts(query);
    });

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.posts.isEmpty) return const Center(child: Text("No results found."));

        return ListView.builder(
          itemCount: provider.posts.length,
          itemBuilder: (context, index) => CommunityPostFeedCard(post: provider.posts[index]),
        );
      },
    );
  }
}