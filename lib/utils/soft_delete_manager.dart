import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:sevaexchange/components/ProfanityDetector.dart';
import 'package:sevaexchange/constants/sevatitles.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/data_model.dart';
import 'package:sevaexchange/new_baseline/models/profanity_image_model.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/utils/helpers/mailer.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:sevaexchange/utils/utils.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';

import '../flavor_config.dart';

String failureMessage =
    "Sending request failed somehow, please try again later!";

String successTitle = "Request submitted";
String failureTitle = "Request failed!";
String reason = "";
final GlobalKey<FormState> _formKey = GlobalKey();

ProgressDialog? progressDialog;
Timer? _progressTimeoutTimer;

enum SoftDelete {
  REQUEST_DELETE_GROUP,
  REQUEST_DELETE_TIMEBANK,
  REQUEST_DELETE_PROJECT,
  REQUEST_DELETE_COMMUNITY,
}

Future<bool> checkExistingRequest({
  String? associatedId,
}) async {
  return await CollectionRef.softDeleteRequests
      .where('requestStatus', isEqualTo: 'REQUESTED')
      .where('associatedId', isEqualTo: associatedId)
      .get()
      .then(
    (onValue) {
      return onValue.docs.length > 0;
    },
  ).catchError((onError) {
    return false;
  });
}

Future<bool> showAdvisoryBeforeDeletion({
  required BuildContext context,
  SoftDelete? softDeleteType,
  String? associatedId,
  String? email,
  String? associatedContentTitle,
  bool? isAccedentalDeleteEnabled,
}) async {
  final profanityDetector = ProfanityDetector();

  logger.d(
      'showAdvisoryBeforeDeletion start: type=$softDeleteType associatedId=$associatedId email=$email');

  // Use custom linear progress dialog instead of ProgressDialog (more reliable on web)
  // Set a timeout to prevent infinite loading
  _progressTimeoutTimer = Timer(Duration(seconds: 30), () {
    try {
      if (buildContextForLinearProgress != null) {
        Navigator.of(buildContextForLinearProgress!).pop();
      }
    } catch (e) {
      logger.w('Timeout: failed to hide progress dialog: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Operation timed out. Please try again.'),
        duration: Duration(seconds: 3),
      ),
    );
  });

  showLinearProgress(context: context);
  var isAlreadyRequested = await checkExistingRequest(
    associatedId: associatedId,
  );
  _progressTimeoutTimer?.cancel();
  try {
    if (buildContextForLinearProgress != null) {
      Navigator.of(buildContextForLinearProgress!).pop();
    }
  } catch (e) {
    logger.w('Failed to hide progress dialog: $e');
  }

  if (isAlreadyRequested) {
    await _showRequestProcessingWithStatus(context: context);
    return true;
  }

  if (softDeleteType == SoftDelete.REQUEST_DELETE_GROUP ||
      softDeleteType == SoftDelete.REQUEST_DELETE_TIMEBANK) {
    if (isAccedentalDeleteEnabled!) {
      await _showAccedentalDeleteConfirmation(
        context: context,
        softDeleteType: softDeleteType!,
      );
      return true;
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext contextDialog) {
      return AlertDialog(
        title: Text(
          S.of(context).delete_confirmation + associatedContentTitle! + "?",
          style: TextStyle(fontSize: 17),
        ),
        content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getContentFromType(softDeleteType!, context),
                    style: TextStyle(fontSize: 15),
                  ),
                  TextFormField(
                    autofocus: true,
                    decoration: InputDecoration(
                      errorMaxLines: 2,
                      hintText: S.of(context).enter_reason_to_delete,
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 17.0),
                    inputFormatters: [
                      // LengthLimitingTextInputFormatter(50),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).enter_reason_to_delete_error;
                      } else if (profanityDetector.isProfaneString(value)) {
                        return S.of(context).profanity_text_alert;
                      } else {
                        reason = value;
                        return null;
                      }
                    },
                  ),
                ],
              ),
            )),
        actions: <Widget>[
          CustomElevatedButton(
            color: HexColor("#d2d2d2"),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2.0,
            textColor: Colors.black,
            onPressed: () {
              Navigator.pop(contextDialog);
            },
            child: Text(
              S.of(context).cancel,
            ),
          ),
          CustomTextButton(
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(contextDialog);
              // show linear progress while committing request
              showLinearProgress(context: context);

              try {
                logger.d('Registering soft delete request for $associatedId');

                final batch = registerSoftDeleteRequestFor(
                  softDeleteRequest: SoftDeleteRequest.createRequest(
                    associatedId: associatedId!,
                    requestType: _getModelType(softDeleteType),
                    reason: reason,
                  ),
                  softDeleteType: softDeleteType,
                );

                await batch.commit();

                logger.i('Soft delete request registered: ${associatedId}');

                //SEND EMAIL TO SEVA TEAM IN CASE TIMEBANK DELETION REQUEST IS MADE
                if (softDeleteType == SoftDelete.REQUEST_DELETE_TIMEBANK) {
                  await sendMailToSevaTeam(
                    associatedContentTitle: associatedContentTitle,
                    associatedId: associatedId,
                    senderEmail: email!,
                    softDeleteType: softDeleteType,
                  );
                  logger.d(
                      'Email sent to Seva team for timebank deletion request');
                }

                try {
                  if (buildContextForLinearProgress != null) {
                    Navigator.of(buildContextForLinearProgress!).pop();
                  }
                } catch (e) {
                  logger.w('Failed to hide progress dialog after commit: $e');
                }

                showFinalResultConfirmation(
                  context,
                  softDeleteType,
                  associatedId,
                  true,
                );
              } catch (e, stackTrace) {
                logger.e('Create soft delete request failed',
                    error: e, stackTrace: stackTrace);
                try {
                  if (buildContextForLinearProgress != null) {
                    Navigator.of(buildContextForLinearProgress!).pop();
                  }
                } catch (e) {
                  logger.w('Failed to hide progress dialog on error: $e');
                }

                // Show specific error message to user
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(S.of(context).request_failed),
                      content: Text(
                          "Failed to process deletion request: ${e.toString()}"),
                      actions: [
                        CustomElevatedButton(
                          color: HexColor("#d2d2d2"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(S.of(context).ok),
                        ),
                      ],
                    );
                  },
                );

                showFinalResultConfirmation(
                  context,
                  softDeleteType,
                  associatedId!,
                  false,
                );
              }
            },
            child: Text(
              S.of(context).delete + " " + associatedContentTitle,
            ),
          )
        ],
      );
    },
  );
  return false;
}

