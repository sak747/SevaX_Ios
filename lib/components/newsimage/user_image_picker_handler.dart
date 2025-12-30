import 'dart:async';
import 'package:universal_io/io.dart' as io;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sevaexchange/components/image_cropper/cropper_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevaexchange/components/sevaavatar/image_picker_handler.dart';
import 'package:permission_handler/permission_handler.dart';

import './user_image_picker_dialog.dart';

class UserImagePickerHandler {
  late UserImagePickerDialog imagePicker;
  late AnimationController _controller;
  late UserImagePickerListener _listener;
  late bool isAspectRatioFixed;

  UserImagePickerHandler(this._listener, this._controller,
      {this.isAspectRatioFixed = true});

  void openCamera() async {
    imagePicker.dismissDialog();
    // Request camera permission
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint('Camera permission denied');
        return;
      }
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final ctx = imagePicker.context;
        if (ctx != null) {
          final result = await Navigator.of(ctx).push<dynamic>(
            MaterialPageRoute(
              builder: (c) => CropperScreen(
                  imageBytes: bytes,
                  aspectRatio: isAspectRatioFixed ? 1.0 : 1.0),
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
      cropImage(pickedFile.path);
    }
  }

  void openGallery() async {
    imagePicker.dismissDialog();
    // Request storage/photos permission
    if (!kIsWeb) {
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      if (!storageStatus.isGranted) {
        final photos = await Permission.photos.request();
        if (!photos.isGranted) {
          debugPrint('Storage/Photos permission denied');
          return;
        }
      }
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final ctx = imagePicker.context;
        if (ctx != null) {
          final result = await Navigator.of(ctx).push<dynamic>(
            MaterialPageRoute(
              builder: (c) => CropperScreen(
                  imageBytes: bytes,
                  aspectRatio: isAspectRatioFixed ? 1.0 : 1.0),
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
      cropImage(pickedFile.path);
    }
  }

  void openStockImages(context) async {
    imagePicker.dismissDialog();

    FocusScope.of(context).requestFocus(FocusNode());
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => SearchStockImages(
              // keepOnBackPress: false,
              // showBackBtn: false,
              // isFromHome: false,
              themeColor: Theme.of(context).primaryColor,
              onChanged: (image) {
                _listener.stockImage(image, 'stock_image');
                Navigator.pop(context);
              },
            ),
          ),
        )
        .then((value) {});
    // _parentStockSelectionBottomsheet(context, (image) {
    //   log("inside stock images onchanged callback");
    //   _listener.userImage(image, 'stock_image');
    //   Navigator.pop(context);
    // });
  }

  addImageUrl() async {
    imagePicker.dismissDialog();

    _listener.addWebImageUrl();
  }

  void init() {
    imagePicker = UserImagePickerDialog(this, _controller);
    imagePicker.initState(isAspectRatioFixed);
  }

  Future cropImage(String path) async {
    try {
      // For web we fallback to original path (cropper plugin unsupported here)
      if (kIsWeb) {
        _listener.userImage(path);
        return;
      }

      final BuildContext? ctx = imagePicker.context;
      if (ctx == null) return;
      final result = await Navigator.of(ctx).push<io.File?>(
        MaterialPageRoute(
          builder: (ctx) => CropperScreen(
            imagePath: path,
            aspectRatio: isAspectRatioFixed ? 1.0 : 1.0,
          ),
        ),
      );

      if (result != null) {
        _listener.userImage(result);
      } else {
        _listener.userImage(path);
      }
    } catch (e, st) {
      debugPrint('Image cropping failed: $e');
      debugPrint(st.toString());
      try {
        _listener.userImage(path);
      } catch (_) {}
    }
  }

  void showDialog(BuildContext context) {
    imagePicker.getImage(context);
  }
}

abstract class UserImagePickerListener {
  void userImage(dynamic _image);
  void stockImage(dynamic _image, String type);

  addWebImageUrl();
}
