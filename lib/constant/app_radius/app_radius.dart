import 'package:flutter/cupertino.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;


  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(lg);
  static final BorderRadius radiusLg = BorderRadius.circular(xl);
  static final BorderRadius radiusXl = BorderRadius.circular(full);
  static final BorderRadius radiusFull = BorderRadius.circular(md);

  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius input = BorderRadius.circular(sm);
  static final BorderRadius bottomSheet = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
  static final BorderRadius chip = BorderRadius.circular(full);
}