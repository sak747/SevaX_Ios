import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/localization/applanguage.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/ui/screens/explore/pages/explore_page.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_page_base_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/user_data_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/widgets/bottom_nav_bar.dart';
import 'package:sevaexchange/ui/screens/members/bloc/members_bloc.dart';
import 'package:sevaexchange/ui/screens/message/bloc/message_bloc.dart';
import 'package:sevaexchange/ui/screens/message/pages/message_page_router.dart';
import 'package:sevaexchange/ui/screens/notifications/bloc/notifications_bloc.dart';
import 'package:sevaexchange/ui/screens/notifications/pages/combined_notification_page.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/firestore_manager.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/views/profile/profile.dart';
import 'package:sevaexchange/views/splash_view.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';
import 'package:sevaexchange/widgets/customise_community/theme_bloc.dart';
import 'package:sevaexchange/utils/firestore_manager.dart' as FirestoreManager;

import '../../../../flavor_config.dart';
import 'home_dashboard.dart';

class HomePageRouter extends StatefulWidget {
  // final UserModel userModel;

  const HomePageRouter({
    Key? key,
    // @required this.userModel
  }) : super(key: key);

  @override
  _BottomNavBarRouterState createState() => _BottomNavBarRouterState();
}

class _BottomNavBarRouterState extends State<HomePageRouter> {
  final AppLanguage appLanguage = AppLanguage();
  int selected = 2;
  UserDataBloc _userBloc = UserDataBloc();
  MessageBloc _messageBloc = MessageBloc();
  NotificationsBloc _notificationsBloc = NotificationsBloc();
  List<Widget> pages = [
    ExplorePage(
      isUserSignedIn: true,
    ),
    // ExploreTabView(),
    CombinedNotificationsPage(),
    HomeDashBoard(),
    MessagePageRouter(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sevaCore = SevaCore.of(context);
      logger.i('SevaCore: $sevaCore');
      if (sevaCore != null) {
        logger.i(
            'LoggedInUser email: ${sevaCore.loggedInUser.email}, currentCommunity: ${sevaCore.loggedInUser.currentCommunity}');
      }
      if (sevaCore != null &&
          sevaCore.loggedInUser.email != null &&
          sevaCore.loggedInUser.currentCommunity != null &&
          sevaCore.loggedInUser.currentCommunity!.isNotEmpty) {
        logger.i(
            'Calling getData with email: ${sevaCore.loggedInUser.email}, communityId: ${sevaCore.loggedInUser.currentCommunity}');
        _userBloc.getData(
          email: sevaCore.loggedInUser.email!,
          communityId: sevaCore.loggedInUser.currentCommunity!,
        );
      } else {
        logger.w('getData not called: Missing user data - email: ${sevaCore.loggedInUser.email}, currentCommunity: ${sevaCore.loggedInUser.currentCommunity}');
        // If no currentCommunity, try to set a default one from user's communities
        if (sevaCore.loggedInUser.communities != null && sevaCore.loggedInUser.communities!.isNotEmpty) {
          String defaultCommunity = sevaCore.loggedInUser.communities!.first;
          logger.i('Setting default community to: $defaultCommunity');
          sevaCore.loggedInUser.currentCommunity = defaultCommunity;
          _userBloc.getData(
            email: sevaCore.loggedInUser.email!,
            communityId: defaultCommunity,
          );
        }
      }
      Provider.of<HomePageBaseBloc>(context, listen: false)
          .init(sevaCore.loggedInUser);
      _userBloc.userStream.listen((UserModel user) async {
        try {
          if (user.currentCommunity != null &&
              user.currentCommunity!.isNotEmpty) {
            Provider.of<MembersBloc>(context, listen: false)
                .init(user.currentCommunity!);

            _notificationsBloc.init(
              user.email!,
              user.sevaUserID!,
              user.currentCommunity!,
            );

            // var membersList =
            //     await Provider.of<MembersBloc>(context, listen: false)
            //         .members
            //         .first;

            _messageBloc.fetchAllMessage(
              user.currentCommunity!,
              user,
              // membersList,
            );
            CommunityModel communityModel =
                await FirestoreManager.getCommunityDetailsByCommunityId(
                    communityId: user.currentCommunity!);
            Provider.of<ThemeBloc>(context, listen: false).changeColor(HexColor(
                (communityModel.theme_color == null ||
                        communityModel.theme_color.isEmpty)
                    ? '2596BE'
                    : communityModel.theme_color));
            logger.e(communityModel.toString());
            AppConfig.isTestCommunity = communityModel.testCommunity ?? false;
            logger.i('User stream processed successfully');
          } else {
            logger.w(
                'User currentCommunity is null or empty, skipping initialization');
          }
        } catch (e, stackTrace) {
          logger.e('Error processing user stream: $e\n$stackTrace');
          // Navigate back to login on error
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SplashView()),
            ((Route<dynamic> route) => false),
          );
        }
      }, onError: (error) {
        logger.e('User stream error: $error');
        // Navigate back to login on error
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => SplashView()),
          ((Route<dynamic> route) => false),
        );
      });
    });
  }

  @override
  void dispose() {
    _userBloc.dispose();
    _messageBloc.dispose();
    _notificationsBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Phoenix(
        child: ChangeNotifierProvider<AppLanguage>(
      create: (_) => appLanguage,
      child: Consumer<AppLanguage>(
        builder: (context, model, child) {
          return StreamBuilder<Color>(
              initialData: Color(0xFF2596BE),
              stream: Provider.of<ThemeBloc>(context).color,
              builder: (context, snapshot) {
                logger.e("Here is the color " + snapshot.data.toString());
                return MaterialApp(
                  builder: (context, child) {
                    return GestureDetector(
                      child: child,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                  locale: model.appLocal,
                  supportedLocales: S.delegate.supportedLocales,
                  localizationsDelegates: [
                    S.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  title: AppConfig.appName,
                  debugShowCheckedModeBanner: false,
                  theme: (FlavorConfig.values.theme ?? ThemeData()).copyWith(
                      primaryColor: snapshot.data,
                      buttonTheme: ButtonThemeData(buttonColor: snapshot.data)),
                  home: BlocProvider<UserDataBloc>(
                    bloc: _userBloc,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: StreamBuilder<UserModel>(
                        stream: _userBloc.userStream,
                        builder: (context, AsyncSnapshot<UserModel> snapshot) {
                          if (snapshot.hasError) {
                            logger.e(
                                'User StreamBuilder error: ${snapshot.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      'Error loading user data: ${snapshot.error}'),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      logger.i(
                                          'User clicked retry, navigating to SplashView');
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) => SplashView()),
                                        ((Route<dynamic> route) => false),
                                      );
                                    },
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            logger
                                .i('User StreamBuilder waiting for user data');
                            return LoadingIndicator();
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            UserModel loggedInUser = snapshot.data!;
                            // Check if community data is available or has error
                            logger.i(
                                'Checking community data: ${_userBloc.community}');
                            return StreamBuilder<CommunityModel>(
                              stream: _userBloc.comunityStream,
                              builder: (context,
                                  AsyncSnapshot<CommunityModel>
                                      communitySnapshot) {
                                if (communitySnapshot.hasError) {
                                  logger.e(
                                      'Community StreamBuilder error: ${communitySnapshot.error}');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            'Error loading community data: ${communitySnapshot.error}'),
                                        SizedBox(height: 20),
                                        ElevatedButton(
                                          onPressed: () {
                                            logger.i(
                                                'User clicked retry after community error, navigating to SplashView');
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SplashView()),
                                              ((Route<dynamic> route) => false),
                                            );
                                          },
                                          child: Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (communitySnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  logger.i(
                                      'Community StreamBuilder waiting for community data');
                                  return LoadingIndicator();
                                }
                                if (communitySnapshot.hasData &&
                                    communitySnapshot.data != null) {
                                  try {
                                    logger.i(
                                        'Setting currentTimebank from community: ${communitySnapshot.data!.primary_timebank}');
                                    loggedInUser.currentTimebank =
                                        communitySnapshot
                                            .data!.primary_timebank ?? '';
                                    loggedInUser.associatedWithTimebanks =
                                        loggedInUser.communities?.length ?? 0;

                                    SevaCore.of(context).loggedInUser =
                                        loggedInUser;
                                    logger.i(
                                        'User and community data set successfully');

                                    if (loggedInUser.communities == null ||
                                        loggedInUser.communities?.isEmpty ==
                                            true) {
                                      logger.w(
                                          'User has no communities, redirecting to SplashView');
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SplashView()),
                                          ((Route<dynamic> route) => false),
                                        );
                                      });
                                    }
                                  } catch (e, stackTrace) {
                                    logger.e(
                                        'Error setting user data: $e\n$stackTrace');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Error setting user data: $e'),
                                          SizedBox(height: 20),
                                          ElevatedButton(
                                            onPressed: () {
                                              logger.i(
                                                  'User clicked retry after data setting error');
                                              Navigator.of(context)
                                                  .pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SplashView()),
                                                ((Route<dynamic> route) =>
                                                    false),
                                              );
                                            },
                                            child: Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return Stack(
                                    children: <Widget>[
                                      BlocProvider<NotificationsBloc>(
                                        bloc: _notificationsBloc,
                                        child: BlocProvider<MessageBloc>(
                                          bloc: _messageBloc,
                                          child: Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height -
                                                65,
                                            child: pages[selected],
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey[300] ??
                                                    Colors.grey,
                                                blurRadius: 100.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: BlocProvider(
                                          bloc: _notificationsBloc,
                                          child: BlocProvider<MessageBloc>(
                                            bloc: _messageBloc,
                                            child: CustomBottomNavigationBar(
                                              selected: selected,
                                              onChanged: (index) {
                                                selected = index;
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  logger.e(
                                      'Community data is null, navigating to login');
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) => SplashView()),
                                      ((Route<dynamic> route) => false),
                                    );
                                  });
                                  return LoadingIndicator(); // Temporary while navigating
                                }
                              },
                            );
                          } else {
                            return LoadingIndicator();
                          }
                        },
                      ),
                    ),
                  ),
                );
              });
        },
      ),
    ));
  }
}
