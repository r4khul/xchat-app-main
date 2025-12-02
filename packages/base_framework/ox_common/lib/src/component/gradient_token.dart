import 'package:flutter/material.dart';

class CLGradient {
  CLGradient._();

  static const Alignment _defaultBegin = Alignment.topCenter;
  static const Alignment _defaultEnd = Alignment.bottomCenter;

  static const Gradient gradeGrey = LinearGradient(
    colors: [
      Color(0xffbdc3c7),
      Color(0xff2c3e50),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient piggyPink = LinearGradient(
    colors: [
      Color(0xffefcdd1),
      Color(0xffde8c97),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient coolBlues = LinearGradient(
    colors: [
      Color(0xff7de5ff),
      Color(0xff2193b0),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient burningOrange = LinearGradient(
    colors: [
      Color(0xffff98ba),
      Color(0xffef3b1b),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient quepal = LinearGradient(
    colors: [
      Color(0xff58ff9d),
      Color(0xff11998e),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient amin = LinearGradient(
    colors: [
      Color(0xffde7dff),
      Color(0xff6a20ff),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient sunkist = LinearGradient(
    colors: [
      Color(0xfffceabb),
      Color(0xfff8b500),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  static const Gradient copper = LinearGradient(
    colors: [
      Color(0xffe7b8b1),
      Color(0xff94716b),
    ],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// All default gradient presets
  static const List<Gradient> defaults = [
    gradeGrey,
    piggyPink,
    coolBlues,
    burningOrange,
    quepal,
    amin,
    sunkist,
    copper,
  ];
}