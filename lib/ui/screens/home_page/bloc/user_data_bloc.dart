import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class UserDataBloc extends BlocBase {
  final _user = BehaviorSubject<UserModel>();
  final _community = BehaviorSubject<CommunityModel>();

  // UserDataBloc({String email, String communityId}) {
  //   getData(email: email, communityId: communityId);
  // }

  Stream<UserModel> get userStream => _user.stream;
  Stream<CommunityModel> get comunityStream => _community.stream;

  StreamSink<UserModel> get updateUser => _user.sink;
  StreamSink<CommunityModel> get updateCommunity => _community.sink;

  UserModel get user => _user.value;
  CommunityModel get community => _community.value;

  Stream<DocumentSnapshot> getUser(String email) {
    return CollectionRef.users.doc(email).snapshots();
  }

  void getData({required String email, required String communityId}) {
    logger.i('Starting getData for email: $email, communityId: $communityId');
    if (!_user.isClosed && !_community.isClosed) {
      // Validate communityId
      if (communityId == null || communityId.isEmpty) {
        logger.e('Invalid communityId: $communityId');
        _community.addError('Invalid community ID');
        return;
      }

      try {
        // Listen to user stream
        logger.i('Setting up user stream listener for $email');
        CollectionRef.users.doc(email).snapshots().listen((userSnapshot) {
          logger.i('User snapshot received for $email: exists=${userSnapshot.exists}, hasData=${userSnapshot.data() != null}');
          try {
            if (!_user.isClosed) {
              if (userSnapshot.exists && userSnapshot.data() != null) {
                final userData = userSnapshot.data() as Map<String, dynamic>;
                logger.i('User data fetched successfully for $email: ${userData.keys}');
                _user.add(UserModel.fromMap(userData, 'user_data_bloc'));
              } else {
                logger.e('User document not found or empty for $email');
                _user.addError('User document not found or empty');
              }
            }
          } catch (e, stackTrace) {
            logger.e('Error processing user snapshot: $e\n$stackTrace');
            _user.addError('Error processing user data: $e');
          }
        }, onError: (error) {
          logger.e('Error in user stream: $error');
          _user.addError('User stream error: $error');
        });

        // Listen to community stream
        logger.i('Setting up community stream listener for $communityId');
        CollectionRef.communities.doc(communityId).snapshots().listen(
            (communitySnapshot) {
          logger.i('Community snapshot received for $communityId: exists=${communitySnapshot.exists}, hasData=${communitySnapshot.data() != null}');
          try {
            if (!_community.isClosed) {
              if (communitySnapshot.exists &&
                  communitySnapshot.data() != null) {
                final communityData =
                    communitySnapshot.data() as Map<String, dynamic>;
                logger.i('Community data fetched successfully for $communityId: ${communityData.keys}');
                _community.add(CommunityModel(communityData));
                AppConfig.paymentStatusMap = _community.value.payment;
                //AppConfig.isTestCommunity = _community.value.testCommunity;
                log('test ${AppConfig.isTestCommunity}');
              } else {
                logger.e(
                    'Community document not found or empty for $communityId');
                _community.addError('Community document not found or empty');
              }
            }
          } catch (e, stackTrace) {
            logger.e('Error processing community snapshot: $e\n$stackTrace');
            _community.addError('Error processing community data: $e');
          }
        }, onError: (error) {
          logger.e('Error in community stream: $error');
          _community.addError('Community stream error: $error');
        });
      } catch (e, stackTrace) {
        logger.e('Error initializing streams: $e\n$stackTrace');
        _user.addError('Initialization error: $e');
        _community.addError('Initialization error: $e');
      }
    } else {
      logger.w('Streams are closed, cannot fetch data');
    }
  }

  @override
  void dispose() {
    _user.close();
    _community.close();
  }
}

class HomeRouterModel {
  final DocumentSnapshot user;
  final DocumentSnapshot community;

  HomeRouterModel({required this.user, required this.community});
}
