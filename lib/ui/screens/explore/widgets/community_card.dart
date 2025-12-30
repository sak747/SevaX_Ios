import 'package:flutter/material.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    Key? key,
    required this.name,
    required this.memberCount,
    required this.imageUrl,
    required this.buttonLabel,
    required this.buttonColor,
    required this.textColor,
    required this.onbuttonPress,
    required this.memberIds,
  }) : super(key: key);

  final String name;
  final String memberCount;
  final String imageUrl;
  final String buttonLabel;
  final Color buttonColor;
  final Color textColor;
  final VoidCallback onbuttonPress;
  final List<String> memberIds;

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    // Responsive font sizes
    double nameFontSize = screenWidth < 600 ? 14 : 16;
    double memberFontSize = screenWidth < 600 ? 10 : 12;
    double buttonFontSize = screenWidth < 600 ? 12 : 14;
    // Responsive image size
    double imageSize = screenWidth < 600 ? 60 : 80;
    // Responsive button width
    double buttonWidth = screenWidth < 600 ? 90 : 110;
    // Responsive padding
    double padding = screenWidth < 600 ? 8.0 : 12.0;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Community Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: imageSize,
                width: imageSize,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: imageSize,
                    width: imageSize,
                    color: Colors.grey[300],
                    child: Icon(Icons.error_outline, color: Colors.grey[600]),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: imageSize,
                    width: imageSize,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),

            const SizedBox(width: 16),

            // Community Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$memberCount ${S.of(context).members}',
                    style: TextStyle(
                      fontSize: memberFontSize,
                      color: Colors.grey[700],
                    ),
                  ),
                  // Member images could be added here if needed
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action Button
            SizedBox(
              width: buttonWidth,
              child: CustomElevatedButton(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                onPressed: onbuttonPress,
                color: buttonColor,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
