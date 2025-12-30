import 'package:flutter/material.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class SandBoxBanner extends StatelessWidget {
  final String title;
  final CommunityModel? communityModel;
  const SandBoxBanner({Key? key, required this.title, this.communityModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isTestCommunity = communityModel?.testCommunity ?? false;
    logger.e("issandbox" + isTestCommunity.toString());
    return isTestCommunity
        ? Container(
            height: 20,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          )
        : Offstage(
            offstage: true,
          );
  }
}
