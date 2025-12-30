import 'package:flutter/material.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/labels.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sevaexchange/ui/screens/explore/pages/community_by_category_view.dart';
import 'package:sevaexchange/utils/data_managers/blocs/communitylist_bloc.dart';
import 'package:sevaexchange/models/community_category_model.dart';
import 'package:sevaexchange/views/community/communitycreate.dart';
import 'package:sevaexchange/views/login/login_page.dart';
import 'package:sevaexchange/views/login/register_page.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';
import 'package:sevaexchange/widgets/hide_widget.dart';

class ExplorePageAppBar extends PreferredSize {
  final ValueChanged<String>? onSearchChanged;
  final bool hideSearchBar;
  final TextEditingController? controller;

  ExplorePageAppBar(
      {this.controller, this.hideSearchBar = false, this.onSearchChanged})
      : super(
          child: Container(),
          preferredSize: Size.fromHeight(210),
        );

  @override
  Size get preferredSize => Size.fromHeight(210);

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      height: isMobile ? 120 : 200,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('images/waves.png'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isMobile ? MediaQuery.of(context).padding.top + 5 : 10,
          left: isMobile ? 16.0 : 0.0,
          right: isMobile ? 16.0 : 0.0,
          bottom: 10,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 5 : 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).maybePop();
                      },
                      child: Image.asset(
                        'images/seva-x-logo-white.png',
                        width: isMobile ? 80 : 150,
                        height: isMobile ? 50 : 60,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Flexible(
                  child: isMobile
                      ? Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isMobile ? 5 : 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _mobileTextButton(
                                  S.of(context).register,
                                  () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RegisterPage(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _mobileTextButton(
                                  S.of(context).log_in,
                                  () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 64,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              appBarButton(
                                "Create a new Seva community",
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommunityByCategoryView(
                                              model: CommunityCategoryModel(
                                                  id: '', logo: '', data: {}),
                                              isUserSignedIn: false),
                                    ),
                                  );
                                },
                              ),
                              appBarButton(
                                "Help",
                                () async {
                                  final Uri url = Uri(
                                    scheme: 'https',
                                    host: 'stg.sevaxapp.com/',
                                  );
                                  if (!await launchUrl(url)) {
                                    throw Exception('Could not launch $url');
                                  }
                                },
                              ),
                              appBarButton(
                                S.of(context).register,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RegisterPage(),
                                    ),
                                  );
                                },
                              ),
                              appBarButton(
                                S.of(context).log_in,
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            HideWidget(
              hide: hideSearchBar,
              secondChild: const SizedBox(),
              child: Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: isMobile ? 50 : 40,
                    child: TextField(
                      controller: controller,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: S.of(context).try_oska_postal_code,
                        hintStyle: TextStyle(
                            color: Colors.grey, fontSize: isMobile ? 14 : 12),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: CustomTextButton(
                          child: Text(S.of(context).search),
                          textColor: Colors.white,
                          color: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () {},
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 8.0 : 4.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomTextButton appBarButton(String text, VoidCallback onTap) {
    return CustomTextButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 64,
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      textColor: Colors.white,
      onPressed: onTap,
    );
  }

  TextButton _mobileTextButton(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
