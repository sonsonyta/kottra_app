import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../view_models/profile_view_model.dart';
import '../shared_widgets.dart';
import '../tab_colors.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.viewModel});
  final ProfileViewModel viewModel;

  @override
  State<EditProfileSheet> createState() => EditProfileSheetState();
}

class EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  Uint8List? _croppedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.viewModel.firstName);
    _lastNameController = TextEditingController(text: widget.viewModel.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    if (!mounted) return;

    // Crop in a pure-Dart cropper (crop_your_image). This renders entirely
    // inside Flutter and never launches a separate Android activity, avoiding
    // the native "Reply already submitted" crash of image_cropper's uCrop flow.
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CropImageScreen(imageBytes: bytes),
      ),
    );
    if (cropped != null && mounted) {
      setState(() {
        _croppedImageBytes = cropped;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await widget.viewModel.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        croppedImageBytes: _croppedImageBytes,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.editProfile,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TabAvatar(
                    imageUrl: _croppedImageBytes == null ? widget.viewModel.profileImageUrl : null,
                    initials: widget.viewModel.userInitials,
                    size: 80,
                    useGradient: true,
                  ),
                  if (_croppedImageBytes != null)
                    Positioned.fill(
                      child: ClipOval(
                        child: Image.memory(
                          _croppedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: l10n.firstName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: l10n.lastName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Full-screen square cropper backed by crop_your_image (pure Dart).
/// Returns the cropped image bytes via [Navigator.pop], or nothing if canceled.
class _CropImageScreen extends StatefulWidget {
  const _CropImageScreen({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<_CropImageScreen> {
  final _controller = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Image'),
        actions: [
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _isCropping = true);
                _controller.crop();
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        aspectRatio: 1,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.6),
        cornerDotBuilder: (size, edgeAlignment) =>
            DotControl(color: c.primary),
        onCropped: (result) {
          if (!mounted) return;
          switch (result) {
            case CropSuccess(:final croppedImage):
              Navigator.of(context).pop(croppedImage);
            case CropFailure():
              setState(() => _isCropping = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to crop image')),
              );
          }
        },
      ),
    );
  }
}