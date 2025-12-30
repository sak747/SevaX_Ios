import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/new_baseline/models/timebank_model.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_dashboard_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_page_base_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/user_data_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/widgets/no_group_placeholder.dart';
import 'package:sevaexchange/ui/screens/home_page/widgets/timebank_card.dart';
import 'package:sevaexchange/ui/screens/members/pages/members_page.dart';
import 'package:sevaexchange/ui/utils/helpers.dart';
import 'package:sevaexchange/utils/animations/fade_animation.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/data_managers/blocs/communitylist_bloc.dart';
import 'package:sevaexchange/utils/helpers/configuration_check.dart';
import 'package:sevaexchange/utils/helpers/show_limit_badge.dart';
import 'package:sevaexchange/utils/helpers/transactions_matrix_check.dart';
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/views/community/webview_seva.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/views/tasks/completed_list.dart';
import 'package:sevaexchange/views/tasks/my_tasks_list.dart';
import 'package:sevaexchange/views/tasks/notAccepted_tasks.dart';
import 'package:sevaexchange/views/timebanks/timebankcreate.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';
import 'package:sevaexchange/widgets/custom_info_dialog.dart';

import '../../../../flavor_config.dart';
import '../../../../labels.dart';

class TimebankHomePage extends StatefulWidget {
  final CommunityModel selectedCommunity;
  final String userId;
  final String communityId;

  const TimebankHomePage(
      {Key? key,
      required this.selectedCommunity,
      required this.userId,
      required this.communityId})
      : super(key: key);

  TimebankModel get primaryTimebankModel =>
      TimebankModel.fromMap({'id': selectedCommunity.primary_timebank});
  @override
  _TimebankHomePageState createState() => _TimebankHomePageState();
}

