import 'package:flutter/material.dart';
import 'package:sevaexchange/views/profile/intro_gallery.dart';
import 'package:sevaexchange/views/community/webview_seva.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      'Intro',
      'About SevaX',
      // Intentionally omitting 'About us' as requested by the user
      'Training Video',
      'Contact Us',
      'Glossary',
      'FAQ',
    ];

    final Color appBarColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      title: Text(
                        items[index],
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Wire Intro and About SevaX to existing screens
                        final title = items[index];
                        if (title == 'Intro') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => IntroGalleryPage(),
                            ),
                          );
                        } else if (title == 'About SevaX') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SevaWebView(
                                AboutMode(
                                    title: 'About SevaX',
                                    urlToHit:
                                        'https://www.sevaxapp.com/about/'),
                              ),
                            ),
                          );
                        } else if (title == 'Training Video') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SevaWebView(
                                AboutMode(
                                  title: 'Training Video',
                                  urlToHit: 'https://stg.sevaxapp.com/',
                                ),
                              ),
                            ),
                          );
                        } else if (title == 'Glossary') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SevaWebView(
                                AboutMode(
                                  title: 'Glossary',
                                  urlToHit: 'https://www.sevaxapp.com/404',
                                ),
                              ),
                            ),
                          );
                        } else if (title == 'FAQ') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SevaWebView(
                                AboutMode(
                                  title: 'FAQ',
                                  urlToHit: 'https://www.sevaxapp.com/404',
                                ),
                              ),
                            ),
                          );
                        } else if (title == 'Contact Us') {
                          // Show centered dialog with email and actions
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding:
                                    EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 48,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'info@sevaexchange.com',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap "Email Us" to open your default email app.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                actionsPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                actions: <Widget>[
                                  Container(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              shape: StadiumBorder(),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                            ),
                                            onPressed: () async {
                                              final Uri emailLaunchUri = Uri(
                                                scheme: 'mailto',
                                                path: 'info@sevaexchange.com',
                                                queryParameters: {
                                                  'subject': 'SevaX Support',
                                                  'body': 'Hi SevaX team,\n\n'
                                                },
                                              );

                                              Navigator.of(dialogContext).pop();

                                              try {
                                                await launchUrl(
                                                  emailLaunchUri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'No email client available'),
                                                ));
                                              }
                                            },
                                            child: Text(
                                              'Email Us',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        SizedBox(
                                          width: 110,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              shape: StadiumBorder(),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                            ),
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                            },
                                            child: Text(
                                              'Dismiss',
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          // Other items not implemented yet
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Version label centered at the bottom, matching screenshot
            Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Center(
                child: Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
