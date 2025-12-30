import 'package:universal_io/io.dart' as io;

import 'package:flutter/material.dart';
import 'package:sevaexchange/components/image_cropper/cropper_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sevaexchange/components/ProfanityDetector.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/image_caption_model.dart';
import 'package:sevaexchange/ui/screens/message/widgets/message_input.dart';

class SelectedImagePreview extends StatefulWidget {
  final io.File file;

  const SelectedImagePreview({Key? key, required this.file}) : super(key: key);

  @override
  _SelectedImagePreviewState createState() => _SelectedImagePreviewState();
}

class _SelectedImagePreviewState extends State<SelectedImagePreview> {
  late io.File _file;
  TextEditingController textController = TextEditingController();
  final profanityDetector = ProfanityDetector();
  bool isProfane = false;
  String errorText = '';
  @override
  void initState() {
    super.initState();
    _file = widget.file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.crop_rotate),
            onPressed: () async {
              try {
                if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Crop not supported on web')),
                  );
                  return;
                }
                final result = await Navigator.of(context)
                    .push<io.File?>(MaterialPageRoute(
                        builder: (c) => CropperScreen(
                              imagePath: _file.path,
                              aspectRatio: 1.0,
                            )));
                if (result != null) {
                  setState(() {
                    _file = result;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cropping image')),
                );
              }
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.insert_emoticon),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: Icon(Icons.text_fields),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            Center(
              child: kIsWeb
                  ? Image.network(
                      _file.path ?? '',
                      errorBuilder: (ctx, err, st) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Image.file(
                      _file,
                    ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MessageInput(
                    handleChange: (String value) {
                      if (value.length < 2) {
                        setState(() {
                          isProfane = false;
                          errorText = '';
                        });
                      }
                    },
                    textController: textController,
                    handleSubmitted: (String value) {
                      send(_file, value);
                    },
                    hideCameraIcon: true,
                    hintText: S.of(context).add_caption,
                    onSend: () {
                      send(_file, textController.text);
                    },
                  ),
                  isProfane
                      ? Container(
                          margin: EdgeInsets.only(left: 20),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorText,
                            textAlign: TextAlign.start,
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        )
                      : Offstage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void send(io.File file, String caption) {
    if (caption != null && caption.isNotEmpty) {
      if (profanityDetector.isProfaneString(caption)) {
        setState(() {
          isProfane = true;
          errorText = S.of(context).profanity_text_alert;
        });
      } else {
        setState(() {
          isProfane = false;
          errorText = '';
        });
        ImageCaptionModel model = ImageCaptionModel(file, caption);
        Navigator.of(context).pop<ImageCaptionModel>(model);
      }
    } else {
      isProfane = false;
      errorText = '';
      ImageCaptionModel model = ImageCaptionModel(file, caption);
      Navigator.of(context).pop<ImageCaptionModel>(model);
    }
  }
}
