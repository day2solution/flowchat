import 'package:flutter/material.dart';
class AppStyle {
  AppStyle._(); // this basically makes it so you can instantiate this class
  static const MaterialColor secondaryColor = MaterialColor(
    _companySecondaryColor,
    <int, Color>{
      500: Color(_companySecondaryColor),
    },
  );
  static const MaterialColor primaryColor = MaterialColor(
    _companyPrimaryColor,
    <int, Color>{
      40: Color(0xfffaf7f4),
      50:  Color(0xfffff0f0),
      100: Color(0xffffdede),
      200: Color(0xffffc2c2),
      300: Color(0xffff9696),
      400: Color(0xffff6b6b), // Main Brand Color
      500: Color(_companyPrimaryColor),
      600: Color(0xfff24444),
      700: Color(0xffcc2b2b),
      800: Color(0xffa82525),
      900: Color(0xff8a2323),
      1000: Color(0xff6a250d),
      1001: Color(0xff6c240b),
      1002: Color(0xff682209),
      1003: Color(0xff652008),
    },
  );
  static const int _companyPrimaryColor = 0xFFFF7F50;
  static const int _companySecondaryColor = 0xFF6C63FF;
  static getGap20(){
    return SizedBox(
      height: 20.0,
    );
  }
  static getGap15(){
    return SizedBox(
      height: 15.0,
    );
  }

  static getGap25(){
    return SizedBox(
      height: 25.0,
    );
  }
  static getGap30(){
    return SizedBox(
      height: 30.0,
    );
  }
  static getGap35(){
    return SizedBox(
      height: 35.0,
    );
  }

  static getGap40(){
    return SizedBox(
      height: 40.0,
    );
  }

  static getGap45(){
    return SizedBox(
      height: 45.0,
    );
  }
  static getGap50(){
    return SizedBox(
      height: 50.0,
    );
  }

  static getGap10(){
    return SizedBox(
      height: 10.0,
    );
  }

  static getGap5(){
    return SizedBox(
      height: 5.0,
    );
  }
  static getGap2(){
    return SizedBox(
      height: 2.0,
    );
  }
  static getInputElementGap(){
    return SizedBox(
      height: 20.0,
    );
  }
  static Widget verticalGap([double height = 20.0]) {
    return SizedBox(height: height);
  }

  static Widget horizontalGap([double width = 20.0]) {
    return SizedBox(width: width);
  }
  // static getButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side: BorderSide(width: 1,color: AppStyle.primaryColor[700]),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:AppStyle.primaryColor,
  //   );
  // }
  // static getButtonStyleNoBorder(){
  //   return ElevatedButton.styleFrom(
  //     side: BorderSide(width: 0,color: AppStyle.primaryColor),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:AppStyle.primaryColor,
  //
  //   );
  //
  // }
  // static getImageUploadButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side: BorderSide(width: 1,color: AppStyle.primaryColor[700]),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(2.0),
  //
  //
  //     ),
  //     primary:AppStyle.primaryColor,
  //
  //   );
  //
  // }

}