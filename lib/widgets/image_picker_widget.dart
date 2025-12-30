import 'package:universal_io/io.dart' as io;

import 'package:flutter/material.dart';
import 'package:sevaexchange/components/newsimage/user_image_picker_handler.dart';
import 'package:sevaexchange/globals.dart' as globals;

///Pass a [Widget] without any gestures or click events
class ImagePickerWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<io.File> onChanged;
  final ValueChanged<String>? onStockImageChanged;
  final bool isAspectRatioFixed;

  const ImagePickerWidget(
      {Key? key,
      required this.onChanged,
      required this.child,
      this.isAspectRatioFixed = true,
      this.onStockImageChanged});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget>
    with TickerProviderStateMixin
    implements UserImagePickerListener {
  late UserImagePickerHandler imagePicker;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    imagePicker = UserImagePickerHandler(
      this,
      _controller,
      isAspectRatioFixed: widget.isAspectRatioFixed,
    );
    imagePicker.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
        imagePicker.showDialog(context);
      },
      child: widget.child,
    );
  }

  @override
  void userImage(dynamic image) {
    if (image is io.File) {
      widget.onChanged(image);
      return;
    }
    // If web image (string url/path or bytes) is provided, forward to stock/image URL handler if available
    if (widget.onStockImageChanged != null) {
      if (image is String) {
        widget.onStockImageChanged!(image);
      } else {
        // bytes or other types: pass stringified representation
        widget.onStockImageChanged!(image.toString());
      }
    }
  }

  @override
  void addWebImageUrl() {
    if (widget.onStockImageChanged != null && globals.webImageUrl != null) {
      widget.onStockImageChanged!(globals.webImageUrl!);
    }
  }

  @override
  void stockImage(dynamic image, String type) {
    if (widget.onStockImageChanged != null) {
      widget.onStockImageChanged!(image);
    }
  }
}
