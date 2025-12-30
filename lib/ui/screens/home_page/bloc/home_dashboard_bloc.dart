import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/flavor_config.dart';

class HomeDashBoardBloc extends BlocBase {
  final _communities = BehaviorSubject<List<CommunityModel>>();
  CommunityModel? _selectedCommunity;
  bool _isAdmin = false;

  final _selectedCommunitySubject =
      BehaviorSubject<CommunityModel?>.seeded(null);
  final _isAdminSubject = BehaviorSubject<bool>.seeded(false);

  Stream<List<CommunityModel>> get communities => _communities.stream;
  Stream<CommunityModel?> get selectedCommunityStream =>
      _selectedCommunitySubject.stream;
  Stream<bool> get isAdminStream => _isAdminSubject.stream;

  CommunityModel? get selectedCommunityModel => _selectedCommunity;
  bool get isAdmin => _isAdmin;

  void setSelectedCommunity(CommunityModel community, UserModel user) {
    _selectedCommunity = community;
    _selectedCommunitySubject.add(community);
    bool isAdmin = community.created_by == user.sevaUserID ||
        community.organizers.contains(user.sevaUserID);
    setIsAdmin(isAdmin);
  }

  void setIsAdmin(bool value) {
    _isAdmin = value;
    _isAdminSubject.add(value);
  }

  void getAllCommunities(UserModel user) async {
    logger.i('getAllCommunities called for user: ${user.email}');
    Set<String> communitiesList = Set.from(user.communities ?? []);
    logger.i('Initial communities list: $communitiesList');
    List<CommunityModel> c = [];
    if (communitiesList.isNotEmpty) {
      logger.i('Fetching ${communitiesList.length} communities');
      List<Future> futures = [];
      communitiesList.forEach((id) {
        logger.i('Attempting to fetch community $id');
        futures.add(CollectionRef.communities.doc(id).get().then((value) async {
          if (value.exists) {
            logger.i('Community $id exists, adding to list');
            CommunityModel community =
                CommunityModel(value.data() as Map<String, dynamic>);
            c.add(community);
            logger.i('Added community: ${community.name} (${community.id})');
          } else {
            logger.w('Community $id does not exist');
          }
        }).catchError((error) {
          logger.e('Error fetching community $id: $error');
        }));
      });
      await Future.wait(futures);
      logger.i(
          'Fetched ${c.length} communities successfully out of ${communitiesList.length} attempted');
      if (c.isNotEmpty) {
        c.sort(
          (a, b) => a.name.toLowerCase().compareTo(
                b.name.toLowerCase(),
              ),
        );
        if (!_communities.isClosed) {
          _communities.add(c);
          logger.i('Added ${c.length} communities to stream');
        }
        CommunityModel? selected = c.firstWhere(
            (model) => model.id == user.currentCommunity,
            orElse: () => CommunityModel({}));
        if (selected.id.isNotEmpty) {
          setSelectedCommunity(selected, user);
          logger.i('Set selected community: ${selected.name}');
        } else {
          logger.w(
              'No matching community found for currentCommunity: ${user.currentCommunity}');
        }
      } else {
        logger.w('No communities fetched successfully, emitting empty list');
        if (!_communities.isClosed) {
          _communities.add([]);
        }
      }
    } else {
      logger.w('No communities in user list, emitting empty list');
      if (!_communities.isClosed) {
        _communities.add([]);
      }
    }
  }

  void refreshCommunities(UserModel user) {
    if (user.sevaUserID != null && user.sevaUserID!.isNotEmpty) {
      getAllCommunities(user);
    }
  }

  Future<bool> setDefaultCommunity(
      {required CommunityModel community, required BuildContext context}) {
    CollectionRef.users.doc(SevaCore.of(context).loggedInUser.email).update({
      "currentCommunity": SevaCore.of(context).loggedInUser.currentCommunity,
      "currentTimebank": community.primary_timebank
    });
    return Future.value(true);
  }

  void dispose() {
    _communities.close();
    _selectedCommunitySubject.close();
    _isAdminSubject.close();
  }
}
