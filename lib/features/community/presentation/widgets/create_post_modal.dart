import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/community_service.dart';
import '../../data/services/file_upload_service.dart';
import '../../logic/community_provider.dart';
import '../../../auth/logic/auth_provider.dart';

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  
  final List<_DayController> _days = [_DayController(dayNumber: 1)];
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _costCtrl.dispose();
    for (var d in _days) { d.dispose(); }
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnack("Maximum 5 photos allowed");
      return;
    }
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          int spaceLeft = 5 - _selectedImages.length;
          _selectedImages.addAll(picked.take(spaceLeft));
        });
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  Future<void> _handlePost() async {
    if (_titleCtrl.text.isEmpty || _selectedImages.isEmpty) {
      _showSnack("Title and at least one image are required");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      // ✅ Check if your AuthProvider has 'token' or 'user?.token'
      // I'm assuming 'token' based on our previous setup. 
      // If this still errors, change to authProvider.user?.token
      final token = authProvider.token; 
      
      if (token == null) throw Exception("Session expired. Please login again.");

      final files = _selectedImages.map((x) => File(x.path)).toList();
      final uploadedUrls = await FileUploadService.uploadFiles(
        files: files,
        type: UploadType.post,
        token: token,
      );

      if (uploadedUrls.isEmpty) throw Exception("Failed to upload images.");

      final payload = {
        "title": _titleCtrl.text.trim(),
        "content": _contentCtrl.text.trim(),
        "tripDurationDays": _days.length,
        "estimatedCost": double.tryParse(_costCtrl.text) ?? 0,
        "coverImageUrl": uploadedUrls.first,
        "isPublic": true,
        "media": uploadedUrls.asMap().entries.map((e) => {
          "mediaUrl": e.value,
          "mediaType": "IMAGE",
          "dayNumber": 1,
          "displayOrder": e.key,
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

      await CommunityService.createRaw(payload);

      if (mounted) {
        context.read<CommunityProvider>().refreshPosts();
        Navigator.pop(context);
        _showSnack("Adventure shared!");
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // --- UI BUILDER METHODS ---

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_isSubmitting) const LinearProgressIndicator(color: AppColors.primary),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionLabel("TRIP OVERVIEW"),
                _customField(_titleCtrl, "Where did you go?"),
                _customField(_contentCtrl, "Describe the experience...", maxLines: 3),
                _customField(_costCtrl, "Total Budget (\$)", isNumber: true),
                const SizedBox(height: 20),
                _sectionLabel("PHOTOS"),
                _buildImageGrid(),
                const SizedBox(height: 20),
                _buildItineraryHeader(),
                ..._days.map((d) => _buildDayItem(d)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          const Text("New Adventure", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handlePost,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 12),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey)),
  );

  Widget _customField(TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (_, i) => _imagePreview(i),
            ),
          ),
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.grey[50]),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary), SizedBox(width: 8), Text("Add Trip Photos", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePreview(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_selectedImages[index].path), width: 90, height: 90, fit: BoxFit.cover),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.removeAt(index)),
              child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, size: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionLabel("ITINERARY"),
        TextButton.icon(
          onPressed: () => setState(() => _days.add(_DayController(dayNumber: _days.length + 1))),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Day"),
        ),
      ],
    );
  }

  Widget _buildDayItem(_DayController day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Day ${day.dayNumber}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (_days.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  onPressed: () => setState(() { day.dispose(); _days.remove(day); }),
                ),
            ],
          ),
          _customField(day.description, "What did you see?"),
          _customField(day.activities, "Activities (Hiking, Dinner, etc.)"),
        ],
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