Future<bool> sendMailToSevaTeam({
  String? senderEmail,
  SoftDelete? softDeleteType,
  String? associatedContentTitle,
  String? associatedId,
}) async {
  return await SevaMailer.createAndSendEmail(
      mailContent: MailContent.createMail(
    mailSender: senderEmail!,
    mailReciever: "delete-timebank@sevaexchange.com",
    mailSubject:
        "Deletion request for ${_getModelType(softDeleteType!)} $associatedContentTitle by " +
            senderEmail +
            ".",
    mailContent: senderEmail +
        " has requested to delete ${_getModelType(softDeleteType)} $associatedContentTitle with unique-identity as $associatedId.",
  ));
}

class SoftDeleteRequest extends DataModel {
  late String id;
  late String? timestamp;
  late String? requestStatus;
  String? reason;

  final String? associatedId;
  final String? requestType;

  SoftDeleteRequest.createRequest(
      {this.associatedId, this.requestType, this.reason}) {
    id = Utils.getUuid();
    requestStatus = "REQUESTED";
    timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = HashMap();
    map['associatedId'] = this.associatedId ?? "NA";
    map['requestStatus'] = this.requestStatus ?? "NA";
    map['requestType'] = this.requestType ?? "NA";
    map['id'] = this.id;
    map['reason'] = this.reason;
    map['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    return map;
  }
}

WriteBatch registerSoftDeleteRequestFor({
  required SoftDeleteRequest softDeleteRequest,
  required SoftDelete softDeleteType,
}) {
  WriteBatch batch = CollectionRef.batch;
  var registerRequestRef =
      CollectionRef.softDeleteRequests.doc(softDeleteRequest.id);

  var associatedEntity =
      _getType(softDeleteType).doc(softDeleteRequest.associatedId);
  batch.set(registerRequestRef, softDeleteRequest.toMap());
  batch.update(associatedEntity, {'requestedSoftDelete': true});

  return batch;
}

CollectionReference _getType(SoftDelete softDeleteType) {
  switch (softDeleteType) {
    case SoftDelete.REQUEST_DELETE_TIMEBANK:
    case SoftDelete.REQUEST_DELETE_GROUP:
      return CollectionRef.timebank;

    case SoftDelete.REQUEST_DELETE_PROJECT:
      return CollectionRef.projects;

    case SoftDelete.REQUEST_DELETE_COMMUNITY:
      return CollectionRef.communities;

    default:
      return CollectionRef.timebank;
  }
}

Future<bool> _showAccedentalDeleteConfirmation({
  BuildContext? context,
  SoftDelete? softDeleteType,
}) async {
  bool result = false;
  await showDialog(
    context: context!,
    builder: (BuildContext accedentalDialogContext) {
      return AlertDialog(
        title: Text(
          S.of(context).accidental_delete_enabled,
        ),
        content: Text(
          S.of(context).accidental_delete_enabled_description.replaceAll(
                "**",
                _getModelType(softDeleteType!),
              ),
        ),
        actions: <Widget>[
          CustomElevatedButton(
            color: HexColor("#d2d2d2"),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2.0,
            textColor: Colors.black,
            onPressed: () {
              result = true;
              Navigator.pop(accedentalDialogContext);
            },
            child: Text(
              S.of(context).dismiss,
            ),
          ),
        ],
      );
    },
  );
  return result;
}

Future<bool> _showRequestProcessingWithStatus({BuildContext? context}) async {
  bool result = false;
  await showDialog(
    context: context!,
    builder: (BuildContext _showRequestProcessingWithStatusContext) {
      return AlertDialog(
        title: Text(
          S.of(context).deletion_request_being_processed,
        ),
        content: Text(
          S.of(context).deletion_request_progress_description,
        ),
        actions: <Widget>[
          CustomElevatedButton(
            color: HexColor("#d2d2d2"),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2.0,
            textColor: Colors.black,
            onPressed: () {
              result = true;
              Navigator.pop(_showRequestProcessingWithStatusContext);
            },
            child: Text(
              S.of(context).dismiss,
            ),
          ),
        ],
      );
    },
  );
  return result;
}

BuildContext? buildContextForLinearProgress;

void showLinearProgress({BuildContext? context}) {
  showDialog(
    context: context!,
    builder: (BuildContext context) {
      buildContextForLinearProgress = context;
      return AlertDialog(
        title: Text(
          S.of(context).submitting_request,
        ),
        content: LinearProgressIndicator(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    },
  );
}

String _getContentFromType(
  SoftDelete type,
  BuildContext context,
) {
  switch (type) {
    case SoftDelete.REQUEST_DELETE_GROUP:
      return S.of(context).advisory_for_timebank;
    case SoftDelete.REQUEST_DELETE_PROJECT:
      return S.of(context).advisory_for_projects;
    case SoftDelete.REQUEST_DELETE_TIMEBANK:
      return S.of(context).advisory_for_timebank;
    case SoftDelete.REQUEST_DELETE_COMMUNITY:
      return S.of(context).advisory_for_timebank;
    default:
      return S.of(context).advisory_for_timebank;
  }
}

String _getModelType(SoftDelete type) {
  switch (type) {
    case SoftDelete.REQUEST_DELETE_GROUP:
      return "group";
    case SoftDelete.REQUEST_DELETE_PROJECT:
      return "event";
    case SoftDelete.REQUEST_DELETE_TIMEBANK:
      return "Seva Community";
    case SoftDelete.REQUEST_DELETE_COMMUNITY:
      return "community";
    default:
      return "unknown";
  }
}

Future<bool> showFinalResultConfirmation(
  BuildContext context,
  SoftDelete softDeleteType,
  String associatedId,
  bool didSuceed,
) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          didSuceed
              ? S.of(context).request_submitted
              : S.of(context).request_failed,
        ),
        content: Text(
          didSuceed
              ? getSuccessMessage(softDeleteType, context)
              : S.of(context).request_failure_message,
        ),
        actions: <Widget>[
          CustomElevatedButton(
            color: HexColor("#d2d2d2"),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2.0,
            textColor: Colors.black,
            onPressed: () async {
              await Future.delayed(Duration(milliseconds: 800), () {
                Navigator.pop(context);
//                Navigator.of(context).push(
//                  MaterialPageRoute(
//                    builder: (context) => SevaCore(
//                      loggedInUser: SevaCore.of(context).loggedInUser,
//                      child: HomePageRouter(),
//                    ),
//                  ),
//                );
              });
//              Navigator.pop(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                S.of(context).dismiss,
              ),
            ),
          ),
        ],
      );
    },
  );
  return true;
}

