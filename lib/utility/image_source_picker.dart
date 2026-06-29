import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Show a Camera / Gallery chooser sheet, then pick and return the image path
/// (null when cancelled). Used by the owner add-vehicle / add-driver uploads.
Future<String?> pickImageWithSource(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker()
      .pickImage(source: source, imageQuality: 70, maxWidth: 1280);
  return file?.path;
}
