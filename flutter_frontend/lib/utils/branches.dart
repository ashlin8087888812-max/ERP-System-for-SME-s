import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

Branch get contacts => Branch(
  name: 'contacts',
  url: '/contacts',
  category: 'Sales',
  icon: tabler.User(),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8E6F5), Color(0xFF7EC8E3)],
  ),
  hasImage: true,
  imageUrl: 'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400',
  iconSvg: contacts_2,
  overlaySvg: user_1,
  iconSize: 50,
  overlaySize: 18,
  offset: const Offset(15,14),
  showOverlay: false,
  color: const Color(0xFFD7F0FF),
);

Branch get threads => Branch(
  name: 'threads',
  url: '/threads',
  category: 'All',
  icon: tabler.Menu2(),
  color: const Color(0xFFFFFAD7),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8D5C4), Color(0xFFD4BFA8)],
  ),
  hasImage: true,
  imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
  iconSvg: message_1,
  overlaySvg: dots_1,
  iconSize: 60,
  overlaySize: 35,
  offset: const Offset(16,13),
);

Branch get settings => Branch(
  name: 'settings',
  url: '/settings',
  category: 'All',
  icon: tabler.Settings(),
  color: const Color(0xFFA8A8A8),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A5A5A), Color(0xFF3C3C3C)],
  ),
  hasImage: false,
  iconSvg: settings_1,
  overlaySvg: dots_1,
  iconSize: 55,
  overlaySize: 35,
  showOverlay: false,
  offset: const Offset(2,2),
);

Branch get profiles => Branch(
  name: 'profiles',
  url: '/profiles',
  category: 'Accounting',
  icon: tabler.UserUp(),
  color: const Color(0xFFDED7FF),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A5E8), Color(0xFFA87BC7)],
  ),
  hasImage: false,
  iconSvg: profile_1,
  overlaySvg: profile_2,
  iconSize: 55,
  overlaySize: 58,
  showOverlay: false,
  showIcon: true,
  offset: const Offset(2,2),
);
