import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevaexchange/components/common_help_icon.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/enums/help_context_enums.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/new_baseline/models/timebank_model.dart';
import 'package:sevaexchange/ui/screens/groups/pages/group_page.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_dashboard_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_page_base_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/user_data_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/pages/timebank_home_page.dart';
import 'package:sevaexchange/ui/screens/home_page/widgets/sandbox_community_banner.dart';
import 'package:sevaexchange/ui/screens/members/pages/members_page.dart';
import 'package:sevaexchange/ui/screens/offers/pages/offer_router.dart';
import 'package:sevaexchange/ui/screens/request/pages/request_listing_page.dart';
import 'package:sevaexchange/ui/screens/search/pages/search_page.dart';
import 'package:sevaexchange/ui/utils/seva_analytics.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/common_timebank_model_singleton.dart';
import 'package:sevaexchange/utils/extensions.dart';

import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/views/community/webview_seva.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/views/project_view/timebank_projects_view.dart';
import 'package:sevaexchange/views/switch_timebank.dart';
import 'package:sevaexchange/views/timebank_content_holder.dart';
import 'package:sevaexchange/views/timebanks/timebank_manage_seva.dart';
import 'package:sevaexchange/views/timebanks/timebank_view_latest.dart';
import 'package:sevaexchange/views/tasks/my_tasks_list.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';

class HomeDashBoard extends StatefulWidget {
  @override
  _HomeDashBoardState createState() => _HomeDashBoardState();
}