String getSuccessMessage(
  SoftDelete softDeleteType,
  BuildContext context,
) {
  return S
      .of(context)
      .deletion_request_recieved
      .replaceAll('***', _getModelType(softDeleteType));
}

Future<String?> showProfanityImageAlert(
    {required BuildContext context, required String? content}) {
  return showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext _context) {
        return AlertDialog(
          title: Text(S.of(context).profanity_alert),
          content: Text(
            S.of(context).profanity_image_alert + ' ' + (content ?? ''),
          ),
          actions: <Widget>[
            CustomTextButton(
              shape: StadiumBorder(),
              padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
              color: Theme.of(context).colorScheme.secondary,
              textColor: FlavorConfig.values.buttonTextColor,
              child: Text(
                S.of(context).ok,
                style:
                    TextStyle(fontSize: dialogButtonSize, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(_context, 'Proceed');
              },
            ),
          ],
        );
      });
}

Future<void> showFailedLoadImage({
  BuildContext? context,
}) {
  return showDialog(
      barrierDismissible: false,
      context: context!,
      builder: (BuildContext _context) {
        return AlertDialog(
          title: Text(S.of(context).failed_load_image_title),
          content: Text(
            S.of(context).failed_load_image,
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                right: 15,
                bottom: 15,
              ),
              child: CustomTextButton(
                shape: StadiumBorder(),
                padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                color: Theme.of(context).colorScheme.secondary,
                textColor: Colors.white,
                child: Text(
                  S.of(context).ok,
                  style: TextStyle(
                    fontSize: dialogButtonSize,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(_context);
                },
              ),
            ),
          ],
        );
      });
}