class _TimebankHomePageState extends State<TimebankHomePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  HomeDashBoardBloc? _homeDashBoardBloc;
  TabController? controller;
  ScrollController? _scrollController;
  bool isTitleVisible = false;

  @override
  void initState() {
    controller = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController?.addListener(() {
      if ((_scrollController?.offset ?? 0) > 260 && !isTitleVisible) {
        isTitleVisible = true;
        setState(() {});
      }
      if ((_scrollController?.offset ?? 0) < 250 && isTitleVisible) {
        isTitleVisible = false;
        setState(() {});
      }
    });
    _homeDashBoardBloc = BlocProvider.of<HomeDashBoardBloc>(context);
    // Remove direct changeTimebank call, let it be set from home_dashboard
    super.initState();
  }

  @override
  void dispose() {
    _homeDashBoardBloc?.dispose();
    controller?.dispose();
    super.dispose();
  }

  void navigateToCreateGroup() {
    // Use current timebank from user model instead of async first
    final currentTimebankId =
        SevaCore.of(context).loggedInUser.currentTimebank ?? '';
    final userId = SevaCore.of(context).loggedInUser.sevaUserID ?? '';

    // Check if current timebank is primary and user has access
    if (currentTimebankId == FlavorConfig.values.timebankId) {
      // For primary timebank, check access
      final timebankModel =
          Provider.of<HomePageBaseBloc>(context, listen: false)
              .getTimebankModelFromCurrentCommunity(currentTimebankId);
      if (timebankModel == null || !isAccessAvailable(timebankModel, userId)) {
        showAdminAccessMessage(context: context);
        return;
      }
    }

    // Proceed with navigation
    createEditCommunityBloc
        .updateUserDetails(SevaCore.of(context).loggedInUser);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimebankCreate(
          timebankId: currentTimebankId,
          communityCreatorId: widget.selectedCommunity.created_by,
        ),
      ),
    );
  }

  // void navigateToCreateProjectGroup() {
  //   createEditCommunityBloc
  //       .updateUserDetails(SevaCore.of(context).loggedInUser);
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TimeBankProjectsView(
  //         timebankId: SevaCore.of(context).loggedInUser.currentTimebank,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final user = BlocProvider.of<UserDataBloc>(context);
    final covidcheck = json.decode(AppConfig.remoteConfig!.getString('covid'));
    super.build(context);

    // Use primary timebank model directly instead of waiting for stream
    final primaryTimebankModel = widget.primaryTimebankModel;
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              title: Text(
                S.of(context).your_tasks,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTitleVisible ? Colors.black : Colors.transparent,
                ),
              ),
              titleSpacing: 20,
              backgroundColor: Colors.white,
              pinned: true,
              expandedHeight: covidcheck['show'] ? 480.0 : 370,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        ButtonTheme(
                          minWidth: 110.0,
                          height: 50.0,
                          buttonColor: Color.fromRGBO(234, 135, 137, 1.0),
                          child: Stack(
                            fit: StackFit.loose,
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  right: 10,
                                ),
                                child: CustomTextButton(
                                  onPressed: () {},
                                  child: Text(
                                    S.of(context).your_groups,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                // will be positioned in the top right of the container
                                top: 0,
                                right: -20,
                                child: Container(
                                  padding: EdgeInsets.only(left: 4, right: 4),
                                  child: infoButton(
                                    context: context,
                                    key: GlobalKey(),
                                    type: InfoType.GROUPS,
                                    // text:
                                    //     infoDetails['groupsInfo'] ?? description,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TransactionLimitCheck(
                          comingFrom: ComingFrom.Home,
                          timebankId: primaryTimebankModel.id,
                          isSoftDeleteRequested:
                              primaryTimebankModel.requestedSoftDelete,
                          child: ConfigurationCheck(
                            actionType: 'create_group',
                            role: MemberType.CREATOR,
                            child: IconButton(
                              icon: Icon(Icons.add_circle),
                              color: Theme.of(context).primaryColor,
                              onPressed: primaryTimebankModel.protected
                                  ? isAccessAvailable(
                                          primaryTimebankModel,
                                          SevaCore.of(context)
                                                  .loggedInUser
                                                  .sevaUserID ??
                                              '')
                                      ? navigateToCreateGroup
                                      : showProtctedTImebankDialog
                                  : navigateToCreateGroup,
                            ),
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                    Container(
                      height: 210,
                      child: getTimebanks(user!),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 10,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        S.of(context).your_tasks,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              forceElevated: false,
              bottom: TabBar(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelStyle: TextStyle(color: Colors.grey),
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  Tab(
                    child: Text(S.of(context).to_do),
                  ),
                  Tab(
                    child: Text(S.of(context).pending),
                  ),
                  Tab(
                    child: Text(S.of(context).completed),
                  ),
                ],
                controller: controller,
                isScrollable: false,
                unselectedLabelColor: Colors.black,
              ),
            ),
          ),
        ];
      },
      body: SafeArea(
        minimum: EdgeInsets.only(top: 104),
        child: TabBarView(
          controller: controller,
          children: <Widget>[
            MyTaskList(
              email: SevaCore.of(context).loggedInUser.email!,
              sevaUserId: SevaCore.of(context).loggedInUser.sevaUserID ?? '',
            ),
            NotAcceptedTaskList(),
            CompletedList()
          ],
        ),
      ),
    );
  }

  void showProtctedTImebankDialog() {
    showDialog(
      context: context,
      builder: (BuildContext _context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text(S.of(context).protected_timebank),
          content: Text(S.of(context).protected_timebank_group_creation_error),
          actionsPadding: EdgeInsets.only(right: 20),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            CustomTextButton(
              shape: StadiumBorder(),
              color: Theme.of(context).colorScheme.secondary,
              textColor: Colors.white,
              child: Text(
                S.of(context).close,
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Europa',
                ),
              ),
              onPressed: () {
                Navigator.of(_context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget getTimebanks(UserDataBloc user) {
    return StreamBuilder<List<TimebankModel>>(
      stream: Provider.of<HomePageBaseBloc>(context).timebanksOfCommunity,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading timebanks: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NoGroupPlaceHolder(
              navigateToCreateGroup: navigateToCreateGroup);
        }
        List<TimebankModel> timebanks = snapshot.data!
            .where((tb) => tb.id != widget.primaryTimebankModel.id)
            .toList();
        if (timebanks.isEmpty) {
          return NoGroupPlaceHolder(
              navigateToCreateGroup: navigateToCreateGroup);
        }
        return FadeAnimation(
          0,
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            child: ListView.builder(
              itemCount: timebanks.length,
              itemBuilder: (context, index) {
                return TimeBankCard(
                  user: user,
                  timebank: timebanks[index],
                );
              },
              shrinkWrap: true,
              padding: EdgeInsets.only(left: 12),
              scrollDirection: Axis.horizontal,
            ),
          ),
        );
      },
    );
  }

  void showGroupsWebPage() {
    var dynamicLinks = json.decode(
      AppConfig.remoteConfig!.getString("links_${S.of(context).localeName}"),
    );
    navigateToWebView(
      aboutMode: AboutMode(
        title: S.of(context).groups_help_text,
        urlToHit: dynamicLinks['groupsInfoLink'],
      ),
      context: context,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
