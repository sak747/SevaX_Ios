import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:sevaexchange/components/calendar_events/models/calendar_response.dart';
import 'package:sevaexchange/components/calendar_events/models/kloudless_models.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';
import 'package:http/http.dart' as http;
import 'package:sevaexchange/components/calendar_events/apple_client.dart';

class CalendarAPIRepo {
  static Future<String> createEventInCalendar({
    required KloudlessCalendarEvent event,
    int? calendarAccountId,
    required String calendarId,
    String? calendarAccessToken,
    String? caledarScope,
  }) async {
    //EVENT META DATA
    try {
      // Google Calendar
      if (caledarScope == 'google_calendar') {
        final url =
            'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events';
        final body = {
          'summary': event.eventTitle,
          'description': event.eventDescription,
          'location': event.eventLocation,
          'start': {'dateTime': event.eventStart},
          'end': {'dateTime': event.eventEnd},
        };
        final response =
            await http.post(Uri.parse(url), body: jsonEncode(body), headers: {
          'Authorization': 'Bearer ${calendarAccessToken ?? ''}',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
        logger.d('Google Calendar create: $url -> ${response.body}');
        final map = json.decode(response.body);
        if (map is Map && map.containsKey('id')) return map['id'];
        return Future.error('Could not find id in Google response');
      }

      // Outlook / Microsoft Graph
      if (caledarScope == 'outlook_calendar') {
        final url =
            'https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events';
        final body = {
          'subject': event.eventTitle,
          'body': {
            'contentType': 'HTML',
            'content': event.eventDescription ?? ''
          },
          'start': {'dateTime': event.eventStart, 'timeZone': 'UTC'},
          'end': {'dateTime': event.eventEnd, 'timeZone': 'UTC'},
          'location': {'displayName': event.eventLocation ?? ''},
        };
        final response =
            await http.post(Uri.parse(url), body: jsonEncode(body), headers: {
          'Authorization': 'Bearer ${calendarAccessToken ?? ''}',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
        logger.d('Outlook create: $url -> ${response.body}');
        final map = json.decode(response.body);
        if (map is Map && map.containsKey('id')) return map['id'];
        return Future.error('Could not find id in Outlook response');
      }

      // iCloud / device calendar (use EventKit via device_calendar plugin)
      if (caledarScope == 'icloud_calendar') {
        final appleClient = AppleCalendarClient();
        return await appleClient.createEvent(
            event: event, calendarId: calendarId);
      }

      // Fallback: Kloudless
      final accId = calendarAccountId ?? 0;
      String url =
          "https://api.kloudless.com/v1/accounts/${accId.toString()}/cal/calendars/$calendarId/events";
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(event.toMap()),
        headers: {
          'Authorization':
              'Bearer ${calendarAccessToken ?? 'E0BgzLSL6p1tTEkDhsoERLS5eV7IQu'}',
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
      );
      logger.d(url + " VALUE FROM SERVER  " + response.body);
      Map<String, dynamic> map = json.decode(response.body);
      if (map.containsKey('id'))
        return map['id'];
      else
        return Future.error("Could not find id in response!");
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  static Future<CalendarEventDetailsResponse> getEventDetailsFromId({
    int? calendarAccountId,
    required String calendarId,
    required String eventId,
    String? calendarAccessToken,
    String? caledarScope,
  }) async {
    try {
      // Google
      if (caledarScope == 'google_calendar') {
        final url =
            'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events/$eventId';
        final response = await http.get(Uri.parse(url), headers: {
          'Authorization': 'Bearer ${calendarAccessToken ?? ''}',
          'Accept': 'application/json'
        });
        if (response.statusCode == 200) {
          return CalendarEventDetailsResponse.fromJson(
              json.decode(response.body));
        }
        throw "Couldn't parse Google event model!";
      }

      // Outlook
      if (caledarScope == 'outlook_calendar') {
        final url =
            'https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events/$eventId';
        final response = await http.get(Uri.parse(url), headers: {
          'Authorization': 'Bearer ${calendarAccessToken ?? ''}',
          'Accept': 'application/json'
        });
        if (response.statusCode == 200) {
          return CalendarEventDetailsResponse.fromJson(
              json.decode(response.body));
        }
        throw "Couldn't parse Outlook event model!";
      }

      // Kloudless fallback
      final url =
          "https://api.kloudless.com/v1/accounts/${calendarAccountId.toString()}/cal/calendars/$calendarId/events/$eventId";
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization':
            'Bearer ${calendarAccessToken ?? 'E0BgzLSL6p1tTEkDhsoERLS5eV7IQu'}',
        "Accept": "application/json",
      });
      if (response.statusCode == 200) {
        return CalendarEventDetailsResponse.fromJson(
            json.decode(response.body));
      }
      throw "Couldn't parse the model!";
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<bool> updateCalendarEventWithAttendies({
    List<Attendee>? previousAttendies,
    EventMetaData? eventMetaData,
    AttendeDetails? attendeDetails,
    KloudlessCalendarEvent? event,
  }) async {
    //
    try {
      // Build attendees list
      List<Attendee> updatedAttendies = [];
      if (attendeDetails?.attendee != null) {
        updatedAttendies.add(attendeDetails!.attendee!);
      }
      previousAttendies?.forEach((element) {
        updatedAttendies.add(element);
      });

      // Google
      if (eventMetaData?.calendar?.caledarScope == 'google_calendar') {
        final url =
            'https://www.googleapis.com/calendar/v3/calendars/${eventMetaData!.calendar!.calendarId}/events/${eventMetaData.eventId}';
        final body = {
          'attendees': updatedAttendies.map((e) => e.toJson()).toList(),
        };
        final response =
            await http.patch(Uri.parse(url), body: json.encode(body), headers: {
          'Authorization':
              'Bearer ${attendeDetails?.calendar?.calendarAccessToken ?? ''}',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
        logger.d('Google update attendees: ${response.statusCode}');
        return response.statusCode >= 200 && response.statusCode < 300;
      }

      // Outlook
      if (eventMetaData?.calendar?.caledarScope == 'outlook_calendar') {
        final url =
            'https://graph.microsoft.com/v1.0/me/calendars/${eventMetaData!.calendar!.calendarId}/events/${eventMetaData.eventId}';
        final body = {
          'attendees': updatedAttendies
              .map((e) => {
                    'emailAddress': {
                      'address': e.email ?? '',
                      'name': e.name ?? ''
                    },
                    'type': 'required'
                  })
              .toList()
        };
        final response =
            await http.patch(Uri.parse(url), body: json.encode(body), headers: {
          'Authorization':
              'Bearer ${attendeDetails?.calendar?.calendarAccessToken ?? ''}',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
        logger.d('Outlook update attendees: ${response.statusCode}');
        return response.statusCode >= 200 && response.statusCode < 300;
      }

      // Kloudless fallback
      String url =
          "https://api.kloudless.com/v1/accounts/${eventMetaData!.calendar!.calendarAccId}/cal/calendars/${eventMetaData.calendar!.calendarId}/events/${eventMetaData.eventId}";

      var map = updatedAttendies.map((e) => e.toJson()).toList();

      Map<String, dynamic> body = {
        "attendees": map,
      };

      final response = await http.patch(
        Uri.parse(url),
        body: json.encode(body),
        headers: {
          'Authorization':
              'Bearer ${attendeDetails?.calendar?.calendarAccessToken ?? 'E0BgzLSL6p1tTEkDhsoERLS5eV7IQu'}',
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  static Future<bool> updateAttendiesInCalendarEvent({
    AttendeDetails? attendeDetails,
    EventMetaData? eventMetaData,
    KloudlessCalendarEvent? event,
  }) async {
    //Event doesn't have an associated link

    if (eventMetaData != null &&
        eventMetaData.eventId != null &&
        !(eventMetaData.eventId?.isEmpty ?? true) &&
        eventMetaData.calendar?.caledarScope ==
            attendeDetails?.calendar?.caledarScope) {
      // Get current event and update
      return await getEventDetailsFromId(
        calendarAccountId: eventMetaData.calendar!.calendarAccId,
        calendarId: eventMetaData.calendar!.calendarId!,
        eventId: eventMetaData.eventId!,
        calendarAccessToken: attendeDetails?.calendar?.calendarAccessToken,
        caledarScope: attendeDetails?.calendar?.caledarScope,
      )
          .then(
        (value) => updateCalendarEventWithAttendies(
          eventMetaData: eventMetaData,
          attendeDetails: attendeDetails,
          event: event,
          previousAttendies: value.attendees,
        ),
      )
          .then((value) {
        return true;
      }).catchError((onError) {
        logger.i("Failed Updation due to " + onError);
        return false;
      });
    } else {
      if (attendeDetails?.calendar?.calendarAccId == null &&
          attendeDetails?.calendar?.caledarScope == 'kloudless') {
        throw 'Calendar account ID cannot be null';
      }
      if (event == null) {
        throw 'Event cannot be null';
      }
      return await createEventInCalendar(
        calendarAccountId: attendeDetails?.calendar?.calendarAccId,
        calendarId: attendeDetails!.calendar!.calendarId!,
        calendarAccessToken: attendeDetails.calendar!.calendarAccessToken,
        caledarScope: attendeDetails.calendar!.caledarScope,
        event: event,
      ).then((value) => value != null);
    }
  }
}
