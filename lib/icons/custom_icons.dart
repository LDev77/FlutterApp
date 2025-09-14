import 'package:flutter/widgets.dart';

/// Custom icons from IcoMoon font
class CustomIcons {
  CustomIcons._();

  static const _kFontFam = 'IcoMoon';
  static const String? _kFontPkg = null;

  // Coin icon mapped to Unicode coin character
  static const IconData coin = IconData(0x1FA99, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  // Add more icons here as needed
  // static const IconData anotherIcon = IconData(0xe901, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}