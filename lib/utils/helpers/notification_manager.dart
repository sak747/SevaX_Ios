import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sevaexchange/models/device_details.dart';
import 'package:sevaexchange/models/notifications_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';

class FCMNotificationManager {
  static Future<bool> registerDeviceWithMemberForNotifications(
    String email,
  ) async {
    return await _getFCMTokenForEmail(
      email: email,
    ).then(
      (token) => setFirebaseTokenForMemberWithEmail(
        email: email,
        token: token,
      ),
    );
  }

  static Future<String> _getFCMTokenForEmail({
    String? email,
  }) async {
    const String FAILED_GETTING_TOKEN = "";
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? FAILED_GETTING_TOKEN;
    } catch (e) {
      return FAILED_GETTING_TOKEN;
    }
  }

  static Future<bool> setFirebaseTokenForMemberWithEmail({
    String? email,
    String? token,
  }) async {
    DeviceDetails deviceDetails = DeviceDetails();
    if (kIsWeb) {
      deviceDetails.deviceType = 'web-device';
      deviceDetails.deviceId = 'Web';
    } else if (io.Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      deviceDetails.deviceType = androidInfo.id;
      deviceDetails.deviceId = 'Android';
    } else if (io.Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceDetails.deviceType = 'IOS';
      deviceDetails.deviceId = iosInfo.identifierForVendor ?? 'unknown';
    }
    return await CollectionRef.users
        .doc(email)
        .update({
          'tokenDetails.' + deviceDetails.deviceType!: token,
        })
        .then((e) => true)
        .catchError((onError) => false);
  }

//  static Future<bool> setFirebaseTokenForMemberWithEmail(
//      {String email, String token}) async {
//    return await CollectionRef
//        .users
//        .doc(email)
//        .update({
//          'tokens': token,
//        })
//        .then((e) => true)
//        .catchError((onError) => false);
//  }

  static Future<void> removeDeviceRegisterationForMember(
      {String? email}) async {
    const String UNREGISTER_DEVICE = "";
    await setFirebaseTokenForMemberWithEmail(
      email: email,
      token: UNREGISTER_DEVICE,
    );
  }

  static Map<String, String> getNotificationContent(NotificationsModel notification) {
    String title = 'SevaX Notification';
    String body = 'You have a new notification';

    switch (notification.type) {
      case NotificationType.AddManualTimeRequest:
        title = 'Manual Time Request';
        body = 'A new manual time request has been added';
        break;
      case NotificationType.RequestAccept:
        title = 'Request Accepted';
        body = 'Your request has been accepted';
        break;
      case NotificationType.RequestReject:
        title = 'Request Rejected';
        body = 'Your request has been rejected';
        break;
      case NotificationType.RequestCompleted:
        title = 'Request Completed';
        body = 'A request has been completed';
        break;
      case NotificationType.TransactionCredit:
        title = 'Credits Received';
        body = 'You have received time credits';
        break;
      case NotificationType.TransactionDebit:
        title = 'Credits Deducted';
        body = 'Credits have been deducted from your account';
        break;
      case NotificationType.OfferAccept:
        title = 'Offer Accepted';
        body = 'Your offer has been accepted';
        break;
      case NotificationType.JoinRequest:
        title = 'Join Request';
        body = 'Someone wants to join your timebank';
        break;
      case NotificationType.TypeMemberAdded:
        title = 'New Member';
        body = 'A new member has been added to your timebank';
        break;
      case NotificationType.GOODS_DONATION_REQUEST:
        title = 'Donation Request';
        body = 'You have received a goods donation request';
        break;
      case NotificationType.CASH_DONATION_COMPLETED_SUCCESSFULLY:
        title = 'Donation Completed';
        body = 'Your cash donation has been completed successfully';
        break;
      case NotificationType.MANUAL_TIME_CLAIM:
        title = 'Manual Time Claim';
        body = 'A manual time claim has been submitted';
        break;
      // Add more cases as needed for other notification types
      default:
        title = 'SevaX Notification';
        body = 'You have a new notification';
        break;
    }

    return {'title': title, 'body': body};
  }
}
