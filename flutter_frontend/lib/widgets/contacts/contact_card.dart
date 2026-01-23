import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/contact_model.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class ContactCard extends StatefulWidget {
  final ContactModel contact;

  const ContactCard({super.key, required this.contact});

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _updateImageProvider();
  }

  @override
  void didUpdateWidget(ContactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the image provider if the image data actually changed
    if (oldWidget.contact.image128 != widget.contact.image128) {
      _updateImageProvider();
    }
  }

  void _updateImageProvider() {
    if (widget.contact.image128 != null) {
      _imageProvider = MemoryImage(base64Decode(widget.contact.image128!));
    } else {
      _imageProvider = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Determine icon based on isCompany
    final icon = widget.contact.isCompany ? Icons.business : Icons.person;
    print('rebuilding contacts_card');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.push('/contacts/${widget.contact.id}');
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
                  decoration: BoxDecoration(
                    color: palette.extras[4],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background image if available
                      //Visit Site and Designation
                      Padding(
                        padding: const EdgeInsets.all(8.0).copyWith(left: 15, right: 15),
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Text(
                                (widget.contact.isCompany ? 'Company' : 'Person'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: palette.extras[1],
                                letterSpacing: -0.2,
                                fontFamily: 'Lexend',
                                ),
                            ),
                            SizedBox(width: 20,),
                            if(!widget.contact.isCompany)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                        widget.contact.function ?? 'Unknown',
                                        maxLines: 1,
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: palette.extras[2],
                                        letterSpacing: -0.2,
                                        fontFamily: 'Lexend',
                                        ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ],
                        ),
                      ),
                      Positioned(
                        bottom:0,
                        width: constraints.maxWidth,
                        child: InnerShadow(
                          shadows: [
                            Shadow(
                              color: palette.black.withOpacity(0.08),
                              offset: const Offset(-3, -3),
                              blurRadius: 0,
                            ),
                            Shadow(
                              color: palette.white.withOpacity(0.3),
                              offset: const Offset(3, 3),
                              blurRadius: 0,
                            ),
                            ],
                          child: Container(
                            height: constraints.maxHeight/1.2,
                            margin: EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: palette.extras[3],
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 3,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 15,),
                                Row(
                                  children: [
                                    SizedBox(width: 15,),
                                    SizedBox(
                                      width: 60,
                                      child: Stack(
                                        children: [
                                          Container(
                                            height:  60,
                                            width:  60,
                                            alignment: Alignment(0,0.5),
                                            margin: EdgeInsets.only(top:25),
                                            decoration: BoxDecoration(
                                              color: palette.extras[2],
                                              shape: BoxShape.circle,
                                              
                                            ),
                                          ),
                                          Container(
                                            height:60,
                                            width:60,
                                            decoration: BoxDecoration(
                                              color: palette.extras[1],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: palette.extras[1], width: 2),
                                              image: _imageProvider != null ? DecorationImage(
                                                image: _imageProvider!,
                                                fit: BoxFit.cover,
                                              ) : null,
                                            ),
                                            child: _imageProvider == null ? Center(
                                              child: Icon(icon, color: palette.extras[0], ),
                                            ) : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10,),
                                    SizedBox(
                                      width: (constraints.maxWidth-95-50).clamp(5, constraints.maxWidth),
                                      height: 80,
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            (widget.contact.name ?? 'Supreme Leader Aladeen').replaceAll(' ', '\n'),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w500,
                                              color: palette.extras[1],
                                              letterSpacing: -1,
                                              fontFamily: 'Lexend',
                                              height: 0.85,
                                            ),
                                          ),
                                          if(widget.contact.companyName != null && widget.contact.companyName!.isNotEmpty)
                                          Text(
                                            widget.contact.companyName! ,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: palette.extras[2],
                                              letterSpacing: -0.8,
                                              fontFamily: 'Lexend',
                                              height: 0.85,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 20,),
                                  ],
                                ),
                                Expanded(child: SizedBox(height: 5,)),
                                //EMAIL AND PHONE AND LOCATION
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      //EMAIL AND MAP PIN
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                tabler.MailFilled(
                                                  color: palette.extras[1],
                                                  width: 25,
                                                  height: 25,
                                                  ),
                                                SizedBox(width: 5,),
                                                Expanded(
                                                  child: Text(
                                                    (widget.contact.email ?? 'Unknown'),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w300,
                                                      color: palette.extras[1],
                                                      letterSpacing: -0.2,
                                                      fontFamily: 'Lexend',
                                                      height: 0.85,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          tabler.MapPinFilled(
                                            color: palette.extras[1],
                                            width: 60,
                                            height: 60,
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: 10,),
                                      //PHONE AND LOCATION
                                      Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                          Row(
                                          children: [
                                              SvgPicture.asset(
                                                'assets/icons/phone.svg',
                                                colorFilter: ColorFilter.mode(
                                                  palette.extras[1],
                                                  BlendMode.srcIn,
                                                ),
                                                width: 25,
                                                height: 25,
                                              ),
                                              SizedBox(width: 5,),
                                              Text(
                                                (widget.contact.phone ?? 'Unknown'),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w300,
                                                  color: palette.extras[1],
                                                  letterSpacing: -0.2,
                                                  fontFamily: 'Lexend',
                                                  height: 0.85,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 15,),
                                          Expanded(
                                            child: Text(
                                              (widget.contact.city ?? 'Unknown')+', '+ (widget.contact.countryId?.name ?? '??'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w300,
                                                color: palette.extras[2],
                                                letterSpacing: -0.2,
                                                fontFamily: 'Lexend',
                                                height: 0.85,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            );
          }
        ),
      ),
    );
            

  }
}
