import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sevaexchange/constants/sevatitles.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/chat_model.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/timebank_model.dart';
import 'package:sevaexchange/new_baseline/models/community_model.dart';
import 'package:sevaexchange/ui/screens/sponsors/sponsors_widget.dart';
import 'package:sevaexchange/ui/screens/sponsors/widgets/get_user_verified.dart';
import 'package:sevaexchange/ui/screens/user_info/pages/donations_details_view.dart';
import 'package:sevaexchange/ui/screens/user_info/pages/user_donations.dart';
import 'package:sevaexchange/ui/utils/message_utils.dart';
import 'package:sevaexchange/utils/data_managers/user_data_manager.dart';
import 'package:sevaexchange/utils/firestore_manager.dart' as FirestoreManager;
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';
import 'package:sevaexchange/views/timebanks/widgets/timebank_seva_coin.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';
import 'package:sevaexchange/widgets/user_profile_image.dart';

class TimeBankAboutView extends StatefulWidget {
  final CommunityModel? communityModel;
  final String? email;
  final String? userId;
  TimeBankAboutView.of({this.communityModel, this.email, this.userId});

  @override
  _TimeBankAboutViewState createState() => _TimeBankAboutViewState();
}

class _TimeBankAboutViewState extends State<TimeBankAboutView>
    with AutomaticKeepAliveClientMixin {
  bool descTextShowFlag = false;
  bool isUserJoined = false;
  String? loggedInUser;
  UserModelListMoreStatus? userModels;
  UserModel user = UserModel();
  bool isDataLoaded = false;
  bool isAdminLoaded = false;
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => getData());
    }

    super.initState();
  }

  void getData() async {
    if (widget.communityModel == null) {
      setState(() {
        isDataLoaded = true;
        isAdminLoaded = true;
      });
      return;
    }
    if (widget.communityModel!.created_by != null &&
        widget.communityModel!.created_by!.isNotEmpty) {
      await FirestoreManager.getUserForId(
              sevaUserId: widget.communityModel!.created_by)
          .then((onValue) {
        user = onValue;
        setState(() {
          isAdminLoaded = true;
        });
      });
    } else {
      setState(() {
        isAdminLoaded = true;
      });
    }
    var templist = [
      ...widget.communityModel!.organizers ?? [],
      ...widget.communityModel!.admins ?? []
    ];
    isUserJoined = templist.contains(widget.userId) ? true : false;
    isDataLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.communityModel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('No community data available.'),
        ),
      );
    }
    super.build(context);
    var futures = <Future>[];

    if (widget.communityModel!.members != null) {
      widget.communityModel!.members.forEach((member) {
        futures.add(getUserForId(sevaUserId: member));
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: CachedNetworkImage(
                    imageUrl: widget.communityModel!.cover_url ??
                        defaultGroupImageURL,
                    fit: BoxFit.cover,
                    height: 200,
                    errorWidget: (context, url, error) => Image(
                      fit: BoxFit.cover,
                      width: 620,
                      height: 180,
                      image: NetworkImage(defaultGroupImageURL),
                    ),
                    placeholder: (context, url) {
                      return LoadingIndicator();
                    },
                  ),
                ),
                Positioned(
                  child: Container(
                    child: CachedNetworkImage(
                      imageUrl: (widget.communityModel!.logo_url == null ||
                              widget.communityModel!.logo_url == '')
                          ? defaultUserImageURL
                          : widget.communityModel!.logo_url,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 70,
                      placeholder: (context, url) {
                        return LoadingIndicator();
                      },
                      errorWidget: (context, url, error) => Image(
                        fit: BoxFit.cover,
                        width: 100,
                        height: 70,
                        image: NetworkImage(defaultUserImageURL),
                      ),
                    ),
                  ),
                  left: 13.0,
                  bottom: -38.0,
                ),
              ],
            ),
            SizedBox(
              height: 45,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 5),
              child: Text(
                widget.communityModel!.name ?? "Community Name Not Available",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Europa',
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            isUserJoined
                ? TimeBankSevaCoin(
                    isAdmin: isAccessAvailable(
                        TimebankModel.fromMap({
                          'id': widget.communityModel!.primary_timebank ?? '',
                          'admins': widget.communityModel!.admins ?? [],
                          'organizers': widget.communityModel!.organizers ?? [],
                        }),
                        SevaCore.of(context).loggedInUser.sevaUserID!),
                    loggedInUser: SevaCore.of(context).loggedInUser,
                    timebankData: TimebankModel.fromMap({
                      'id': widget.communityModel!.primary_timebank ?? '',
                      'name': widget.communityModel!.name ?? '',
                      'photoUrl': widget.communityModel!.logo_url ?? '',
                    }))
                : Offstage(),
            SizedBox(
              height: 15,
            ),
            // isAccessAvailable(
            //   widget.timebankModel,
            //   SevaCore.of(context).loggedInUser.sevaUserID,
            // ) ? Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: TransactionsMatrixCheck(
            //           upgradeDetails:
            //               AppConfig.upgradePlanBannerModel.add_manual_time,
            //           transaction_matrix_type: "add_manual_time",
            //           child: AddManualTimeButton(
            //             typeId: widget.timebankModel.id,
            //             timebankId: widget.timebankModel.parentTimebankId ==
            //                     FlavorConfig.values.timebankId
            //                 ? widget.timebankModel.id
            //                 : widget.timebankModel.parentTimebankId,
            //             timeFor: ManualTimeType.Timebank,
            //             userType: getLoggedInUserRole(
            //               widget.timebankModel,
            //               SevaCore.of(context).loggedInUser.sevaUserID,
            //             ),
            //             communityName: widget.timebankModel.name,
            //           ),
            //         ),
            //       )
            //     : Container(),
            isAccessAvailable(
                    TimebankModel.fromMap({
                      'id': widget.communityModel!.primary_timebank,
                      'admins': widget.communityModel!.admins,
                      'organizers': widget.communityModel!.organizers,
                    }),
                    SevaCore.of(context).loggedInUser.sevaUserID!)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoodsAndAmountDonations(
                          userId: SevaCore.of(context).loggedInUser.sevaUserID!,
                          isGoods: false,
                          timebankId:
                              widget.communityModel!.primary_timebank ?? '',
                          isTimeBank: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DonationsDetailsView(
                                  id: widget.communityModel!.primary_timebank ??
                                      '',
                                  totalBalance:
                                      '', //change this to total of goods donated
                                  timebankModel: TimebankModel.fromMap({
                                    'id': widget
                                            .communityModel!.primary_timebank ??
                                        '',
                                    'name': widget.communityModel!.name ?? '',
                                    'photoUrl':
                                        widget.communityModel!.logo_url ?? '',
                                  }),
                                  fromTimebank: true,
                                  isGoods: false,
                                ),
                              ),
                            );
                          }),
                      SizedBox(
                        height: 15,
                      ),
                      GoodsAndAmountDonations(
                          userId: SevaCore.of(context).loggedInUser.sevaUserID!,
                          isGoods: true,
                          timebankId:
                              widget.communityModel!.primary_timebank ?? '',
                          isTimeBank: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DonationsDetailsView(
                                  id: widget.communityModel!.primary_timebank ??
                                      '',
                                  totalBalance:
                                      '', //change this to total of goods donated
                                  timebankModel: TimebankModel.fromMap({
                                    'id': widget
                                            .communityModel!.primary_timebank ??
                                        '',
                                    'name': widget.communityModel!.name ?? '',
                                    'photoUrl':
                                        widget.communityModel!.logo_url ?? '',
                                  }),
                                  fromTimebank: true,
                                  isGoods: true,
                                ),
                              ),
                            );
                          }),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  )
                : Offstage(),
            (widget.communityModel!.members != null &&
                    widget.communityModel!.members.contains(
                      SevaCore.of(context).loggedInUser.sevaUserID,
                    ))
                ? Container(
                    height: 40,
                    child: GestureDetector(
                      child: FutureBuilder(
                          future: Future.wait(futures),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Text(S.of(context).getting_volunteers),
                              );
                            }

                            if (widget.communityModel!.members == null ||
                                widget.communityModel!.members.isEmpty) {
                              return Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Text(S.of(context).no_volunteers_yet),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              // If the future completed but returned null, show placeholder
                              return Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Text(S.of(context).no_volunteers_yet),
                              );
                            }

                            final dataList = snapshot.data is List
                                ? (snapshot.data as List)
                                : <dynamic>[];

                            List<UserModel> memberPhotoUrlList = [];
                            // Only iterate over the items we actually received
                            for (var i = 0; i < dataList.length; i++) {
                              final item = dataList[i];
                              if (item is UserModel) {
                                memberPhotoUrlList.add(item);
                              }
                            }

                            if (memberPhotoUrlList.isEmpty) {
                              return Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Text(S.of(context).no_volunteers_yet),
                              );
                            }

                            return ListView(
                              padding: EdgeInsets.only(left: 15),
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                ...memberPhotoUrlList.map((user) {
                                  return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2.5),
                                      child: UserProfileImage(
                                        photoUrl: user.photoURL ??
                                            defaultUserImageURL,
                                        email: user.email ?? '',
                                        userId: user.sevaUserID ?? '',
                                        height: 40,
                                        width: 40,
                                        timebankModel: TimebankModel.fromMap({
                                          'id': widget.communityModel!
                                                  .primary_timebank ??
                                              ''
                                        }),
                                      ));
                                }).toList()
                              ],
                            );
                          }),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 20),
              child: Text(
                (widget.communityModel!.members != null
                        ? widget.communityModel!.members.length.toString()
                        : '0') +
                    ' ${S.of(context).members ?? 'Members'}',
                style: TextStyle(
                  fontFamily: 'Europa',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                widget.communityModel!.about ?? 'No description available',
                style: TextStyle(
                  fontFamily: 'Europa',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Divider(
                color: Colors.black12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 0, bottom: 5),
              child: Text(
                S.of(context).help_about_us ?? 'About Us',
                style: TextStyle(
                  fontFamily: 'Europa',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 5.0, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      widget.communityModel!.about ??
                          'No description available',
                      style: TextStyle(
                        fontFamily: 'Europa',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: descTextShowFlag ? null : 2,
                      textAlign: TextAlign.start),
                  InkWell(
                    onTap: () {
                      setState(() {
                        descTextShowFlag = !descTextShowFlag;
                      });
                    },
                    child: (widget.communityModel!.about != null &&
                            widget.communityModel!.about.length > 100)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              descTextShowFlag
                                  ? Text(
                                      S.of(context).read_less ?? 'Read Less',
                                      style: TextStyle(
                                        fontFamily: 'Europa',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightBlueAccent,
                                      ),
                                    )
                                  : Text(
                                      S.of(context).read_more ?? 'Read More',
                                      style: TextStyle(
                                        fontFamily: 'Europa',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightBlueAccent,
                                      ),
                                    )
                            ],
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
            Offstage(
              offstage: widget.communityModel!.billing_address == null ||
                      widget.communityModel!.billing_address.companyname ==
                          null ||
                      widget.communityModel!.billing_address.companyname.isEmpty
                  ? true
                  : false,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Divider(
                  color: Colors.black12,
                ),
              ),
            ),
            Offstage(
              offstage: widget.communityModel!.billing_address == null ||
                      widget.communityModel!.billing_address.companyname ==
                          null ||
                      widget.communityModel!.billing_address.companyname.isEmpty
                  ? true
                  : false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  'Billing: ${widget.communityModel!.billing_address.companyname}',
                  style: TextStyle(
                    fontFamily: 'Europa',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Divider(
                color: Colors.black12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                S.of(context).owner ?? 'Owner',
                style: TextStyle(
                  fontFamily: 'Europa',
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 20, bottom: 5, top: 5),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      isAdminLoaded
                          ? Text(
                              user.fullname ?? 'Admin Name Not Available',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Europa'),
                            )
                          : Container(
                              child: Text(S.of(context).admin_not_available),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            if (isAccessAvailable(
                                TimebankModel.fromMap({
                                  'id': widget.communityModel!.primary_timebank,
                                  'admins': widget.communityModel!.admins,
                                  'organizers':
                                      widget.communityModel!.organizers,
                                }),
                                SevaCore.of(context)
                                    .loggedInUser
                                    .sevaUserID!)) {
                              _showAdminMessage();
                            } else {
                              startChat(
                                widget.communityModel!.id ?? '',
                                widget.email ?? '',
                                context,
                                TimebankModel.fromMap({
                                  'id':
                                      widget.communityModel!.primary_timebank ??
                                          ''
                                }),
                              );
                            }
                          },
                          child: Text(
                            S.of(context).message ?? 'Message',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Europa',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  isAdminLoaded
                      ? UserProfileImage(
                          photoUrl: user.photoURL ?? defaultUserImageURL,
                          email: user.email ?? '',
                          userId: user.sevaUserID ?? '',
                          height: 60,
                          width: 60,
                          timebankModel: TimebankModel.fromMap({
                            'id': widget.communityModel!.primary_timebank ?? ''
                          }),
                        )
                      : CircleAvatar()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).admin_cannot_create_message ??
              'Admin cannot create message'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                right: 15,
                bottom: 15,
              ),
              child: CustomTextButton(
                color: Colors.grey,
                padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                shape: StadiumBorder(),
                child: Text(
                  S.of(context).close ?? 'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Europa',
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

var timeStamp = DateTime.now().millisecondsSinceEpoch;

void startChat(
  String email,
  String loggedUserEmail,
  BuildContext context,
  TimebankModel timebankModel,
) async {
  if (email == loggedUserEmail) {
    return null;
  } else {
    UserModel loggedInUser = SevaCore.of(context).loggedInUser;
    ParticipantInfo sender = ParticipantInfo(
      id: loggedInUser.sevaUserID,
      name: loggedInUser.fullname,
      photoUrl: loggedInUser.photoURL,
      type: ChatType.TYPE_PERSONAL,
    );

    ParticipantInfo reciever = ParticipantInfo(
      id: timebankModel.id,
      name: timebankModel.name,
      photoUrl: timebankModel.photoUrl,
      type: ChatType.TYPE_TIMEBANK,
    );
    createAndOpenChat(
      context: context,
      timebankId: timebankModel.id,
      sender: sender,
      reciever: reciever,
      communityId: loggedInUser.currentCommunity!,
      isTimebankMessage: true,
      feedId: '', // Provide appropriate value if needed
      onChatCreate: () {}, // Provide appropriate callback if needed
      showToCommunities: [], // Provide appropriate value if needed
      entityId: timebankModel.id, // Provide appropriate value if needed
    );
  }
}
