import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class Intro extends StatelessWidget {
  final VoidCallback onSkip;
  Intro({
    required this.onSkip,
  });

  @override
  @override
  Widget build(BuildContext context) {
    String introScreensJson =
        AppConfig.remoteConfig?.getString('intro_screens') ?? '[]';
    logger.i('>>>> $introScreensJson');
    List<dynamic> introSliderScreenshots = [];
    try {
      introSliderScreenshots = json.decode(introScreensJson) as List<dynamic>;
    } catch (e) {
      logger.e('Failed to parse intro_screens remote config: $e');
      introSliderScreenshots = [];
    }
    List<ContentConfig> slides =
        introSliderScreenshots.map<ContentConfig>((item) {
      return ContentConfig(
        title: item['title'] ?? '',
        description: item['description'] ?? '',
        pathImage: item['image'] ?? '',
        backgroundColor: Colors.white,
      );
    }).toList();

    // If there are no slides available, immediately skip the intro to avoid
    // triggering an assertion inside the intro_slider package which requires
    // at least one slide.
    if (slides.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          onSkip();
        } catch (e) {
          logger.e('Error while skipping intro with empty slides: $e');
        }
      });
      return Scaffold(
        body: Center(child: SizedBox.shrink()),
      );
    }

    return IntroSlider(
      listContentConfig: slides,
      onDonePress: onSkip,
      onSkipPress: onSkip,
      renderSkipBtn: Text(
        S.of(context).skip,
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      renderNextBtn: Text(
        S.of(context).next,
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      renderDoneBtn: Text(
        S.of(context).done,
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
