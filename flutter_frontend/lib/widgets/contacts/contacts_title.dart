import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/utils/branches.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';

class ContactsTitle extends StatelessWidget {
  const ContactsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Contacts",
            style: TextStyle(
              fontFamily: "Lexend",
              fontSize: 70,
              fontWeight: FontWeight.w600,
              color: palette.black,
              letterSpacing: -6,
            ),
          ),
        ),
        DecoratedIcon(
          iconSvg: contacts.iconSvg, 
          offset: contacts.offset, 
          overlaySvg: contacts.overlaySvg, 
          iconSize: 70, 
          showOverlay: contacts.showOverlay,
          overlaySize: contacts.overlaySize)
      ],
    );
  }
}