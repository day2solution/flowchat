import 'package:flutter/cupertino.dart';

class ScreenUtil {
  double getAdaptiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;
    // 360 is the standard design width
    return (width / 360) * size;
  }
}
