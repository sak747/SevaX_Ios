import 'package:flutter/material.dart';
import 'package:sevaexchange/l10n/l10n.dart';

class CommunityCategoryModel {
  final String id;
  final String logo;
  final Map<String, String> data;

  CommunityCategoryModel(
      {required this.id, required this.logo, required this.data});

  factory CommunityCategoryModel.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final logo = map['logo']?.toString() ?? '';

    // Build a localized data map by taking string entries except reserved keys.
    final Map<String, String> data = {};
    map.forEach((key, value) {
      if (key == 'id' || key == 'logo') return;
      if (value == null) return;
      try {
        data[key] = value.toString();
      } catch (_) {}
    });

    return CommunityCategoryModel(id: id, logo: logo, data: data);
  }

  String getCategoryName(BuildContext context) {
    var key = S.of(context).localeName;
    return data.containsKey(key) ? data[key] ?? '' : data['en'] ?? '';
  }
}