Future<ProfanityStatusModel> getProfanityStatus(
    {ProfanityImageModel? profanityImageModel}) async {
  ProfanityStatusModel profanityStatusModel = ProfanityStatusModel();

  if (profanityImageModel!.adult == ProfanityStrings.veryLikely ||
      profanityImageModel.adult == ProfanityStrings.likely) {
    profanityStatusModel.isProfane = true;
    profanityStatusModel.category = ProfanityStrings.adult;
  } else if (profanityImageModel.spoof == ProfanityStrings.veryLikely ||
      profanityImageModel.spoof == ProfanityStrings.likely) {
    profanityStatusModel.isProfane = true;
    profanityStatusModel.category = ProfanityStrings.spoof;
  } else if (profanityImageModel.medical == ProfanityStrings.veryLikely ||
      profanityImageModel.medical == ProfanityStrings.likely) {
    profanityStatusModel.isProfane = true;
    profanityStatusModel.category = ProfanityStrings.medical;
  } else if (profanityImageModel.racy == ProfanityStrings.veryLikely ||
      profanityImageModel.racy == ProfanityStrings.likely) {
    profanityStatusModel.isProfane = true;
    profanityStatusModel.category = ProfanityStrings.racy;
  } else if (profanityImageModel.violence == ProfanityStrings.veryLikely ||
      profanityImageModel.violence == ProfanityStrings.likely) {
    profanityStatusModel.isProfane = true;
    profanityStatusModel.category = ProfanityStrings.violence;
  } else {
    profanityStatusModel.isProfane = false;
  }

  return profanityStatusModel;
}

// Hard delete utility functions for immediate deletion
class HardDeleteUtils {
  /// Delete a request immediately (used for temporary/test data)
  static Future<bool> deleteRequestImmediately(String requestId) async {
    try {
      await CollectionRef.requests.doc(requestId).delete();
      return true;
    } catch (e) {
      logger.e('Failed to delete request immediately: $e');
      return false;
    }
  }

  /// Delete a notification immediately
  static Future<bool> deleteNotificationImmediately(
      String notificationId) async {
    try {
      await CollectionRef.notifications.doc(notificationId).delete();
      return true;
    } catch (e) {
      logger.e('Failed to delete notification immediately: $e');
      return false;
    }
  }

  /// Delete news/feed immediately
  static Future<bool> deleteNewsImmediately(String newsId) async {
    try {
      await CollectionRef.feeds.doc(newsId).delete();
      return true;
    } catch (e) {
      logger.e('Failed to delete news immediately: $e');
      return false;
    }
  }

  /// Delete timebank code immediately
  static Future<bool> deleteTimebankCodeImmediately(String codeId) async {
    try {
      await CollectionRef.timebankCodes.doc(codeId).delete();
      return true;
    } catch (e) {
      logger.e('Failed to delete timebank code immediately: $e');
      return false;
    }
  }

  /// Show a simple confirmation dialog for hard deletion
  static Future<bool> showHardDeleteConfirmation({
    required BuildContext context,
    required String itemType,
    required String itemName,
    required VoidCallback onDelete,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete $itemType'),
              content: Text('Are you sure you want to delete "$itemName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onDelete();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Generic hard delete with progress indicator
  static Future<void> deleteWithProgress({
    required BuildContext context,
    required String itemName,
    required Future<bool> Function() deleteFunction,
    String? successMessage,
    String? errorMessage,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting $itemName...'),
            ],
          ),
        );
      },
    );

    try {
      final success = await deleteFunction();
      Navigator.of(context).pop(); // Hide loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? '$itemName deleted successfully'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to delete $itemName'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Hide loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
