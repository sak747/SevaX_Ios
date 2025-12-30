import 'package:flutter/material.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/community_category_model.dart';
import 'package:sevaexchange/repositories/community_repository.dart';
import 'package:sevaexchange/ui/screens/explore/widgets/explore_browse_card.dart';
import 'package:sevaexchange/views/timebanks/widgets/loading_indicator.dart';

class CommunityBrowseCategories extends StatelessWidget {
  final ValueChanged<CommunityCategoryModel>? onTap;

  const CommunityBrowseCategories({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a stream from future so builder usage matches RequestCategories
    final stream = Stream.fromFuture(CommunityRepository.getCommunityCategories());

    return StreamBuilder<List<CommunityCategoryModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingIndicator();
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text(S.of(context).no_categories_available));
        }

        return GridView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 1,
            crossAxisSpacing: 0.5,
            childAspectRatio: 6,
          ),
          children: List.generate(
            snapshot.data!.length,
            (index) => ExploreBrowseCard(
              imageUrl: snapshot.data![index].logo ?? '',
              title: snapshot.data![index].getCategoryName(context),
              onTap: () => onTap?.call(snapshot.data![index]),
            ),
          ),
        );
      },
    );
  }
}
