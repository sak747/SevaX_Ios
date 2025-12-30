import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sevaexchange/l10n/l10n.dart';

class Regex {
  static RegExp numericRegex = RegExp(r"^[0-9]+$");
  static RegExp emailAndPhoneRegex = RegExp(r"^(?:\d{7,15}|\w+@\w+\.\w{2,3})$");
}

class Validators {
  var titleValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (title, sink) {
      if (title != null && title.length > 0) {
        sink.add(title);
      } else {
        sink.addError('Please enter the subject of your offer');
      }
    },
  );
  var preperationValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (title, sink) {
      if (title != null) {
        sink.add(title);
      } else {
        sink.addError('Please enter your preperation time');
      }
    },
  );
  var classHoursValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (title, sink) {
      if (title != null) {
        sink.add(title);
      } else {
        sink.addError('Please enter the hours required for the class');
      }
    },
  );

  var genericValidator = StreamTransformer<String, String>.fromHandlers(
    handleData: (text, sink) {
      if (text != null && text.length > 0) {
        sink.add(text);
      } else {
        sink.addError('Please enter some text');
      }
    },
  );
}

//keys for localisation
class ValidationErrors {
  static const String titleError = 'title_error';
  static const String char_error = '_error';
  static const String genericError = 'generic_error';
  static const String classHours = 'class_hours';
  static const String hoursNotInt = 'hours_not_int';
  static const String preprationTimeError = 'prepration_time_error';
  static const String locationError = 'location_error';
  static const String sizeOfClassIsNotInt = "size_of_class_not_int";
  static const String sizeOfClassError = "size_of_class_error";
  static const String offerCreditError = "offer_credit_error";
  static const String profanityError = "profanity_error";
  static const String emptyErrorCash = "add_amount_donate_empty";
  static const String emptyErrorGoods = "add_goods_donate_empty";
  static const String minimumCreditsError = "minimum_credits_empty";

  // static const String titleError = 'Please enter the subject of your offer';
}

String getValidationErrorNew(BuildContext context, String errorCode) {
  if (errorCode.isEmpty) return '';
  S error = S.of(context);
  switch (errorCode) {
    case ValidationErrors.titleError:
      return error.validation_error_offer_title;
    case ValidationErrors.char_error:
      return 'Creating offer with "_" is not allowed';
    case ValidationErrors.genericError:
      return error.validation_error_general_text;
    case ValidationErrors.classHours:
      return error.validation_error_offer_class_hours;
    case ValidationErrors.hoursNotInt:
      return error.validation_error_hours_not_int;
    case ValidationErrors.preprationTimeError:
      return error.validation_error_offer_prep_hour;
    case ValidationErrors.locationError:
      return error.validation_error_location;
    case ValidationErrors.sizeOfClassIsNotInt:
      return error.validation_error_class_size_int;
    case ValidationErrors.sizeOfClassError:
      return error.validation_error_class_size;
    case ValidationErrors.offerCreditError:
      return error.validation_error_offer_credit;
    case ValidationErrors.profanityError:
      return error.profanity_text_alert;
    case ValidationErrors.emptyErrorCash:
      return error.add_amount_donate_empty;
    case ValidationErrors.emptyErrorGoods:
      return error.add_goods_donate_empty;
    case ValidationErrors.minimumCreditsError:
      return error.min_credits_error;
    default:
      return '';
  }
}
