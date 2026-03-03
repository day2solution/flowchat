import 'package:flutter/material.dart';
class CompanyStyle {
  CompanyStyle._(); // this basically makes it so you can instantiate this class

  static const MaterialColor primaryColor = MaterialColor(
    _companyPrimaryColor,
    <int, Color>{
      10: Color(0xffb38306),
      50: Color(0xFFfab702),
      100: Color(0xffeaac02),
      200: Color(0xfffcc226),
      300: Color(0xfffcc226),
      400: Color(0xfffdc52e),
      500: Color(_companyPrimaryColor),
      600: Color(0xfffdc838),
      700: Color(0xFFF8C740),
      800: Color(0xFFFACB48),
      900: Color(0xFFFACD50),
      1000: Color(0xFFF8CD57),
      1001: Color(0xFFFCD15E),
      1002: Color(0xFFFDD569),
      1003: Color(0xFFFFDA76),
      1004: Color(0xFFF6E7BF),
      1005: Color(0xFF20427D),
    },
  );
  static const MaterialColor ratingColor = MaterialColor(
    _ratingColor,
    <int, Color>{
      0: Color(0xFFFF0000),
      1: Color(0xFFFF0000),
      2: Color(0xFFFF0000),
      3: Color(0xFFFFBE00),
      4: Color(0xFF06FF00),
      5: Color(0xFF06FF00),
    },
  );
  static const MaterialColor txtPrimaryColor = MaterialColor(
    _defaultTxtColor,
    <int, Color>{
      1: Color(0xffd4d5d5),
      5: Color(0xffb9bbbe),
      10: Color(0xffa7a9af),
      20: Color(0xFF92949c),

    },
  );
  static const MaterialColor cardPrimaryColor = MaterialColor(
    _cardBackgroundColor,
    <int, Color>{
      50: Color(0xFFf4f6fa),

    },
  );
  static const int _companyPrimaryColor = 0xFFfab702;
  static const int _ratingColor = 0xFFFF0000;
  static const int _defaultTxtColor=0xFF92949c;
  static const int _cardBackgroundColor=0xFFf4f6fa;
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
    return const SizedBox(
      height: 10.0,
    );
  }

  static getGap5(){
    return SizedBox(
      height: 5.0,
    );
  }
  static getCustomGap(double value){
    return SizedBox(
      height: value,
    );
  }
  static getGap2(){
    return const SizedBox(
      height: 2.0,
    );
  }
  static getInputElementGap(){
    return const SizedBox(
      height: 20.0,
    );
  }
  static TextStyle getCompanyTxtStyle(double fontsize){
    return TextStyle(fontSize:fontsize ,color: CompanyStyle.txtPrimaryColor,);
  }
  // static getButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side:  const BorderSide(width: 1,color: Colors.yellow),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:CompanyStyle.primaryColor,
  //   );
  // }
  // static getRedButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side:  const BorderSide(width: 1,color: Colors.yellow),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:Colors.red,
  //   );
  // }
  // static getGreenButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side:  const BorderSide(width: 1,color: Colors.yellow),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:Colors.green,
  //   );
  // }
  // static getButtonStyleNoBorder(){
  //   return ElevatedButton.styleFrom(
  //     side: const BorderSide(width: 0,color: CompanyStyle.primaryColor),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(50.0),
  //     ),
  //     primary:CompanyStyle.primaryColor,
  //
  //   );
  //
  // }
  // static getImageUploadButtonStyle(){
  //   return ElevatedButton.styleFrom(
  //     side: BorderSide(width: 1,color: CompanyStyle.primaryColor),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(2.0),
  //
  //
  //     ),
  //     primary:CompanyStyle.primaryColor,
  //
  //   );
  //
  // }

}