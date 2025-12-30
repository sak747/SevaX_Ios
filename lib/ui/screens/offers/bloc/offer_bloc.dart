import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/subjects.dart';
import 'package:sevaexchange/models/offer_model.dart';
import 'package:sevaexchange/models/offer_participants_model.dart';
import 'package:sevaexchange/models/transaction_model.dart';
import 'package:sevaexchange/new_baseline/models/borrow_accpetor_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/ui/screens/offers/pages/lending_offer_participants.dart';
import 'package:sevaexchange/ui/screens/offers/pages/time_offer_participant.dart';
import 'package:sevaexchange/ui/utils/offer_dialogs.dart';
import 'package:sevaexchange/utils/bloc_provider.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class OfferBloc extends BlocBase {
  final _participants = BehaviorSubject<List<OfferParticipantsModel>>();
  final _completedParticipants =
      BehaviorSubject<List<TimeOfferParticipantsModel>>();
  final _timeOfferParticipants =
      BehaviorSubject<List<TimeOfferParticipantsModel>>();
  final _totalEarnings = BehaviorSubject<num>.seeded(0.0);

  OfferModel? offerModel;

  Stream<List<OfferParticipantsModel>> get participants => _participants.stream;

  Stream<List<TimeOfferParticipantsModel>> get timeOfferParticipants =>
      _timeOfferParticipants.stream;

  Stream<List<TimeOfferParticipantsModel>> get completedParticipants =>
      _completedParticipants.stream;

  Stream<num> get totalEarnings => _totalEarnings.stream;

  void init() {
    if (offerModel == null ||
        offerModel?.id == null ||
        offerModel!.id!.isEmpty) {
      logger.w('OfferBloc.init called without an offerModel or id');
      return;
    }

    try {
      CollectionRef.offers
          .doc(offerModel!.id)
          .collection("offerParticipants")
          .snapshots()
          .listen((QuerySnapshot snap) {
        try {
          List<OfferParticipantsModel> offer = [];
          snap.docs.forEach((DocumentSnapshot doc) {
            try {
              OfferParticipantsModel model = OfferParticipantsModel.fromJson(
                  doc.data() as Map<String, dynamic>);
              model.id = doc.id;
              offer.add(model);
            } catch (e) {
              logger.e("Error parsing offer participant: $e");
            }
          });
          _participants.add(offer);
        } catch (e) {
          logger.e("Error processing offer participants snapshot: $e");
        }
      }, onError: (error) {
        logger.e("Error listening to offer participants: $error");
      });

      CollectionRef.offers
          .doc(offerModel!.id!)
          .collection("offerAcceptors")
          .snapshots()
          .listen((QuerySnapshot snap) async {
        try {
          List<TransactionModel> completedParticipantsTransactions =
              await getCompletedMembersTransaction(
                  associatedOfferId: offerModel!.id!);

          List<TimeOfferParticipantsModel> offer = [];
          List<TimeOfferParticipantsModel> completedParticipants = [];
          _totalEarnings.value = 0;

          for (int i = 0; i < snap.docs.length; i++) {
            try {
              TimeOfferParticipantsModel model =
                  TimeOfferParticipantsModel.fromJSON(
                      snap.docs[i].data() as Map<String, dynamic>);
              offer.add(model);

              for (int j = 0;
                  j < completedParticipantsTransactions.length;
                  j++) {
                if (completedParticipantsTransactions[j].from ==
                        model.participantDetails?.sevauserid ||
                    completedParticipantsTransactions[j].from ==
                        model.timebankId) {
                  completedParticipants.add(model);
                  _totalEarnings.value +=
                      (completedParticipantsTransactions[j].credits ?? 0);
                  completedParticipantsTransactions.removeAt(j);
                }
              }
            } catch (e) {
              logger.e("Error processing offer acceptor at index $i: $e");
            }
          }
          _timeOfferParticipants.add(offer);
          _completedParticipants.add(completedParticipants);
        } catch (e) {
          logger.e("Error processing offer acceptors snapshot: $e");
        }
      }, onError: (error) {
        logger.e("Error listening to offer acceptors: $error");
      });
    } catch (e) {
      logger.e("Error initializing OfferBloc: $e");
    }
  }

  Future<List<TransactionModel>> getCompletedMembersTransaction({
    String? associatedOfferId,
  }) async {
    var completedParticipants = <TransactionModel>[];

    try {
      await CollectionRef.transactions
          .where('offerId', isEqualTo: associatedOfferId)
          .get()
          .then(
        (value) {
          // Add comprehensive null safety check
          if (value != null && value.docs != null) {
            logger.i(" >>>>>>>> " + value.docs.length.toString());
            value.docs.forEach((map) {
              try {
                if (map.data() != null) {
                  var model = TransactionModel.fromMap(
                      map.data() as Map<String, dynamic>);
                  completedParticipants.add(model);
                } else {
                  logger.w("Transaction document has null data");
                }
              } catch (e) {
                logger.e("Error parsing transaction model: $e");
              }
            });
          } else {
            if (value == null) {
              logger.w("Query result is null for offerId: $associatedOfferId");
            } else if (value.docs == null) {
              logger.w(
                  "Query result docs is null for offerId: $associatedOfferId");
            }
          }
        },
      );
    } catch (e) {
      logger.e("Error fetching completed members transaction: $e");
      // Return empty list on error instead of throwing
    }

    return completedParticipants;
  }

  void handleRequestActions(context, index, ParticipantStatus status) {
    DocumentReference ref = CollectionRef.offers
        .doc(offerModel!.id)
        .collection("offerParticipants")
        .doc(_participants.value[index].id);

    if (status == ParticipantStatus.NO_ACTION_FROM_CREATOR) {
      ref.update(
        {
          "status":
              ParticipantStatus.NO_ACTION_FROM_CREATOR.toString().split('.')[1],
        },
      );
    }
    if (status == ParticipantStatus.NO_ACTION_FROM_CREATOR) {
      ref.update(
        {
          "status": ParticipantStatus.CREATOR_REQUESTED_CREDITS
              .toString()
              .split('.')[1]
        },
      );
    }

    if ([
      ParticipantStatus.MEMBER_DID_NOT_ATTEND,
      ParticipantStatus.MEMBER_REJECTED_CREDIT_REQUEST,
      ParticipantStatus.MEMBER_TRANSACTION_FAILED
    ].contains(status)) {
      requestAgainDialog(context, ref);
    }
  }

  void updateOfferAcceptorAction({
    OfferAcceptanceStatus? action,
    String? offerId,
    String? acceptorDocumentId,
    String? notificationId,
    required String? hostEmail,
  }) {
    var batch = CollectionRef.batch;

    batch.update(
        CollectionRef.offers
            .doc(offerId)
            .collection("offerAcceptors")
            .doc(acceptorDocumentId),
        {"status": action?.readable});

    batch.delete(CollectionRef.users
        .doc(hostEmail)
        .collection('notifications')
        .doc(notificationId));

    batch.commit();
  }

  @override
  void dispose() {
    _participants.close();
    _timeOfferParticipants.close();
    _completedParticipants.close();
    _totalEarnings.close();
  }
}
