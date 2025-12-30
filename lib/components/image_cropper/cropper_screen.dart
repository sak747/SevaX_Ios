import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:path_provider/path_provider.dart';

/// Simple Dart cropper screen - non-native. Works on mobile (Android/iOS).
/// On web this screen will not perform cropping (fallback to original file).
class CropperScreen extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final double aspectRatio; // if 1.0 -> square, else free

  CropperScreen({this.imagePath, this.imageBytes, this.aspectRatio = 1.0});

  @override
  _CropperScreenState createState() => _CropperScreenState();
}

class _CropperScreenState extends State<CropperScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.imageBytes != null) {
        _imageBytes = widget.imageBytes;
        setState(() {
          _loading = false;
        });
        return;
      }

      if (kIsWeb) {
        // No bytes provided and running on web: nothing to preview
        setState(() {
          _loading = false;
        });
        return;
      }

      final f = io.File(widget.imagePath!);
      final bytes = await f.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cropAndReturn() async {
    if (kIsWeb) {
      // perform cropping using the rendered image and return bytes on web
      try {
        // capture the rendered area same as below and return jpg bytes
        RenderRepaintBoundary boundary = _repaintKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        ui.Image rendered = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData =
            await rendered.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception('Failed to capture image');
        final pngBytes = byteData.buffer.asUint8List();
        final decoded = img_pkg.decodeImage(pngBytes);
        if (decoded == null) throw Exception('Failed to decode rendered image');

        final box = _repaintKey.currentContext!.findRenderObject() as RenderBox;
        final logicalSize = box.size;
        final renderedWidth = rendered.width.toDouble();
        final renderedHeight = rendered.height.toDouble();

        final cropLogicalSize = (logicalSize.width < logicalSize.height
                ? logicalSize.width
                : logicalSize.height) *
            0.8;
        double cropW = cropLogicalSize;
        double cropH = cropLogicalSize;
        if (widget.aspectRatio > 0) {
          if (widget.aspectRatio != 1.0) {
            cropW = cropLogicalSize;
            cropH = cropW / widget.aspectRatio;
            if (cropH > logicalSize.height) {
              cropH = logicalSize.height * 0.8;
              cropW = cropH * widget.aspectRatio;
            }
          }
        }

        final left = (logicalSize.width - cropW) / 2.0;
        final top = (logicalSize.height - cropH) / 2.0;

        final scaleX = renderedWidth / logicalSize.width;
        final scaleY = renderedHeight / logicalSize.height;

        final srcLeft = (left * scaleX).round();
        final srcTop = (top * scaleY).round();
        final srcW = (cropW * scaleX).round();
        final srcH = (cropH * scaleY).round();

        final int cx = (srcLeft.clamp(0, decoded.width - 1)).toInt();
        final int cy = (srcTop.clamp(0, decoded.height - 1)).toInt();
        final int cW = (srcW.clamp(1, decoded.width)).toInt();
        final int cH = (srcH.clamp(1, decoded.height)).toInt();

        final cropped =
            img_pkg.copyCrop(decoded, x: cx, y: cy, width: cW, height: cH);
        final jpg = img_pkg.encodeJpg(cropped, quality: 90);
        Navigator.of(context).pop(jpg);
        return;
      } catch (e, st) {
        debugPrint('Web crop failed: $e\n$st');
        Navigator.of(context).pop(null);
        return;
      }
    }

    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      ui.Image rendered = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to capture image');
      final pngBytes = byteData.buffer.asUint8List();

      // decode via `image` package
      final decoded = img_pkg.decodeImage(pngBytes);
      if (decoded == null) throw Exception('Failed to decode rendered image');

      // Calculate crop rect based on overlay (centered) and current logical size
      final box = _repaintKey.currentContext!.findRenderObject() as RenderBox;
      final logicalSize = box.size;
      final renderedWidth = rendered.width.toDouble();
      final renderedHeight = rendered.height.toDouble();

      // Crop window: a centered square or aspect-ratio box
      final cropLogicalSize = (logicalSize.width < logicalSize.height
              ? logicalSize.width
              : logicalSize.height) *
          0.8;
      double cropW = cropLogicalSize;
      double cropH = cropLogicalSize;
      if (widget.aspectRatio > 0) {
        if (widget.aspectRatio != 1.0) {
          cropW = cropLogicalSize;
          cropH = cropW / widget.aspectRatio;
          if (cropH > logicalSize.height) {
            cropH = logicalSize.height * 0.8;
            cropW = cropH * widget.aspectRatio;
          }
        }
      }

      final left = (logicalSize.width - cropW) / 2.0;
      final top = (logicalSize.height - cropH) / 2.0;

      final scaleX = renderedWidth / logicalSize.width;
      final scaleY = renderedHeight / logicalSize.height;

      final srcLeft = (left * scaleX).round();
      final srcTop = (top * scaleY).round();
      final srcW = (cropW * scaleX).round();
      final srcH = (cropH * scaleY).round();

      final int cx = (srcLeft.clamp(0, decoded.width - 1)).toInt();
      final int cy = (srcTop.clamp(0, decoded.height - 1)).toInt();
      final int cW = (srcW.clamp(1, decoded.width)).toInt();
      final int cH = (srcH.clamp(1, decoded.height)).toInt();

      final cropped =
          img_pkg.copyCrop(decoded, x: cx, y: cy, width: cW, height: cH);

      final jpg = img_pkg.encodeJpg(cropped, quality: 90);

      final tempDir = await getTemporaryDirectory();
      final out = io.File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(jpg);
      Navigator.of(context).pop(out);
    } catch (e, st) {
      debugPrint('Crop failed: $e\n$st');
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Image'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _cropAndReturn,
            child: Text('Crop', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: LayoutBuilder(builder: (context, constraints) {
                final availW = constraints.maxWidth;
                final availH = constraints.maxHeight;
                return RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _imageBytes != null
                            ? InteractiveViewer(
                                child: Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text('Preview not available on web')),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CropOverlayPainter(
                                aspectRatio: widget.aspectRatio),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final double aspectRatio;

  _CropOverlayPainter({this.aspectRatio = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    // crop area
    double cropW = (size.width < size.height ? size.width : size.height) * 0.8;
    double cropH = cropW;
    if (aspectRatio > 0 && aspectRatio != 1.0) {
      cropH = cropW / aspectRatio;
      if (cropH > size.height) {
        cropH = size.height * 0.8;
        cropW = cropH * aspectRatio;
      }
    }

    final left = (size.width - cropW) / 2;
    final top = (size.height - cropH) / 2;
    final rect = Rect.fromLTWH(left, top, cropW, cropH);

    // draw dimmed background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // clear center
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(rect, clearPaint);

    // border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
