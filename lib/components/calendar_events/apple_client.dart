import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:sevaexchange/components/calendar_events/models/kloudless_models.dart';

class AppleCalendarClient {
  /// Create an event in the user's calendar using `add_2_calendar`.
  /// Note: `add_2_calendar` opens the platform calendar add UI and does not
  /// return a platform event id. To keep the repo API stable we return a
  /// generated id string on success.
  Future<String> createEvent({
    required KloudlessCalendarEvent event,
    String? calendarId,
  }) async {
    try {
      final start =
          event.eventStart != null ? DateTime.parse(event.eventStart!) : null;
      final end =
          event.eventEnd != null ? DateTime.parse(event.eventEnd!) : null;

      final addEvent = Event(
        title: event.eventTitle ?? '',
        description: event.eventDescription,
        location: event.eventLocation,
        startDate: start ?? DateTime.now(),
        endDate: end ?? (start ?? DateTime.now()).add(Duration(hours: 1)),
      );

      await Add2Calendar.addEvent2Cal(addEvent);

      // `add_2_calendar` does not provide an event id; return a generated id.
      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      throw 'Failed to create event in device calendar: $e';
    }
  }
}
