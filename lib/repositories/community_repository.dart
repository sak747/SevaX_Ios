import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sevaexchange/models/community_category_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class CommunityRepository {
  static final CollectionReference _ref = CollectionRef.communities;
  static final CollectionReference _categoriesRef =
      CollectionRef.communityCategories;

  static Future<List<CommunityCategoryModel>> getCommunityCategories() async {
    try {
      var result = await _categoriesRef.get();
      List<CommunityCategoryModel> models = [];
      for (var document in result.docs) {
        var data = document.data();
        if (data != null) {
          models.add(CommunityCategoryModel.fromMap(
              data as Map<String, dynamic>));
        }
      }
      return models;
    } catch (e) {
      logger.e('Failed to load community categories: $e');
      // Return empty list on error so UI can continue working instead of showing an error state
      return <CommunityCategoryModel>[];
    }
  }

  Stream<List<CommunityModel>> getAllCommunitiesOfUser(String userId) async* {
    var data = _ref.where('members', arrayContains: userId).snapshots();
    yield* data.transform(
      StreamTransformer<QuerySnapshot<Map<String, dynamic>>,
          List<CommunityModel>>.fromHandlers(
        handleData: (data, sink) async {
          List<CommunityModel> _communities = [];

          try {
            for (var element in data.docs) {
              var community = CommunityModel(element.data());
              _communities.add(community);
            }
            sink.add(_communities);
          } catch (e) {
            logger.e(e);
            sink.addError(e);
          }
        },
        handleError: (error, stackTrace, sink) {
          logger.e(error.toString(), error: error, stackTrace: stackTrace);
          sink.addError(error);
        },
      ),
    );
  }

  static Future<CommunityModel?> getCommunity(String communityId) async {
    var result = await _ref.doc(communityId).get();
    return result.exists
        ? CommunityModel(result.data() as Map<String, dynamic>)
        : null;
  }

  static Stream<List<CommunityModel>> getFeatureCommunities() async* {
    var data = _ref
        .where("private", isEqualTo: false)
        .where("softDelete", isEqualTo: false)
        .limit(10)
        .snapshots();

    yield* data.map<List<CommunityModel>>((event) {
      var models = <CommunityModel>[];
      for (var element in event.docs) {
        models.add(CommunityModel(element.data() as Map<String, dynamic>));
      }
      return models;
    });
  }

  static Future<List<CommunityModel>> getFeatureCommunitiesFuture() async {
    var data = await _ref
        .where("private", isEqualTo: false)
        .where("softDelete", isEqualTo: false)
        .limit(10)
        .get();

    List<CommunityModel> models = [];
    for (var element in data.docs) {
      CommunityModel model =
          CommunityModel(element.data() as Map<String, dynamic>);
      if (AppConfig.isTestCommunity != null && AppConfig.isTestCommunity) {
        if (model.testCommunity) models.add(model);
      } else {
        models.add(model);
      }
    }
    return models;
  }
}
