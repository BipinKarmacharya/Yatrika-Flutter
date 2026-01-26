import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tour_guide/core/theme/app_colors.dart';
import 'package:tour_guide/features/community/data/services/file_upload_service.dart';
import 'package:tour_guide/features/community/logic/community_provider.dart';

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  // 1. Controllers
  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  final List<_DayController> _days = [_DayController(dayNumber: 1)];
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _availableTags = ["Adventure", "Beach", "Cultural", "Food", "Hiking", "Historical", "Mountains", "Nature"];
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _contentCtrl.dispose();
    _costCtrl.dispose();
    for (var d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  // 2. Main Logic Method

  // 2. Main Logic Method
  Future<void> _handlePost() async {
    // Validation
    if (_titleCtrl.text.isEmpty || _destinationCtrl.text.isEmpty || _selectedImages.isEmpty) {
      _showSnack("Please provide a title, destination, and at least one photo.");
      return;
    }

    final commProvider = context.read<CommunityProvider>();
    // Note: We no longer need to manually extract the token here for the upload service
    // because FileUploadService now uses ApiClient.getToken() internally.

    try {
      // Step A: Upload Images 
      // REMOVED 'token: token' as it is no longer a parameter in our updated Service
      final files = _selectedImages.map((x) => File(x.path)).toList();
      final uploadedUrls = await FileUploadService.uploadFiles(
        files: files,
        type: UploadType.post,
      );

      if (uploadedUrls.isEmpty) throw Exception("Failed to upload images.");

      // Step B: Construct Payload
      final Map<String, dynamic> payload = {
        "title": _titleCtrl.text.trim(),
        "destination": _destinationCtrl.text.trim(),
        "content": _contentCtrl.text.trim(),
        "tags": _selectedTags.toList(),
        "tripDurationDays": _days.length,
        "estimatedCost": double.tryParse(_costCtrl.text) ?? 0.0,
        "coverImageUrl": uploadedUrls.first, // Uses the first uploaded image as cover
        "isPublic": true,
        "media": uploadedUrls.asMap().entries.map((e) => {
          "mediaUrl": e.value,
          "mediaType": "IMAGE",
          "dayNumber": 1, 
          "displayOrder": e.key,
          "caption": "Trip Image",
        }).toList(),
        "days": _days.map((d) => {
          "dayNumber": d.dayNumber,
          "description": d.description.text.trim(),
          "activities": d.activities.text.trim(),
          "accommodation": "Standard",
          "food": "Local",
          "transportation": "Public",
        }).toList(),
      };

      // Step C: Send to Provider
      final success = await commProvider.createPostFromRaw(payload);

      if (mounted && success) {
        Navigator.pop(context);
        _showSnack("Adventure shared successfully!");
      } else if (mounted) {
        _showSnack(commProvider.errorMessage ?? "Failed to create post");
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 3. UI Build
  @override
  Widget build(BuildContext context) {
    final isCreating = context.watch<CommunityProvider>().isCreating;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          if (isCreating) const LinearProgressIndicator(color: AppColors.primary),
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
                    _inputLabel("Total Budget"),
                    _customField(_costCtrl, "e.g., 2000", isNumber: true),
                    _inputLabel("Tags"),
                    _buildTagWrap(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard("Photos", [_buildImageUploader()]),
                  const SizedBox(height: 16),
                  _buildItinerarySection(),
                  const SizedBox(height: 32),
                  _buildActionButton(isCreating),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENT METHODS ---

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Create Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _inputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 8), child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)));

  Widget _customField(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
    return Column(children: [
      if (_selectedImages.isNotEmpty)
        SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _selectedImages.length, itemBuilder: (ctx, i) => Image.file(File(_selectedImages[i].path), width: 80))),
      ElevatedButton.icon(onPressed: () async {
        final picked = await _picker.pickMultiImage();
        if (picked.isNotEmpty) setState(() => _selectedImages.addAll(picked));
      }, icon: const Icon(Icons.add_a_photo), label: const Text("Add Photos"))
    ]);
  }

  Widget _buildItinerarySection() {
    return _buildSectionCard("Itinerary", [
      ..._days.map((d) => ExpansionTile(title: Text("Day ${d.dayNumber}"), children: [
        _customField(d.activities, "Activities"),
        _customField(d.description, "Description"),
      ])),
      TextButton(onPressed: () => setState(() => _days.add(_DayController(dayNumber: _days.length + 1))), child: const Text("Add Day"))
    ]);
  }

  Widget _buildActionButton(bool loading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : _handlePost,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), padding: const EdgeInsets.symmetric(vertical: 16)),
        child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Publish Trip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DayController {
  final int dayNumber;
  final description = TextEditingController();
  final activities = TextEditingController();
  _DayController({required this.dayNumber});
  void dispose() { description.dispose(); activities.dispose(); }
}