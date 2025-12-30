import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;

import 'package:flutter/material.dart';
import 'package:sevaexchange/components/image_cropper/cropper_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import './image_picker_dialog.dart';

class ImagePickerHandler {
  late ImagePickerDialog imagePicker;
  AnimationController _controller;
  ImagePickerListener _listener;
  BuildContext? _context;

  ImagePickerHandler(this._listener, this._controller, {BuildContext? context})
      : _context = context;

  void openCamera() async {
    try {
      imagePicker.dismissDialog();
    } catch (e) {
      debugPrint('Warning: imagePicker.dismissDialog failed: $e');
    }
    try {
      // Request camera permission at runtime (skip on web)
      if (!kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          debugPrint('Camera permission not granted');
          if (_context != null) {
            ScaffoldMessenger.of(_context!).showSnackBar(
              SnackBar(content: Text('Camera permission is required')),
            );
          }
          return;
        }
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final ctx = _context ?? imagePicker.context;
          if (ctx != null) {
            final result = await Navigator.of(ctx).push<dynamic>(
              MaterialPageRoute(
                builder: (c) =>
                    CropperScreen(imageBytes: bytes, aspectRatio: 1.0),
              ),
            );
            if (result != null) {
              _listener.userImage(result);
            } else {
              _listener.userImage(bytes);
            }
          } else {
            _listener.userImage(bytes);
          }
          return;
        }
        final didCrop = await cropImage(pickedFile.path);
        if (!didCrop) {
          _listener.userImage(io.File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking camera image: $e');
    }
  }

  void openGallery() async {
    try {
      imagePicker.dismissDialog();
    } catch (e) {
      debugPrint('Warning: imagePicker.dismissDialog failed: $e');
    }
    try {
      // Request storage/media permission at runtime (skip on web)
      if (!kIsWeb) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        if (!storageStatus.isGranted) {
          // Try photos permission as a fallback for newer Android/iOS
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            debugPrint('Storage/Photos permission not granted');
            if (_context != null) {
              ScaffoldMessenger.of(_context!).showSnackBar(
                SnackBar(content: Text('Storage permission is required')),
              );
            }
            return;
          }
        }
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final ctx = _context ?? imagePicker.context;
          if (ctx != null) {
            final result = await Navigator.of(ctx).push<dynamic>(
              MaterialPageRoute(
                builder: (c) =>
                    CropperScreen(imageBytes: bytes, aspectRatio: 1.0),
              ),
            );
            if (result != null) {
              _listener.userImage(result);
            } else {
              _listener.userImage(bytes);
            }
          } else {
            _listener.userImage(bytes);
          }
          return;
        }
        final didCrop = await cropImage(pickedFile.path);
        if (!didCrop) {
          _listener.userImage(io.File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking gallery image: $e');
    }
  }

  addImageUrl() async {
    imagePicker.dismissDialog();
    _listener.addWebImageUrl();
  }

  void init() {
    imagePicker = ImagePickerDialog(this, _controller);
    imagePicker.initState();
  }

  /// Attempts to crop the image at [image].
  /// Returns `true` if cropping produced a file and the listener was called.
  /// Returns `false` if cropping was cancelled/failed — caller can fallback to original file.
  Future<bool> cropImage(String image) async {
    try {
      // On web we avoid the native cropper and fallback to no-crop
      if (kIsWeb) return false;

      final ctx = _context ?? imagePicker.context;
      final result = await Navigator.of(ctx).push<io.File?>(
        MaterialPageRoute(
          builder: (c) => CropperScreen(imagePath: image, aspectRatio: 1.0),
        ),
      );
      if (result != null) {
        _listener.userImage(result);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return false;
    }
  }

  void showDialog(BuildContext context) {
    imagePicker.getImage(context);
  }
}

abstract class ImagePickerListener {
  void userImage(dynamic _image);
  addWebImageUrl();
}