class _HomeDashBoardState extends State<HomeDashBoard>
    with TickerProviderStateMixin {
  HomeDashBoardBloc? _homeDashBoardBloc = HomeDashBoardBloc();
  CommunityModel? selectedCommunity;
  TimebankModel? currentTimebank;
  TimeBankModelSingleton timeBankModelSingleton = TimeBankModelSingleton();
  List<Widget> pages = [];
  bool isAdmin = false;
  int tabLength = 8;

  void checkAdminStatus() {
    if (selectedCommunity != null) {
      final userId = SevaCore.of(context).loggedInUser.sevaUserID ?? '';
      isAdmin = (selectedCommunity!.admins ?? []).contains(userId) ||
          (selectedCommunity!.organizers ?? []).contains(userId) ||
          selectedCommunity!.created_by == userId;
      setState(() {});
    }
  }

  @override
  void initState() {
    planTransactionsMatrix();
    super.initState();
    // Delay initialization to after dependencies are available
    Future.delayed(Duration.zero, () {
      final user = SevaCore.of(context).loggedInUser;
      final currentCommunity = user.currentCommunity ?? '';
      final currentTimebank = user.currentTimebank ?? '';
      if (currentCommunity.isNotEmpty && currentTimebank.isNotEmpty) {
        setState(() {
          selectedCommunity = CommunityModel({
            'id': currentCommunity,
            'primary_timebank': currentTimebank,
            'name': 'Loading...', // Will be updated when full data loads
            'timebanks': [],
            'created_by': '',
            'organizers': [],
          });
        });
      }
      final userId = user.sevaUserID ?? '';
      if (userId.isNotEmpty) {
        _homeDashBoardBloc?.getAllCommunities(user);
      }
      // Initialize HomePageBaseBloc to start fetching data
      Provider.of<HomePageBaseBloc>(context, listen: false).init(user);
    });

    // Listen to communities stream to update selectedCommunity without setState during build
    _homeDashBoardBloc?.communities.listen((data) {
      if (data.isNotEmpty && mounted) {
        setCurrentCommunity(data);
      }
    });
  }

  Future<void> planTransactionsMatrix() async {
    AppConfig.plan_transactions_matrix = json
        .decode(AppConfig.remoteConfig!.getString('transactions_plans_matrix'));
  }

  @override
  void dispose() {
    _homeDashBoardBloc!.dispose();
    super.dispose();
  }

  void setCurrentCommunity(List<CommunityModel> data) async {
    if (data.isNotEmpty) {
      data.forEach((model) {
        final userCurrentCommunity =
            SevaCore.of(context).loggedInUser.currentCommunity ?? '';
        if ((model.id ?? '') == userCurrentCommunity) {
          setState(() {
            selectedCommunity = model;
          });
          _homeDashBoardBloc?.setSelectedCommunity(
              model, SevaCore.of(context).loggedInUser);

          Catalyst.recordAccessTime(communityId: selectedCommunity?.id ?? '');

          SevaCore.of(context).loggedInUser.currentTimebank =
              model.primary_timebank ?? '';
          SevaCore.of(context).loggedInUser.associatedWithTimebanks =
              model.timebanks.length;

          checkAdminStatus();

          // Set current timebank in HomePageBaseBloc
          final homePageBaseBloc =
              Provider.of<HomePageBaseBloc>(context, listen: false);
          homePageBaseBloc.init(SevaCore.of(context).loggedInUser);
          // Wait for timebanks to load before setting current timebank
          homePageBaseBloc.timebanksOfCommunity.listen((timebanks) {
            if (timebanks.isNotEmpty) {
              try {
                final primaryTimebank = model.primary_timebank ?? '';
                TimebankModel timebank = timebanks.firstWhere(
                  (t) => (t.id ?? '') == primaryTimebank,
                );
                homePageBaseBloc.changeTimebank(timebank);
                setState(() {
                  currentTimebank = timebank;
                });
              } catch (e) {
                logger.i(
                    'Timebank not found for ${model.primary_timebank ?? 'unknown'}');
              }
            }
          });
        }
      });
      // If no matching community found, set to the first one
      if (selectedCommunity == null) {
        final firstModel = data[0];
        selectedCommunity = firstModel;
        _homeDashBoardBloc?.setSelectedCommunity(
            firstModel, SevaCore.of(context).loggedInUser);
        SevaCore.of(context).loggedInUser.currentCommunity =
            firstModel.id ?? '';
        SevaCore.of(context).loggedInUser.currentTimebank =
            firstModel.primary_timebank ?? '';
        checkAdminStatus();
        setState(() {});

        // Set current timebank in HomePageBaseBloc
        final homePageBaseBloc =
            Provider.of<HomePageBaseBloc>(context, listen: false);
        homePageBaseBloc.init(SevaCore.of(context).loggedInUser);
        // Wait for timebanks to load before setting current timebank
        homePageBaseBloc.timebanksOfCommunity.listen((timebanks) {
          if (timebanks.isNotEmpty) {
            try {
              final primaryTimebank = firstModel.primary_timebank ?? '';
              TimebankModel timebank = timebanks.firstWhere(
                (t) => (t.id ?? '') == primaryTimebank,
              );
              homePageBaseBloc.changeTimebank(timebank);
              setState(() {
                currentTimebank = timebank;
              });
            } catch (e) {
              logger.i(
                  'Timebank not found for ${firstModel.primary_timebank ?? 'unknown'}');
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _user = BlocProvider.of<UserDataBloc>(context);
    List<String> _tabsNames = [
      S.of(context).timebank ?? 'Timebank',
      S.of(context).feeds ?? 'Feeds',
      S.of(context).projects ?? 'Projects',
      S.of(context).requests ?? 'Requests',
      S.of(context).offers ?? 'Offers',
      (S.of(context).groups ?? 'Groups').firstWordUpperCase(),
      S.of(context).about ?? 'About',
      S.of(context).members ?? 'Members',
      S.of(context).manage ?? 'Manage',
    ];

    return BlocProvider<HomeDashBoardBloc>(
      bloc: _homeDashBoardBloc!,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: false,
          title: StreamBuilder<List<CommunityModel>>(
            stream: _homeDashBoardBloc?.communities,
            initialData:
                selectedCommunity != null ? [selectedCommunity!] : null,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Error loading communities: ${snapshot.error}',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        final user = SevaCore.of(context).loggedInUser;
                        _homeDashBoardBloc?.refreshCommunities(user);
                      },
                    ),
                  ],
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(S.of(context).loading,
                          style: TextStyle(color: Colors.white)),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        final user = SevaCore.of(context).loggedInUser;
                        _homeDashBoardBloc?.refreshCommunities(user);
                      },
                    ),
                  ],
                );
              }

              if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Theme.of(context).primaryColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CommunityModel>(
                      isExpanded: true,
                      style: TextStyle(color: Colors.white),
                      focusColor: Colors.white,
                      iconEnabledColor: Colors.white,
                      value: selectedCommunity,
                      onChanged: (v) {
                        if (selectedCommunity != null &&
                            v?.id != selectedCommunity?.id) {
                          logger.i(
                              'Switching to community: ${v?.name ?? 'Unknown'} (${v?.id ?? ''})');
                          SevaCore.of(context).loggedInUser.currentCommunity =
                              v?.id ?? '';
                          SevaCore.of(context).loggedInUser.currentTimebank =
                              v?.primary_timebank ?? '';
                          setState(() {
                            selectedCommunity = v;
                          });
                          checkAdminStatus();
                          _homeDashBoardBloc
                              ?.setDefaultCommunity(
                            context: context,
                            community: v ?? CommunityModel({}),
                          )
                              ?.then((_) {
                            SevaCore.of(context).loggedInUser.currentCommunity =
                                v?.id ?? '';
                            SevaCore.of(context).loggedInUser.currentTimebank =
                                v?.primary_timebank ?? '';
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SwitchTimebank(content: ""),
                              ),
                            );
                          });
                        }
                      },
                      items: List.generate(
                        snapshot.data?.length ?? 0,
                        (index) => DropdownMenuItem(
                          value: snapshot.data![index],
                          child: Text(
                            ((snapshot.data![index].name ?? '').isEmpty
                                ? (S.of(context).loading ?? 'Loading')
                                : (snapshot.data![index].name ??
                                    (S.of(context).loading ?? 'Loading'))),
                            style: TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: Text(S.of(context).loading,
                          style: TextStyle(color: Colors.white)),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        final user = SevaCore.of(context).loggedInUser;
                        _homeDashBoardBloc?.refreshCommunities(user);
                      },
                    ),
                  ],
                );
              }
            },
          ),
          actions: <Widget>[
            CommonHelpIconWidget(),
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Builder(builder: (context) {
                      return BlocProvider(
                        bloc: _user,
                        child: SearchPage(
                          bloc: _homeDashBoardBloc!,
                          user: SevaCore.of(context).loggedInUser,
                          timebank: selectedCommunity != null
                              ? TimebankModel.fromMap(
                                  {'id': selectedCommunity!.primary_timebank})
                              : null,
                          community: selectedCommunity ?? CommunityModel({}),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        ),
        body: selectedCommunity == null
            ? Container(
                color: Colors.white,
                child: LoadingIndicator(),
              )
            : (selectedCommunity!.id ?? '').isEmpty
                ? Container(
                    color: Colors.white,
                    child: Center(
                      child: Text('No community selected'),
                    ),
                  )
                : DefaultTabController(
                    length: isAdmin ? tabLength + 1 : tabLength,
                    child: Column(
                      children: <Widget>[
                        SandBoxBanner(
                            title: S.of(context).sandbox_community ??
                                'Sandbox Community',
                            communityModel: selectedCommunity),
                        // ShowLimitBadge(),
                        TabBar(
                          onTap: (int index) {
                            switch (index) {
                              case 2:
                                AppConfig.helpIconContextMember =
                                    HelpContextMemberType.events;
                                break;
                              case 3:
                                AppConfig.helpIconContextMember =
                                    HelpContextMemberType.requests;
                                break;
                              case 4:
                                AppConfig.helpIconContextMember =
                                    HelpContextMemberType.offers;
                                break;
                              case 5:
                                AppConfig.helpIconContextMember =
                                    HelpContextMemberType.groups;
                                break;
                              default:
                                AppConfig.helpIconContextMember =
                                    HelpContextMemberType.seva_community;
                                break;
                            }
                            logger.i(
                                "tabbar index tapped is $index with ${AppConfig.helpIconContextMember}");
                          },
                          labelPadding: EdgeInsets.symmetric(horizontal: 10),
                          // controller: _timebankController,
                          indicatorColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.black,
                          labelColor: Theme.of(context).primaryColor,
                          isScrollable: true,
                          tabs: List.generate(
                            isAdmin ? tabLength + 1 : tabLength,
                            (index) => Tab(
                              text: _tabsNames[index] ?? 'Tab ${index + 1}',
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: <Widget>[
                              TimebankHomePage(
                                selectedCommunity: selectedCommunity!,
                                userId: SevaCore.of(context)
                                        .loggedInUser
                                        .sevaUserID ??
                                    '',
                                communityId: selectedCommunity!.id ?? '',
                              ),
                              DiscussionList(
                                loggedInUser: SevaCore.of(context)
                                        .loggedInUser
                                        .sevaUserID ??
                                    '',
                                selectedCommunity: selectedCommunity!,
                              ),
                              TimeBankProjectsView(
                                timebankId: selectedCommunity!.primary_timebank,
                                timebankModel: TimebankModel.fromMap({
                                  'id':
                                      selectedCommunity!.primary_timebank ?? ''
                                }),
                                selectedCommunity: selectedCommunity,
                              ),
                              RequestListingPage(
                                timebankModel: currentTimebank,
                                isFromSettings: false,
                              ),
                              OfferRouter(
                                timebankId:
                                    selectedCommunity!.primary_timebank ?? '',
                                timebankModel: TimebankModel.fromMap({
                                  'id':
                                      selectedCommunity!.primary_timebank ?? ''
                                }),
                              ),
                              Builder(
                                builder: (context) {
                                  logger.i(
                                      'Building GroupPage tab for community: ${selectedCommunity!.id ?? ''}');
                                  return GroupPage(
                                    communityId: selectedCommunity!.id ?? '',
                                  );
                                },
                              ),
                              TimeBankAboutView.of(
                                communityModel: selectedCommunity,
                                email:
                                    SevaCore.of(context).loggedInUser.email ??
                                        '',
                                userId: SevaCore.of(context)
                                        .loggedInUser
                                        .sevaUserID ??
                                    '',
                              ),
                              MembersPage(
                                timebankId:
                                    selectedCommunity!.primary_timebank ?? '',
                              ),
                              // TimebankRequestAdminPage(
                              //   isUserAdmin: isAccessAvailable(
                              //           primaryTimebank,
                              //           SevaCore.of(context)
                              //               .loggedInUser
                              //               .sevaUserID) ||
                              //       primaryTimebank.organizers.contains(
                              //         SevaCore.of(context).loggedInUser.sevaUserID,
                              //       ),
                              //   timebankId: primaryTimebank.id,
                              //   userEmail: SevaCore.of(context).loggedInUser.email,
                              //   isCommunity: true,
                              //   isFromGroup: false,
                              // ),
                              ...isAdmin
                                  ? [
                                      (selectedCommunity != null &&
                                              (selectedCommunity!.id ?? '')
                                                  .isNotEmpty)
                                          ? ManageTimebankSeva.of(
                                              timebankModel:
                                                  TimebankModel.fromMap({
                                                'id': selectedCommunity!
                                                        .primary_timebank ??
                                                    '',
                                                'community_id':
                                                    selectedCommunity!.id ?? ''
                                              }),
                                            )
                                          : LoadingIndicator(),
                                    ]
                                  : []
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
