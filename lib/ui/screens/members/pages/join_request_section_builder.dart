import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/new_baseline/models/join_request_model.dart';
import 'package:sevaexchange/new_baseline/models/timebank_model.dart';
import 'package:sevaexchange/ui/screens/members/bloc/join_request_bloc.dart';
import 'package:sevaexchange/ui/screens/members/bloc/members_bloc.dart';
import 'package:sevaexchange/ui/screens/members/pages/members_page.dart';
import 'package:sevaexchange/ui/screens/members/widgets/short_profile_card.dart';
import 'package:sevaexchange/models/manual_time_model.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';
import 'package:shimmer/shimmer.dart';

class JoinRequestSectionBuilder extends StatelessWidget {
  const JoinRequestSectionBuilder({
    Key? key,
    required this.joinRequestBloc,
    required this.timebankModel,
  }) : super(key: key);

  final JoinRequestBloc joinRequestBloc;
  final TimebankModel timebankModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: StreamBuilder<List<JoinRequestModel>>(
        stream: joinRequestBloc.joinRequests,
        builder: (_, snapshot) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return Container();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).requests,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ListBody(
                children: List.generate(
                  snapshot.data!.length,
                  (index) {
                    final joinReq = snapshot.data![index];
                    if ((joinReq.userId ?? '').isEmpty)
                      return Container(height: 40);

                    return FutureBuilder<UserModel>(
                      future: Provider.of<MembersBloc>(context, listen: false)
                          .getUserModel(userId: joinReq.userId ?? ''),
                      builder: (_, userSnapshot) {
                        if (userSnapshot.hasError) return Container(height: 40);
                        if (userSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            userSnapshot.data == null) {
                          return Container(height: 40);
                        }

                        final user = userSnapshot.data!;
                        return Row(
                          children: [
                            Expanded(
                              child: ShortProfileCard(
                                key: ValueKey(
                                    user.sevaUserID ?? index.toString()),
                                model: user,
                                role: UserRole.Member,
                                actionButton: PopupMenuButton<dynamic>(
                                  itemBuilder: (context) => [],
                                ),
                              ),
                            ),
                            CustomElevatedButton(
                              child: Text(S.of(context).approve),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              color: Colors.green,
                              textColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 2,
                              onPressed: () {
                                final joinRequestModel = joinReq;
                                joinRequestBloc.addMemberToTimebank(
                                  timebankModel: timebankModel,
                                  timebankId: joinRequestModel.entityId ?? '',
                                  joinRequestId: joinRequestModel.id ?? '',
                                  memberJoiningSevaUserId:
                                      joinRequestModel.userId ?? '',
                                  notificaitonId:
                                      joinRequestModel.notificationId ?? '',
                                  communityId: SevaCore.of(context)
                                          .loggedInUser
                                          .currentCommunity ??
                                      '',
                                  newMemberJoinedEmail: user.email ?? '',
                                  isFromGroup: joinRequestModel.isFromGroup,
                                  memberFullName: user.fullname ?? '',
                                  memberPhotoUrl: user.photoURL ?? '',
                                  adminEmail:
                                      SevaCore.of(context).loggedInUser.email ??
                                          '',
                                  adminId: SevaCore.of(context)
                                          .loggedInUser
                                          .sevaUserID ??
                                      '',
                                  adminFullName: SevaCore.of(context)
                                          .loggedInUser
                                          .fullname ??
                                      '',
                                  adminPhotoUrl: SevaCore.of(context)
                                          .loggedInUser
                                          .photoURL ??
                                      '',
                                  timebankTitle:
                                      joinRequestModel.timebankTitle ?? '',
                                );
                              },
                            ),
                            SizedBox(width: 12),
                            CustomElevatedButton(
                              child: Text(S.of(context).reject),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              color: Colors.red,
                              textColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 2,
                              onPressed: () {
                                final joinRequestModel = joinReq;
                                joinRequestBloc.rejectMemberJoinRequest(
                                  timebankModel: timebankModel,
                                  timebankId: joinRequestModel.entityId ?? '',
                                  joinRequestId: joinRequestModel.id ?? '',
                                  notificaitonId:
                                      joinRequestModel.notificationId ?? '',
                                  communityId: SevaCore.of(context)
                                          .loggedInUser
                                          .currentCommunity ??
                                      '',
                                  memberFullName: user.fullname ?? '',
                                  memberPhotoUrl: user.photoURL ?? '',
                                  adminEmail:
                                      SevaCore.of(context).loggedInUser.email ??
                                          '',
                                  adminId: SevaCore.of(context)
                                          .loggedInUser
                                          .sevaUserID ??
                                      '',
                                  adminFullName: SevaCore.of(context)
                                          .loggedInUser
                                          .fullname ??
                                      '',
                                  adminPhotoUrl: SevaCore.of(context)
                                          .loggedInUser
                                          .photoURL ??
                                      '',
                                  timebankTitle:
                                      joinRequestModel.timebankTitle ?? '',
                                  memberEmail: user.email ?? '',
                                  memberId: user.sevaUserID ?? '',
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget get shimmerWidget {
    return Shimmer.fromColors(
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.grey.withAlpha(40),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
            title: Container(
              color: Colors.grey.withAlpha(90),
              height: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.withAlpha(90),
            ),
            subtitle: Container(
              color: Colors.grey.withAlpha(90),
              height: 8,
            )),
      ),
      baseColor: Colors.grey,
      highlightColor: Colors.white,
    );
  }
}
