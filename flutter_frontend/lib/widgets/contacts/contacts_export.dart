import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class ContactExport extends StatelessWidget {
  const ContactExport({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.extras[0],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            " Export Contacts",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.extras[1],
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lexend',
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
      
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: tabler.Upload(
                  width: 90,
                  height: 90,
                  strokeWidth: 2.5,
                  color: palette.extras[2],
                ),
              ),
            ),
          ),
      
          const Spacer(),
      
          Center(
            child: Container(
              height: 50,
              width: 180,
              decoration: BoxDecoration(
                color: palette.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                ".xlsx",
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.extras[1],
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactExportMini extends StatelessWidget {
  const ContactExportMini({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: palette.extras[0],
        child: InkWell(
          onTap: () => context.go('/contacts/new'),
          hoverColor: palette.black.withOpacity(0.1),
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8, top: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    " Export\n Contacts",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.extras[1],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lexend',
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                tabler.Upload(
                  width: 40,
                  height: 40,
                  strokeWidth: 2.5,
                  color: palette.extras[1],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
