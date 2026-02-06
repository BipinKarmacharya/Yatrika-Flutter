import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/community/data/services/file_upload_service.dart';
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

  final List<XFile> _selectedNewImages = [];
  List<String> _existingMediaUrls = []; // Track existing images in edit mode
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableTags = [
    "Adventure", "Beach", "Cultural", "Food", "Hiking", "Historical", "Mountains", "Nature",
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
    super.dispose();
  }

  // 2. Main Logic Method
  Future<void> _handlePost() async {
    // 1. Validation: Must have at least one image (new or existing)
    if (_titleCtrl.text.isEmpty ||
        _destinationCtrl.text.isEmpty ||
        (_selectedNewImages.isEmpty && _existingMediaUrls.isEmpty)) {
      _showSnack("Please provide a title, destination, and at least one photo.");
      return;
    }

    final commProvider = context.read<CommunityProvider>();

    try {
      // Step A: Upload New Images (if any)
      List<String> finalMediaUrls = List.from(_existingMediaUrls);
      
      if (_selectedNewImages.isNotEmpty) {
        final files = _selectedNewImages.map((x) => File(x.path)).toList();
        final uploadedUrls = await FileUploadService.uploadFiles(
          files: files,
          type: UploadType.post,
        );
        finalMediaUrls.addAll(uploadedUrls);
      }

      if (finalMediaUrls.isEmpty) throw Exception("No images associated with post.");

      // Step B: Construct Payload
      final Map<String, dynamic> payload = {
        "title": _titleCtrl.text.trim(),
        "destination": _destinationCtrl.text.trim(),
        "content": _contentCtrl.text.trim(),
        "tags": _selectedTags.toList(),
        "tripDurationDays": widget.postToEdit?.tripDurationDays ?? 1,
        "estimatedCost": double.tryParse(_costCtrl.text) ?? 0.0,
        "coverImageUrl": finalMediaUrls.first,
        "isPublic": true,
        "media": finalMediaUrls.asMap().entries.map((e) => {
          "mediaUrl": e.value,
          "mediaType": "IMAGE",
          "displayOrder": e.key,
          "caption": "Trip Image",
        }).toList(),
        "days": [], 
      };

      // Step C: Send to Provider
      bool success;
      if (isEditMode) {
        // You'll need to implement updatePost in your provider
        success = await commProvider.updatePost(widget.postToEdit!.id!, payload);
      } else {
        success = await commProvider.createPostFromRaw(payload);
      }

      if (mounted && success) {
        commProvider.refreshPosts();
        Navigator.pop(context);
        _showSnack(isEditMode ? "Story updated!" : "Adventure shared successfully!");
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
    // Note: You should add an 'isUpdating' bool to your provider similar to 'isCreating'
    final isLoading = context.watch<CommunityProvider>().isCreating;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          if (isLoading) const LinearProgressIndicator(color: AppColors.primary),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSectionCard("Trip Overview", [
                    _inputLabel("Trip Title *"),
                    _customField(_titleCtrl, "e.g., Swiss Alps"),
                    _inputLabel("Destination *"),
                    _customField(_destinationCtrl, "e.g., Switzerland"),
                    _inputLabel("Description"),
                    _customField(_contentCtrl, "Highlights...", maxLines: 3),
                    _inputLabel("Total Budget (Rs.)"),
                    _customField(_costCtrl, "e.g., 2000", isNumber: true),
                    _inputLabel("Tags"),
                    _buildTagWrap(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("Photos *", [_buildImageUploader()]),
                  const SizedBox(height: 16),
                  _buildActionButton(isLoading),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditMode ? "Edit Story" : "Create Post",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  );

  Widget _customField(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTagWrap() {
    return Wrap(
      spacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (val) => setState(() => val ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
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
                ..._existingMediaUrls.map((url) => Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: url, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _existingMediaUrls.remove(url)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      ),
                    )
                  ],
                )),
                // Display New Picked Images
                ..._selectedNewImages.map((xfile) => Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(xfile.path), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedNewImages.remove(xfile)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      ),
                    )
                  ],
                )),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final picked = await _picker.pickMultiImage();
            if (picked.isNotEmpty) setState(() => _selectedNewImages.addAll(picked));
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
          backgroundColor: const Color(0xFF047857),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEditMode ? "Update Story" : "Publish Trip",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:tour_guide/core/theme/app_colors.dart';
// import 'package:tour_guide/features/community/data/services/file_upload_service.dart';
// import 'package:tour_guide/features/community/logic/community_provider.dart';

// class CreatePostModal extends StatefulWidget {
//   const CreatePostModal({super.key});

//   @override
//   State<CreatePostModal> createState() => _CreatePostModalState();
// }

// class _CreatePostModalState extends State<CreatePostModal> {
//   // 1. Controllers
//   final _titleCtrl = TextEditingController();
//   final _destinationCtrl = TextEditingController();
//   final _contentCtrl = TextEditingController();
//   final _costCtrl = TextEditingController();

//   // final List<_DayController> _days = [_DayController(dayNumber: 1)];
//   final List<XFile> _selectedImages = [];
//   final ImagePicker _picker = ImagePicker();

//   final List<String> _availableTags = [
//     "Adventure",
//     "Beach",
//     "Cultural",
//     "Food",
//     "Hiking",
//     "Historical",
//     "Mountains",
//     "Nature",
//   ];
//   final Set<String> _selectedTags = {};

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _destinationCtrl.dispose();
//     _contentCtrl.dispose();
//     _costCtrl.dispose();
//     // for (var d in _days) {
//     //   d.dispose();
//     // }
//     super.dispose();
//   }

//   // 2. Main Logic Method

//   Future<void> _handlePost() async {
//     // 1. Validation
//     if (_titleCtrl.text.isEmpty ||
//         _destinationCtrl.text.isEmpty ||
//         _selectedImages.isEmpty) {
//       _showSnack(
//         "Please provide a title, destination, and at least one photo.",
//       );
//       return;
//     }

//     final commProvider = context.read<CommunityProvider>();

//     try {
//       // Step A: Upload Images
//       final files = _selectedImages.map((x) => File(x.path)).toList();
//       final uploadedUrls = await FileUploadService.uploadFiles(
//         files: files,
//         type: UploadType.post,
//       );

//       if (uploadedUrls.isEmpty) throw Exception("Failed to upload images.");

//       // Step B: Construct Payload
//       // Note: Even if you removed the Day-by-Day itinerary UI,
//       // these fields power your "Summary Card" in the details screen.
//       final Map<String, dynamic> payload = {
//         "title": _titleCtrl.text.trim(),
//         "destination": _destinationCtrl.text.trim(),
//         "content": _contentCtrl.text.trim(),
//         "tags": _selectedTags.toList(),
//         "tripDurationDays": 1, // Defaulting to 1 if you removed the day picker
//         "estimatedCost": double.tryParse(_costCtrl.text) ?? 0.0,
//         "coverImageUrl": uploadedUrls.first,
//         "isPublic": true,
//         "media": uploadedUrls
//             .asMap()
//             .entries
//             .map(
//               (e) => {
//                 "mediaUrl": e.value,
//                 "mediaType": "IMAGE",
//                 "displayOrder": e.key,
//                 "caption": "Trip Image",
//               },
//             )
//             .toList(),
//         // Sending an empty days list if you aren't using the itinerary feature
//         "days": [],
//       };

//       // Step C: Send to Provider
//       final success = await commProvider.createPostFromRaw(payload);

//       if (mounted && success) {
//         // Refresh the feed so the new post appears immediately
//         commProvider.refreshPosts();
//         Navigator.pop(context);
//         _showSnack("Adventure shared successfully!");
//       }
//     } catch (e) {
//       _showSnack("Error: ${e.toString()}");
//     }
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // 3. UI Build
//   @override
//   Widget build(BuildContext context) {
//     final isCreating = context.watch<CommunityProvider>().isCreating;

//     return Container(
//       height: MediaQuery.of(context).size.height * 0.9,
//       decoration: const BoxDecoration(
//         color: Color(0xFFF9FAFB),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           _buildTopBar(),
//           if (isCreating)
//             const LinearProgressIndicator(color: AppColors.primary),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   _buildSectionCard("Trip Overview", [
//                     _inputLabel("Trip Title *"),
//                     _customField(_titleCtrl, "e.g., Swiss Alps"),
//                     _inputLabel("Destination *"),
//                     _customField(_destinationCtrl, "e.g., Switzerland"),
//                     _inputLabel("Description"),
//                     _customField(_contentCtrl, "Highlights...", maxLines: 3),
//                     _inputLabel("Total Budget"),
//                     _customField(_costCtrl, "e.g., 2000", isNumber: true),
//                     _inputLabel("Tags"),
//                     _buildTagWrap(),
//                   ]),
//                   const SizedBox(height: 16),
//                   _buildSectionCard("Photos *", [_buildImageUploader()]),
//                   const SizedBox(height: 16),
//                   // _buildItinerarySection(),
//                   // const SizedBox(height: 32),
//                   _buildActionButton(isCreating),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- UI COMPONENT METHODS ---

//   Widget _buildTopBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             "Create Post",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.close),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionCard(String title, List<Widget> children) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _inputLabel(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 8, top: 8),
//     child: Text(
//       text,
//       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//     ),
//   );

//   Widget _customField(
//     TextEditingController ctrl,
//     String hint, {
//     int maxLines = 1,
//     bool isNumber = false,
//   }) {
//     return TextField(
//       controller: ctrl,
//       maxLines: maxLines,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   Widget _buildTagWrap() {
//     return Wrap(
//       spacing: 8,
//       children: _availableTags.map((tag) {
//         final isSelected = _selectedTags.contains(tag);
//         return ChoiceChip(
//           label: Text(tag),
//           selected: isSelected,
//           onSelected: (val) => setState(
//             () => val ? _selectedTags.add(tag) : _selectedTags.remove(tag),
//           ),
//           selectedColor: AppColors.primary,
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildImageUploader() {
//     return Column(
//       children: [
//         if (_selectedImages.isNotEmpty)
//           SizedBox(
//             height: 80,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: _selectedImages.length,
//               itemBuilder: (ctx, i) =>
//                   Image.file(File(_selectedImages[i].path), width: 80),
//             ),
//           ),
//         ElevatedButton.icon(
//           onPressed: () async {
//             final picked = await _picker.pickMultiImage();
//             if (picked.isNotEmpty)
//               setState(() => _selectedImages.addAll(picked));
//           },
//           icon: const Icon(Icons.add_a_photo),
//           label: const Text("Add Photos"),
//         ),
//       ],
//     );
//   }

//   // Widget _buildItinerarySection() {
//   //   return _buildSectionCard("Itinerary", [
//   //     ..._days.map((d) => ExpansionTile(title: Text("Day ${d.dayNumber}"), children: [
//   //       _customField(d.activities, "Activities"),
//   //       _customField(d.description, "Description"),
//   //     ])),
//   //     TextButton(onPressed: () => setState(() => _days.add(_DayController(dayNumber: _days.length + 1))), child: const Text("Add Day"))
//   //   ]);
//   // }

//   Widget _buildActionButton(bool loading) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: loading ? null : _handlePost,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF047857),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//         child: loading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : const Text(
//                 "Publish Trip",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//     );
//   }
// }

// // class _DayController {
// //   final int dayNumber;
// //   final description = TextEditingController();
// //   final activities = TextEditingController();
// //   _DayController({required this.dayNumber});
// //   void dispose() { description.dispose(); activities.dispose(); }
// // }
