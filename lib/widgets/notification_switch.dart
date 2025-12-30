import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';

class NotificationWidgetSwitch extends StatefulWidget {
  final bool isTurnedOn;
  final String title;
  final Function onPressed;
  NotificationWidgetSwitch({
    Key? key,
    required this.isTurnedOn,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  _NotificationWidgetSwitchState createState() =>
      _NotificationWidgetSwitchState();

  static void updateNotificationFormAdmin({
    required String timebankId,
    required String adminSevaUserId,
    required String notificationType,
    required bool status,
  }) {
    CollectionRef.timebank.doc(timebankId).update(
      {
        'notificationSetting.$adminSevaUserId.$notificationType': status,
      },
    );
  }

  static void updatePersonalNotifications({
    required String userEmail,
    required String notificationType,
    required bool status,
  }) {
    CollectionRef.users.doc(userEmail).update(
      {
        'notificationSetting.$notificationType': status,
      },
    );
  }
}

class _NotificationWidgetSwitchState extends State<NotificationWidgetSwitch> {
  late bool switchStatus;

  @override
  void initState() {
    super.initState();
    switchStatus = widget.isTurnedOn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Europa',
                // fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Switch(
              value: switchStatus,
              onChanged: (value) {
                setState(() {
                  switchStatus = value;
                });
                widget.onPressed(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
