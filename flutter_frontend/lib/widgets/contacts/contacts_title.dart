import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/utils/branches.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';

class ContactsTitle extends StatelessWidget {
  const ContactsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
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
        Transform.scale(
          scale: 2,
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