import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/community_category_model.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/repositories/elastic_search.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/widgets/hide_widget.dart';
import 'package:sevaexchange/ui/screens/explore/pages/explore_page_view_holder.dart';
import 'package:sevaexchange/ui/screens/explore/pages/explore_community_details.dart';
import 'package:sevaexchange/ui/screens/search/bloc/queries.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';
import 'package:sevaexchange/constants/sevatitles.dart';
import 'package:sevaexchange/ui/screens/explore/widgets/community_card.dart';

class CommunityByCategoryView extends StatefulWidget {
  final CommunityCategoryModel model;
  final bool isFromNearby;
  final GeoPoint? geoPoint;
  final bool isUserSignedIn;

  const CommunityByCategoryView({
    Key? key,
    required this.model,
    this.isFromNearby = false,
    this.geoPoint,
    required this.isUserSignedIn,
  }) : super(key: key);
  @override
  _CommunityByCategoryViewState createState() =>
      _CommunityByCategoryViewState();
}

class _CommunityByCategoryViewState extends State<CommunityByCategoryView> {
  Future<List<CommunityModel>>? communities;
  Stream<List<CommunityModel>>? nearbyCommunities;

  @override
  void initState() {
    if (widget.isFromNearby) {
      if (widget.isUserSignedIn) {
        nearbyCommunities = Stream.value([]); // Empty stream for signed users
      } else {
        nearbyCommunities =
            Searches.getNearBYCommunities(geoPoint: widget.geoPoint);
      }
    } else {
      // Add timeout to prevent infinite loading
      communities = _getCommunitiesWithTimeout();
    }
    super.initState();
  }

  Future<List<CommunityModel>> _getCommunitiesWithTimeout() async {
    try {
      return await ElasticSearchApi.getCommunitiesByCategory(widget.model.id)
          .timeout(Duration(seconds: 2));
    } catch (e) {
      debugPrint('Error fetching communities: $e');
      return []; // Return empty list on error or timeout
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExplorePageViewHolder(
      hideSearchBar: true,
      hideHeader: widget.isUserSignedIn,
      hideFooter: widget.isUserSignedIn,
      appBarTitle: widget.isFromNearby
          ? S.of(context).timebanks_near_you
          : widget.model.getCategoryName(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.isFromNearby
              ? StreamBuilder<List<CommunityModel>>(
                  stream: nearbyCommunities,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return WidgetWrapper(
                        categoryTitle: widget.model.getCategoryName(context),
                        page: 'Community',
                        isUserSignedIn: widget.isUserSignedIn,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 2,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 4 -
                                      20),
                              child: LoadingIndicator(),
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return WidgetWrapper(
                        categoryTitle: widget.model.getCategoryName(context),
                        page: 'Community',
                        isUserSignedIn: widget.isUserSignedIn,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 2,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 4 -
                                      20),
                              child: Text(S.of(context).no_result_found),
                            ),
                          ),
                        ],
                      );
                    }

                    var list = snapshot.data!;
                    return WidgetWrapper(
                      categoryTitle: widget.model.getCategoryName(context),
                      page: 'Community',
                      isUserSignedIn: widget.isUserSignedIn,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            var m = list[index];
                            return CommunityCard(
                              name: m.name ?? '',
                              memberCount: (m.members?.length ?? 0).toString(),
                              imageUrl: m.logo_url ?? defaultProjectImageURL,
                              buttonLabel: widget.isUserSignedIn
                                  ? S.of(context).info
                                  : S.of(context).view,
                              buttonColor: HexColor('#F5A623'),
                              textColor: Colors.white,
                              memberIds: m.members ?? [],
                              onbuttonPress: () {
                                if (widget.isUserSignedIn) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ExploreCommunityDetails(
                                      communityId: m.id,
                                      isSignedUser: widget.isUserSignedIn,
                                    ),
                                  ));
                                } else {
                                  showSignInAlertMessage(
                                      context: context,
                                      message: S.of(context).sign_in_alert);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                )
              : FutureBuilder<List<CommunityModel>>(
                  future: communities,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return WidgetWrapper(
                        categoryTitle: widget.model.getCategoryName(context),
                        page: 'Community',
                        isUserSignedIn: widget.isUserSignedIn,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 2,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 4 -
                                      20),
                              child: LoadingIndicator(),
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return WidgetWrapper(
                        categoryTitle: widget.model.getCategoryName(context),
                        page: 'Community',
                        isUserSignedIn: widget.isUserSignedIn,
                        children: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            height: MediaQuery.of(context).size.height / 2.3,
                            child: Text(S.of(context).no_result_found),
                          ),
                        ],
                      );
                    }

                    var list = snapshot.data!;
                    return WidgetWrapper(
                      categoryTitle: widget.model.getCategoryName(context),
                      page: 'Community',
                      isUserSignedIn: widget.isUserSignedIn,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            var m = list[index];
                            return CommunityCard(
                              name: m.name ?? '',
                              memberCount: (m.members?.length ?? 0).toString(),
                              imageUrl: m.logo_url ?? defaultProjectImageURL,
                              buttonLabel: widget.isUserSignedIn
                                  ? S.of(context).info
                                  : S.of(context).view,
                              buttonColor: HexColor('#F5A623'),
                              textColor: Colors.white,
                              memberIds: m.members ?? [],
                              onbuttonPress: () {
                                if (widget.isUserSignedIn) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        ExploreCommunityDetails(
                                      communityId: m.id,
                                      isSignedUser: widget.isUserSignedIn,
                                    ),
                                  ));
                                } else {
                                  showSignInAlertMessage(
                                      context: context,
                                      message: S.of(context).sign_in_alert);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Local WidgetWrapper copied/adapted from requests view to match block UI
class WidgetWrapper extends StatelessWidget {
  final List<Widget> children;
  final String page;
  final String categoryTitle;
  final bool? isUserSignedIn;

  const WidgetWrapper(
      {Key? key,
      required this.children,
      required this.page,
      required this.categoryTitle,
      this.isUserSignedIn})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HideWidget(
          hide: isUserSignedIn!,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      page,
                      style: TextStyle(
                        color: HexColor('#F5A623'),
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: HexColor('#F5A623'),
                    size: 15,
                  ),
                  Text(
                    categoryTitle,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          secondChild: SizedBox.shrink(),
        ),
        ...children
      ],
    );
  }
}
