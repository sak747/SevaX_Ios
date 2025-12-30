import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/community_category_model.dart';
import 'package:sevaexchange/repositories/community_repository.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';
import 'package:sevaexchange/widgets/custom_chip.dart';

class CommunityCategorySelector extends StatefulWidget {
  final List<String>? selectedCategories;
  final ValueChanged<List<CommunityCategoryModel>>? onChanged;

  const CommunityCategorySelector({
    Key? key,
    this.onChanged,
    this.selectedCategories,
  }) : super(key: key);
  @override
  _CommunityCategorySelectorState createState() =>
      _CommunityCategorySelectorState();
}

class _CommunityCategorySelectorState extends State<CommunityCategorySelector> {
  Map<String, CommunityCategoryModel> selectedCateories = {};
  final TextEditingController _textEditingController = TextEditingController();
  TextEditingController? _activeController;
  late final Future<List<CommunityCategoryModel>> future;
  bool isDataLoaded = false;
  @override
  void initState() {
    future = CommunityRepository.getCommunityCategories();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<List<CommunityCategoryModel>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingIndicator();
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(S.of(context).error_occured),
              );
            }

            final all = snapshot.data ?? <CommunityCategoryModel>[];

            if (!isDataLoaded) {
              if (widget.selectedCategories?.isNotEmpty ?? false) {
                for (final element in widget.selectedCategories!) {
                  try {
                    final found = all.firstWhere((e) => element == e.id);
                    selectedCateories[element] = found;
                  } catch (e) {
                    // ignore if not found
                  }
                }
              }
              isDataLoaded = true;
            }

            return TypeAheadField<CommunityCategoryModel>(
              builder: (context, controllerParam, focusNode) {
                _activeController = controllerParam;
                return TextField(
                  controller: _textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: S.of(context).search,
                    filled: true,
                    fillColor: Colors.grey[300],
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(25.7),
                    ),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(25.7)),
                    contentPadding: EdgeInsets.fromLTRB(10.0, 12.0, 10.0, 5.0),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    suffixIcon: InkWell(
                      splashColor: Colors.transparent,
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        _textEditingController.clear();
                      },
                    ),
                  ),
                );
              },
              onSelected: (suggestion) {
                selectedCateories[suggestion.id] = suggestion;
                _textEditingController.clear();
                widget.onChanged?.call(selectedCateories.values.toList());
                setState(() {});
              },
              errorBuilder: (context, err) {
                return Text(S.of(context).error_occured);
              },
              suggestionsCallback: (String pattern) async {
                if (pattern.trim().isEmpty) return <CommunityCategoryModel>[];
                var dataCopy = all
                    .where((s) =>
                        s
                            .getCategoryName(context)
                            .toLowerCase()
                            .contains(pattern.toLowerCase()) &&
                        !selectedCateories.containsKey(s.id))
                    .toList();
                return dataCopy;
              },
              itemBuilder: (BuildContext context, itemData) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    itemData.getCategoryName(context),
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            );
          },
        ),
        SizedBox(height: 4),
        Wrap(
          runSpacing: 4,
          spacing: 4,
          children: selectedCateories.values
              .map(
                (data) => CustomChip(
                  title: data.getCategoryName(context),
                  onDelete: () {
                    setState(() {
                      selectedCateories.remove(data.id);
                      widget.onChanged?.call(selectedCateories.values.toList());
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
