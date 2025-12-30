import 'package:flutter/material.dart';

class IntroGalleryPage extends StatefulWidget {
  const IntroGalleryPage({Key? key}) : super(key: key);

  @override
  _IntroGalleryPageState createState() => _IntroGalleryPageState();
}

class _IntroGalleryPageState extends State<IntroGalleryPage> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<String> _images = [
    'images/intro_screens/What_is_a_timebank_and_how_can_people_find_and_join_one.png',
    'images/intro_screens/Requests_and_Offers.png',
    'images/intro_screens/Messaging_and_communication.png',
    'images/intro_screens/Groups_and_Projects.png',
    'images/intro_screens/Broadcasting_feeds.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Intro'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Image.asset(
                      _images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _images.length,
              (i) => AnimatedContainer(
                duration: Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _current == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _current == i
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
