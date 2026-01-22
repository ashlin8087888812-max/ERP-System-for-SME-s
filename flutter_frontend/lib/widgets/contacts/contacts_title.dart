import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/utils/branches.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';

class ContactsTitle extends StatelessWidget {
  final double scale;
  const ContactsTitle({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "Contacts",
              style: TextStyle(
                fontFamily: "Lexend",
                fontSize: 120,
                fontWeight: FontWeight.w600,
                color: palette.black,
                letterSpacing: -6,
              ),
            ),
          ),
        ),
        SizedBox(width: 40),
        Transform.scale(
          scale: scale,
          child: DecoratedIcon(
            iconSvg: contacts.iconSvg, 
            offset: contacts.offset, 
            overlaySvg: contacts.overlaySvg, 
            iconSize: 50, 
            showOverlay: contacts.showOverlay,
            overlaySize: contacts.overlaySize),
        )
      ],
    );
  }
}