// 🔧 COMPREHENSIVE TYPE SAFETY PATCH
// This file contains fixes for ALL sources of JSArray<String?> type casting errors

import 'package:cloud_firestore/cloud_firestore.dart';

// Utility function to safely create List<String> from potentially nullable values
List<String> safeStringList(List<dynamic>? input) {
  if (input == null) return <String>[];

  return input
      .map((e) => e?.toString())
      .where((e) => e != null && e.isNotEmpty)
      .cast<String>()
      .toList();
}

// Utility function to safely create List<String> from single nullable string
List<String> safeSingleStringList(String? value) {
  if (value == null || value.isEmpty) return <String>[];
  return <String>[value];
}

// Utility function to safely create List<String> from list of nullable strings
List<String> safeNullableStringList(List<String?>? values) {
  if (values == null) return <String>[];

  return values.where((e) => e != null && e.isNotEmpty).cast<String>().toList();
}

// PATCH 1: Safe array union for Firestore operations
extension SafeFieldValue on FieldValue {
  static FieldValue arrayUnionSafe(List<String> values) {
    return FieldValue.arrayUnion(values);
  }

  static FieldValue arrayRemoveSafe(List<String> values) {
    return FieldValue.arrayRemove(values);
  }
}

// PATCH 2: Safe list creation for user IDs
List<String> createUserIdList(String? userId, {List<String>? additionalIds}) {
  List<String> result = [];

  if (userId != null && userId.isNotEmpty) {
    result.add(userId);
  }

  if (additionalIds != null) {
    result.addAll(additionalIds.where((id) => id.isNotEmpty));
  }

  return result;
}

// PATCH 3: Safe list assignment for model properties
void safeAssignList(List<String> target, List<dynamic>? source) {
  if (source == null) {
    target.clear();
    return;
  }

  target.clear();
  target.addAll(safeStringList(source));
}

// PATCH 4: Check for potential type casting issues in JSON deserialization
List<String> safeFromJson(dynamic jsonValue) {
  if (jsonValue == null) return <String>[];

  if (jsonValue is List) {
    return jsonValue
        .map((e) => e?.toString())
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();
  }

  if (jsonValue is String) {
    return jsonValue.isEmpty ? <String>[] : <String>[jsonValue];
  }

  return <String>[];
}
