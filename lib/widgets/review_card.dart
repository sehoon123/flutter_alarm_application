import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewCard extends StatelessWidget {
  final String reviewUrl = 'https://yourwebsite.com/reviews';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchURL(reviewUrl);
      },
      child: Card(
        margin: EdgeInsets.all(16.0),
        color: Colors.grey[800],
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '당첨 후기',
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Could not launch the URL
    }
  }
}
