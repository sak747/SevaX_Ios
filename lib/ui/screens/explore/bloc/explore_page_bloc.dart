import 'package:flutter/material.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';
import 'package:sevaexchange/models/category_model.dart';
import 'package:sevaexchange/models/offer_model.dart';
import 'package:sevaexchange/models/request_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/new_baseline/models/project_model.dart';
import 'package:sevaexchange/repositories/elastic_search.dart';
import 'package:sevaexchange/utils/firestore_manager.dart' as FirestoreManager;
import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:sevaexchange/ui/utils/location_helper.dart';

class ExplorePageBloc {
  final _events = BehaviorSubject<List<ProjectModel>>();
  final _requests = BehaviorSubject<List<RequestModel>>();
  final _offers = BehaviorSubject<List<OfferModel>>();
  final _communities = BehaviorSubject<List<CommunityModel>>();
  final _categories = BehaviorSubject<List<CategoryModel>>();

  Stream<List<ProjectModel>> get events => _events.stream;
  Stream<List<RequestModel>> get requests => _requests.stream;
  Stream<List<OfferModel>> get offers => _offers.stream;
  Stream<List<CommunityModel>> get communities => _communities.stream;
  Stream<List<CategoryModel>> get categories => _categories.stream;

  Stream<bool> get isDataLoaded => CombineLatestStream.combine4(
        events,
        requests,
        offers,
        communities,
        (List<ProjectModel> a, List<RequestModel> b, List<OfferModel> c,
            List<CommunityModel> d) {
          return a.isNotEmpty && b.isNotEmpty && c.isNotEmpty && d.isNotEmpty;
        },
      );

  void load(
      {bool isUserLoggedIn = false,
      String? sevaUserID,
      BuildContext? context}) {
    // Always load featured communities first
    _loadFeaturedCommunities();

    if (isUserLoggedIn) {
      _loadLoggedInUserData(sevaUserID!);
    } else {
      _loadNonLoggedInUserData(context!);
    }
  }

  void _loadFeaturedCommunities() {
    ElasticSearchApi.getFeaturedCommunities().then((value) {
      debugPrint('Loaded ${value.length} featured communities');
      _communities.add(value);
    }).onError((error, stackTrace) {
      debugPrint('Error loading featured communities: $error');
      _communities.addError(error!);
    });
  }

  void _loadLoggedInUserData(String sevaUserID) {
    // Use Firestore for logged-in users
    FirestoreManager.getPublicOffers().listen((event) {
      debugPrint('Loaded ${event.length} offers for logged-in user');
      _offers.add(event);
    }, onError: (error) {
      debugPrint('Error loading offers for logged-in user: $error');
      _offers.addError(error);
    });

    FirestoreManager.getPublicProjects(sevaUserID).listen((event) {
      debugPrint('Loaded ${event.length} projects for logged-in user');
      _events.add(event);
    }, onError: (error) {
      debugPrint('Error loading projects for logged-in user: $error');
      _events.addError(error);
    });

    FirestoreManager.getPublicRequests().listen((event) {
      debugPrint('Loaded ${event.length} requests for logged-in user');
      _requests.add(event);
    }, onError: (error) {
      debugPrint('Error loading requests for logged-in user: $error');
      _requests.addError(error);
    });
  }

  void _loadNonLoggedInUserData(BuildContext context) {
    // Use ElasticSearch API for non-logged-in users with improved error handling

    // Load offers with retry mechanism
    ElasticSearchApi.getPublicOffers().then((value) {
      debugPrint('Loaded ${value.length} public offers for non-logged-in user');
      _offers.add(value);
    }).onError((error, stackTrace) {
      debugPrint('Error loading public offers: $error');
      _offers.addError(error ?? Exception('Failed to load offers'));
    });

    // Load projects with retry mechanism (no sevaUserID for non-logged-in users)
    ElasticSearchApi.getPublicProjects(
      distanceFilterData: null,
    ).then((value) {
      debugPrint(
          'Loaded ${value.length} public projects for non-logged-in user');
      _events.add(value);
    }).onError((error, stackTrace) {
      debugPrint('Error loading public projects: $error');
      _events.addError(error ?? Exception('Failed to load projects'));
    });

    // Load requests with retry mechanism
    ElasticSearchApi.getPublicRequests().then((value) {
      debugPrint(
          'Loaded ${value.length} public requests for non-logged-in user');
      _requests.add(value);
    }).onError((error, stackTrace) {
      debugPrint('Error loading public requests: $error');
      _requests.addError(error ?? Exception('Failed to load requests'));
    });

    // Load categories
    ElasticSearchApi.getAllCategories(context).then((value) {
      debugPrint('Loaded ${value.length} categories');
      _categories.add(value);
    }).onError((error, stackTrace) {
      debugPrint('Error loading categories: $error');
      _categories.addError(error ?? Exception('Failed to load categories'));
    });
  }

  /// Method to manually retry loading data (useful for refresh scenarios)
  void retryLoad(
      {bool isUserLoggedIn = false,
      String? sevaUserID,
      BuildContext? context}) {
    // Clear existing data first
    _offers.add([]);
    _events.add([]);
    _requests.add([]);

    // Reload data
    load(
      isUserLoggedIn: isUserLoggedIn,
      sevaUserID: sevaUserID,
      context: context,
    );
  }

  void dispose() {
    _events.close();
    _requests.close();
    _offers.close();
    _communities.close();
    _categories.close();
  }
}
