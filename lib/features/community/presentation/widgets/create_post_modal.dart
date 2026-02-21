import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';
import 'package:tour_guide/features/community/data/models/community_post.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreatePostModal extends StatefulWidget {
  final CommunityPost? postToEdit; // Optional parameter for Edit Mode

  const CreatePostModal({super.key, this.postToEdit});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  // 1. Controllers
  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  int _tripDuration = 1;

  final List<XFile> _selectedNewImages = [];
  List<String> _existingMediaUrls = []; // Track existing images in edit mode
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableTags = [
    "Adventure",
    "Beach",
    "Cultural",
    "Food",
    "Hiking",
    "Historical",
    "Mountains",
    "Nature",
  ];
  final Set<String> _selectedTags = {};

  bool get isEditMode => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    // Initialize data if in Edit Mode
    if (isEditMode) {
      final post = widget.postToEdit!;
      _titleCtrl.text = post.title;
      _destinationCtrl.text = post.destination ?? "";
      _contentCtrl.text = post.content;
      _tripDuration = widget.postToEdit!.tripDurationDays;
      _costCtrl.text = post.estimatedCost.toString();
      _selectedTags.addAll(post.tags);
      _existingMediaUrls = post.media.map((m) => m.mediaUrl).toList();
      // If media list was empty, check cover image
      if (_existingMediaUrls.isEmpty && post.coverImageUrl.isNotEmpty) {
        _existingMediaUrls.add(post.coverImageUrl);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _contentCtrl.dispose();
    _costCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  // 2. Main Logic Method
  Future<void> _handlePost() async {
    if (_titleCtrl.text.isEmpty || _destinationCtrl.text.isEmpty) {
      _showSnack("Title and Destination are required.");
      return;
    }
    if (_selectedNewImages.isEmpty) {
      _showSnack("At least one image is required.");
      return;
    }

    final commProvider = context.read<CommunityProvider>();

    try {
      // ✅ 1. Convert all selected XFiles to a List of Files
      final List<File> imageFiles = _selectedNewImages
          .map((xFile) => File(xFile.path))
          .toList();

      // 2. Prepare the object
      final postRequest = CommunityPost(
        id: widget.postToEdit?.id, // Important for edit mode
        title: _titleCtrl.text.trim(),
        destination: _destinationCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        tags: _selectedTags.toList(),
        tripDurationDays: _tripDuration,
        estimatedCost: double.tryParse(_costCtrl.text) ?? 0.0,
        coverImageUrl: isEditMode ? widget.postToEdit!.coverImageUrl : "",
        media: [],
        days: [],
        authorName: "",
      );

      bool success;
      if (isEditMode) {
        // ✅ Now passing the List<File> correctly
        success = await commProvider.updatePost(
          widget.postToEdit!.id!,
          postRequest,
          imageFiles,
        );
      } else {
        success = await commProvider.createPost(postRequest, imageFiles);
      }

      if (mounted && success) {
        Navigator.pop(context);
        _showSnack(isEditMode ? "Updated!" : "Published!");
      }
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CommunityProvider>().isCreating;

    return Scaffold(
      backgroundColor: Colors.transparent, // Keep the background transparent
      body: Container(
        // height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(
            0xFFF3F4F6,
          ), // Slightly darker background to make cards pop
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildTopBar(),
            if (isLoading)
              const LinearProgressIndicator(
                color: AppColors.primary,
                minHeight: 2,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    _buildSectionCard("Trip Overview", [
                      _inputLabel("Trip Title *"),
                      _customField(
                        _titleCtrl,
                        "e.g., Swiss Alps Adventure",
                        prefixIcon: Icons.landscape_outlined,
                      ),

                      _inputLabel("Destination *"),
                      _customField(
                        _destinationCtrl,
                        "e.g., Switzerland",
                        prefixIcon: Icons.location_on_outlined,
                      ),

                      _inputLabel("Description"),
                      _customField(
                        _contentCtrl,
                        "Tell us about your highlights...",
                        maxLines: 3,
                        prefixIcon: Icons.notes_outlined,
                      ),

                      _inputLabel("Trip Duration (Days) *"),
                      _buildInteractiveStepper(),

                      _inputLabel("Total Budget (Rs.)"),
                      _customField(
                        _costCtrl,
                        "e.g., 2000",
                        isNumber: true,
                        prefixIcon: Icons.account_balance_wallet_outlined,
                      ),

                      const SizedBox(height: 8),
                      _inputLabel("Relevant Tags"),
                      _buildTagWrap(),
                    ]),

                    _buildSectionCard("Visual Story *", [
                      _buildImageUploader(),
                    ]),

                    const SizedBox(height: 8),
                    _buildActionButton(isLoading),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              const Text(
                "Duration",
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _stepperButton(Icons.remove, () {
                  if (_tripDuration > 1) setState(() => _tripDuration--);
                }),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: Text(
                    "$_tripDuration",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                _stepperButton(Icons.add, () {
                  if (_tripDuration < 30) setState(() => _tripDuration++);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  size: 20,
                  color: AppColors.primary.withOpacity(0.7),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // The Stepper buttons now look like modern rounded icons
  @override
  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditMode ? "Edit Story" : "Create Post",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  // Widget _customField(
  //   TextEditingController ctrl,
  //   String hint, {
  //   int maxLines = 1,
  //   bool isNumber = false,
  //   IconData? prefixIcon,
  // }) {
  //   return TextField(
  //     controller: ctrl,
  //     maxLines: maxLines,
  //     keyboardType: isNumber ? TextInputType.number : TextInputType.text,
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 12,
  //         vertical: 12,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTagWrap() {
    return Wrap(
      spacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (val) => setState(
            () => val ? _selectedTags.add(tag) : _selectedTags.remove(tag),
          ),
          selectedColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildImageUploader() {
    return Column(
      children: [
        if (_existingMediaUrls.isNotEmpty || _selectedNewImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Display Existing Images
                ..._existingMediaUrls.map(
                  (url) => Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _existingMediaUrls.remove(url)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Display New Picked Images
                ..._selectedNewImages.map(
                  (xfile) => Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(xfile.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedNewImages.remove(xfile)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            const int maxImages = 5;
            final int currentCount =
                _selectedNewImages.length + _existingMediaUrls.length;

            if (currentCount >= maxImages) {
              _showSnack("Maximum $maxImages photos allowed.");
              return;
            }

            final List<XFile> picked = await _picker.pickMultiImage();

            if (picked.isNotEmpty) {
              // Check if adding the new ones exceeds the limit
              if (currentCount + picked.length > maxImages) {
                // Calculate how many more we can actually take
                int remainingSlots = maxImages - currentCount;
                setState(() {
                  _selectedNewImages.addAll(picked.take(remainingSlots));
                });
                _showSnack(
                  "Only the first $remainingSlots images were added (Limit: $maxImages)",
                );
              } else {
                setState(() => _selectedNewImages.addAll(picked));
              }
            }
          },
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Add More Photos"),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool loading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : _handlePost,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEditMode ? "Update Story" : "Publish Trip",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
