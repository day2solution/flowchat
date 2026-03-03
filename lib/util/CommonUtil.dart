import 'dart:convert';
import 'dart:typed_data';
import 'package:flowchat/config/Constant.dart';
import 'package:flowchat/config/Logger.dart';
import 'package:flowchat/util/style.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

class CommonUtil {
  static double? screenWidth;
  static double? screenHeight;
  static MediaQueryData? _mediaQueryData;
  File? selectedVideo;
  // VideoPlayerController? _controller;

  // static DateTime intToDate(int number){
  //   return new DateTime.fromMicrosecondsSinceEpoch(number*1000);
  // }


  static DateTime stringToDate(String date) {
    return new DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").parse(date);
  }

  static getTimeStampToStringDate(int number) {
    var date = new DateTime.fromMicrosecondsSinceEpoch(number * 1000);
    return new DateFormat('dd MMM yyyy').format(date);
  }

  static getYYYYMMDDStringDate(String date) {
    debugPrint('date=$date');
    DateTime dateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").parse(date);
    DateFormat outputFormat = DateFormat('yyyy-MM-dd');
    String outputDate = outputFormat.format(dateTime);
    return outputDate;
  }

  static getYYYYMMMDDStringDate(String date) {
    DateTime dateTime = DateFormat("yyyy-MM-dd").parse(date);
    DateFormat outputFormat = new DateFormat('dd-MMM-yyyy');
    String outputDate = outputFormat.format(dateTime);
    return outputDate;
  }

  static getDDMMMYYYYStringDate(String date) {
    if (isBlank(date)) {
      return "-";
    }
    DateTime dateTime = DateFormat("yyyy-MM-dd").parse(date);
    DateFormat outputFormat = DateFormat('dd-MMM-yyyy');
    String outputDate = outputFormat.format(dateTime);
    return outputDate;
  }

  static getHHMMSSStringTime(String date) {
    if (isBlank(date)) {
      return "-";
    }
    DateTime dateTime = DateFormat("yyyy-MM-dd").parse(date);
    DateFormat outputFormat = DateFormat('HH:mm:ss a');
    String outputDate = outputFormat.format(dateTime);
    return outputDate;
  }

  static String getTextWithCheckBlank(String text) {
    if (isBlank(text)) {
      return "";
    }

    return text;
  }

  static String textCheckBlankReturnDash(String text) {
    if (isBlank(text)) {
      return "-";
    }

    return text;
  }


  static Widget showCircularProgressLoading(String msg, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          child: CircularProgressIndicator(
            // backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(
                CompanyStyle.primaryColor[900]!),
            strokeWidth: 3,
          ),
        ),
        !CommonUtil.isBlank(msg) ? Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Text(msg,
              style: TextStyle(fontSize: screenWidth! / 30,
                  color: CompanyStyle.primaryColor),
            )
          ],
        ) :
        Container(),
      ],
    );
  }

  static String convertToTitleCase(String text) {
    debugPrint('text to capitalize=$text');
    if (isBlank(text)) {
      return "-";
    } else {
      if (text.length <= 1) {
        return text.toUpperCase();
      }
    }
    text = text.trim().replaceAll(RegExp(' +'), ' ');
    final List<String> words = text.split(' ');
    final capitalizedWords = words.map((word) {
      final String firstLetter = word.substring(0, 1).toUpperCase();
      final String remainingLetters = word.substring(1).toLowerCase();
      return '$firstLetter$remainingLetters';
    });

    return capitalizedWords.join(' ');
  }

  static String convertToTitleCaseReturnDash(String text) {
    debugPrint('text to capitalize=$text');
    if (text == null) {
      return "-";
    }

    if (text.length <= 1) {
      return text.toUpperCase();
    }
    text = text.trim().replaceAll(RegExp(' +'), ' ');
    final List<String> words = text.split(' ');
    debugPrint('words=$words');
    final capitalizedWords = words.map((word) {
      final String firstLetter = word.substring(0, 1).toUpperCase();
      final String remainingLetters = word.substring(1).toLowerCase();
      return '$firstLetter$remainingLetters';
    });

    return capitalizedWords.join(' ');
  }

  // static Future<String> convertImgToBase64Str(XFile pfile) async{
  //   String base64Image="";
  //   File file=File (pfile.path);
  //   File futureFile= await testCompressAndGetFile(file);
  //   base64Image = base64Encode(futureFile.readAsBytesSync());
  //   return base64Image;
  // }
  // static Future<File> testCompressAndGetFile(File file) async {
  //   int imgQuality=100;
  //   double ogFileSize=file.lengthSync()/1024;
  //   debugPrint("image original size in KB="+ogFileSize.toString()+" KB");
  //
  //   if(ogFileSize>100 && ogFileSize<200){
  //     imgQuality=90;
  //   }
  //   if(ogFileSize>200 && ogFileSize<300){
  //     imgQuality=80;
  //   }
  //   if(ogFileSize>300 && ogFileSize<400){
  //     imgQuality=70;
  //   }
  //   if(ogFileSize>400){
  //     imgQuality=30;
  //   }
  //   ogFileSize=ogFileSize/1024;
  //   debugPrint("image original size in MB="+ogFileSize.toString()+" MB");
  //   debugPrint('imgQuality=$imgQuality');
  //   File compressedFile = await FlutterNativeImage.compressImage(file.path,
  //       quality: imgQuality, percentage: 100);
  //
  //   ogFileSize=compressedFile.lengthSync()/1024;
  //   debugPrint("image compressed size in KB="+ogFileSize.toString()+" KB");
  //   ogFileSize=ogFileSize/1024;
  //   debugPrint("image compressed size in MB="+ogFileSize.toString()+" MB");
  //   return compressedFile;
  // }
  static Widget getImageInDialogue(String base64String, BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    var image;
    if (base64String != null && base64String != "") {
      String finalImg = base64String.split(",")[1];
      image = Base64Decoder().convert(finalImg);
      return Container(
        alignment: Alignment.center,
        height: screenWidth!-40 ,
        width: screenWidth!-40,
        child: Image.memory(
          image,
          alignment: Alignment.center,
          repeat: ImageRepeat.noRepeat,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.fill,
        ),
      );
      // Image.memory(image, width: screenWidth/4, height: screenWidth/4,fit: BoxFit.contain,)

    } else {
      return Image.asset('assets/images/no_image.jpg', width: screenWidth! / 4,
        height: screenWidth! / 4,);
    }
  }
  static Widget getImage(String base64String, BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    var image;
    if (base64String != null && base64String != "") {
      String finalImg = base64String.split(",")[1];
      image = Base64Decoder().convert(finalImg);
      return Container(
        alignment: Alignment.center,
        height: screenWidth! / 4,
        width: screenWidth! / 4,
        child: Image.memory(
          image,
          alignment: Alignment.center,
          repeat: ImageRepeat.noRepeat,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.fill,
        ),
      );
      // Image.memory(image, width: screenWidth/4, height: screenWidth/4,fit: BoxFit.contain,)

    } else {
      return Image.asset('assets/images/no_image.jpg', width: screenWidth! / 4,
        height: screenWidth! / 4,);
    }
  }

  static Future<Widget> getImageXFile(XFile pickedFile,
      BuildContext context) async {
    // if (pickedFile != null) {
    File imageFile = File(pickedFile.path);
    List<int> imageBytes = await imageFile.readAsBytes(); // Convert to bytes
    String base64 = base64Encode(imageBytes); // Convert bytes to Base64
    return getImageFromBase64FillSize(base64, context);
    print("Base64 String: $base64"); // Log Base64 output
    // }
  }

  static Uint8List decodeBase64(String base64Str) {
    final pureBase64 = base64Str
        .split(',')
        .last;
    return base64Decode(pureBase64);
  }

  static Widget getImageFromBase64FillSize22222(Uint8List imageBytes,
      BuildContext context) {
    var image;
    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
    );
  }

  static Widget getImageFromStorage(String fileName) {
    // final appDir = await getApplicationDocumentsDirectory();
    return Image.file(
      File(fileName),
      height: 200,
      width: 200,
      fit: BoxFit.cover,
    );
    // return AssetImage(
    //   fileName,
    //   height: 200,
    //   width:200,
    //   fit: BoxFit.fill,
    // );
  }

  static Future<String> saveBase64Image(String base64String,
      String fileName) async {
    try {
      Logger.log("fileName=$fileName");

      // Decode Base64 String
      Uint8List bytes = base64Decode(base64String);

      // Get directory to save (App's documents directory)
      Directory dir = await getApplicationDocumentsDirectory();
      String filePath = '${dir.path}/$fileName';

      // Write bytes to file
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(bytes);

      Logger.log('Image saved at: $filePath');
      return filePath;
    } catch (e) {
      Logger.log('Error saving image: $e');
      return '';
    }
  }
  static Future<String> saveBase64video(String base64String,
      String fileName) async {
    try {
      // Decode Base64 String
      Uint8List bytes = base64Decode(base64String);

      // Get directory to save (App's documents directory)
      Directory dir = await getApplicationDocumentsDirectory();
      String filePath = '${dir.path}/$fileName';


      // Write bytes to file
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(bytes);

      Logger.log('video saved at: $filePath');
      return filePath;
    } catch (e) {
      Logger.log('Error saving video: $e');
      return '';
    }
  }

  static Widget getImageFromBase64FillSize(String base64String,
      BuildContext context) {
    var image;
    if (base64String != null && base64String != "") {
      String finalImg = base64String.split(",")[1];
      image = Base64Decoder().convert(finalImg);
      return Image.memory(
        image,
        alignment: Alignment.center,
        repeat: ImageRepeat.noRepeat,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        'assets/no_image.jpg',
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.fill,
      );
    }
  }

  static Widget getImageFromBase64CustSize(String base64String,
      double screenWidth, double screenHeight) {
    var image;
    if (base64String != null && base64String != "") {
      String finalImg = base64String.split(",")[1];
      image = Base64Decoder().convert(finalImg);
      return Image.memory(
        image,
        alignment: Alignment.center,
        repeat: ImageRepeat.noRepeat,
        height: screenHeight,
        width: screenWidth,
        fit: BoxFit.fill,
      );
    } else {
      return Image.asset(
        'assets/images/no_image.jpg',
        height: screenHeight,
        width: screenWidth,
        fit: BoxFit.fill,
      );
    }
  }

  static bool isValidEmail(String input) {
    debugPrint("validating");
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(input);
  }

  static bool isEqualBothString(String input1, String input2) {
    debugPrint('input1=$input1 input2=$input2');
    if (!isBlank(input1) && !isBlank(input2)) {
      if (input1.toUpperCase().trim() == input2.toUpperCase().trim()) {
        debugPrint('true found');
        return true;
      } else {
        return false;
      }
    }
    else {
      return false;
    }
  }

  static Widget getImgFromBase64OriginalSizeNoSplit(String base64String,
      BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    var image;
    if (base64String != null && base64String != "") {
      image = Base64Decoder().convert(base64String);

      return Image.memory(
        image,
        alignment: Alignment.center,
        repeat: ImageRepeat.noRepeat,

        // fit: BoxFit.fill,
      );
      // Image.memory(image, width: screenWidth/4, height: screenWidth/4,fit: BoxFit.contain,)

    } else {
      return Image.asset('assets/images/no_image.jpg', width: screenWidth! / 4,
        height: screenWidth! / 4,);
    }
  }

  static Widget getImgFromBase64FillSizeNoSplit(String base64String,
      BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    var image;
    if (base64String != null && base64String != "") {
      image = Base64Decoder().convert(base64String);

      return Image.memory(
        image,
        alignment: Alignment.center,
        repeat: ImageRepeat.noRepeat,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.fill,
      );
      // Image.memory(image, width: screenWidth/4, height: screenWidth/4,fit: BoxFit.contain,)

    } else {
      return Image.asset('assets/images/no_image.jpg', width: screenWidth! / 4,
        height: screenWidth! / 4,);
    }
  }

  static Widget getFileBasedOnFileType(String fileName,String fileType){
    if(!isBlank(fileType) || !isBlank(fileName)){
      if(isEqualBothString(fileType,Constant.FILE_TYPE_IMAGE)){
        return Container(
          child: CommonUtil.getImageFromStorage(fileName),
        );
      }else if(isEqualBothString(fileType,Constant.FILE_TYPE_VIDEO)){
        return Container(
          height: 200,
          width: 200,
          child: IconButton(icon: Icon(
            Icons.video_call,
            size: 30,
          ),
            onPressed: () {
              // _controller!.seekTo(Duration(seconds: _start.toInt()));
              // _controller!.play();
              // Navigator.push(
              //   context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoPath: fileName,),),
              // );
              // VideoPlayerScreen(videoPath: fileName,);
            },),
        );
      }else if(isEqualBothString(fileType,Constant.FILE_TYPE_TEXT)){
        return Container(
          child: Text(fileName),
        );
      }else{
        return Container(
          child: Text("unknown data"),
        );
      }

    }else{
      return Container(
          child: Text("media not found"),
      );
    }

  }
  static Widget getImageFromBase64OriginalSize(String base64String,
      BuildContext context) {
    debugPrint('base64String in OG=$base64String');
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    debugPrint('screenHeight in OG=$screenHeight');
    var image;
    if (base64String != null && base64String != "") {
      List<String> list = base64String.split(",");
      debugPrint(list.toString());
      String finalImg = "";
      if (list[0].startsWith("data:image/jpeg;")) {
        finalImg = list[1];
      } else {
        finalImg = list[0];
      }

      image = Base64Decoder().convert(finalImg);

      return Image.memory(
        image,
        alignment: Alignment.center,
        repeat: ImageRepeat.noRepeat,

        // fit: BoxFit.fill,
      );
      // Image.memory(image, width: screenWidth/4, height: screenWidth/4,fit: BoxFit.contain,)

    } else {
      return Image.asset('assets/images/no_image.jpg', width: screenWidth! / 4,
        height: screenWidth! / 4,);
    }
  }

  // static Widget getEmptyMsg(String msg,BuildContext context){
  //   _mediaQueryData = MediaQuery.of(context);
  //   screenWidth = _mediaQueryData.size.width;
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const SizedBox(height: 5,),
  //       SvgPicture.asset('assets/svg/empty_box.svg',width: screenWidth/4,height: screenWidth/4),
  //       const SizedBox(height: 5,),
  //       Text(msg,style: const TextStyle(color: Colors.grey),),
  //     ],);
  // }

  // static Widget getExcelSvgImg(String msg,BuildContext context){
  //   _mediaQueryData = MediaQuery.of(context);
  //   screenWidth = _mediaQueryData!.size.width;
  //
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       SvgPicture.asset('assets/svg/excel_img.svg',width: screenWidth/4,height: screenWidth/4),
  //     ],);
  // }

  // static Widget getSvgImg(String type,BuildContext context){
  //   _mediaQueryData = MediaQuery.of(context);
  //   screenWidth = _mediaQueryData!.size.width;
  //   String imageName="default.svg";
  //   if(!isBlank(type) && type.toUpperCase().contains('CCTV')){
  //     imageName="cctv.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('FRIDGE') || type.toUpperCase().contains('REFRIGERATOR'))) {
  //     imageName = "fridge.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('LCD') || type.toUpperCase().contains('LED'))){
  //     imageName="lcd_led.svg";
  //   }
  //   if(!isBlank(type) && type.toUpperCase().contains('PLUMBER')){
  //     imageName="plumber.svg";
  //   }
  //   if(!isBlank(type) && type.toUpperCase().contains('MICROWAVE')){
  //     imageName="microwave.svg";
  //   }
  //   if(!isBlank(type) && type.toUpperCase().contains('AIR CONDITIONING')){
  //     imageName="air-conditioner.svg";
  //   }
  //   if(!isBlank(type) && type.toUpperCase().contains('WASHING MACHINE')){
  //     imageName="washing-machine.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('LAPTOP') ||type.toUpperCase().contains('COMPUTER'))){
  //     imageName="computer_repair.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('DISHWASHER'))){
  //     imageName="dishwasher.svg";
  //   }
  //
  //   // if(!isBlank(type) && (type.toUpperCase().contains('GEYSERS'))){
  //   //   imageName="computer_repair.svg";
  //   // }
  //   if(!isBlank(type) && (type.toUpperCase().contains('ELECTRICIAN'))){
  //     imageName="electrician.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('WATER PURIFIER'))){
  //     imageName="water_filter.svg";
  //   }
  //   if(!isBlank(type) && (type.toUpperCase().contains('DRYER'))){
  //     imageName="equipment_dryer.svg";
  //   }
  //   // /computer_repair.svg
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       SvgPicture.asset('assets/svg/'+imageName,width: screenWidth!/4,height: screenWidth!/4),
  //     ],);
  // }
  // static Future<String> getVersionCode() async{
  //   String projectVersion="";
  //   try {
  //     PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //     debugPrint('packageName=${packageInfo.packageName}');
  //     debugPrint('buildNumber=${packageInfo.buildNumber}');
  //     debugPrint('projectVersion=${packageInfo.version}');
  //     projectVersion=await packageInfo.version;
  //     debugPrint('appName=${packageInfo.appName}');
  //   } on PlatformException {
  //     projectVersion = 'Failed to get build number.';
  //   }
  //   return projectVersion;
  // }

  // static Future<String> getProjectCode() async{
  //   String buildNumber="2052";
  //   try {
  //     PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //     // projectCode = await GetVersion.projectCode;
  //     buildNumber = packageInfo.buildNumber;
  //     debugPrint('buildNumber=${buildNumber}');
  //
  //   } on PlatformException {
  //     debugPrint('Failed to get build number.');
  //     buildNumber = '2052';
  //   }
  //   return buildNumber;
  // }
  // static bool isNumericOnly(String text){
  //   if(isBlank(text)) {
  //     return false;
  //   }
  //   return double.tryParse(text)!=null;
  // }
  // static Widget showLoading(String msg,BuildContext context){
  //   _mediaQueryData = MediaQuery.of(context);
  //   screenWidth = _mediaQueryData!.size.width;
  //   if(isBlank(msg)){
  //     msg="Loading Details..";
  //   }
  //   return Container(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: <Widget>[
  //         SizedBox(
  //           child: BarProgressIndicator(
  //             numberOfBars: 4,
  //             color: CompanyStyle.primaryColor,
  //             fontSize: 5.0,
  //             barSpacing: 2.0,
  //             beginTweenValue: 5.0,
  //             endTweenValue: 13.0,
  //             milliseconds: 200,
  //           ),
  //           height:screenWidth!/ 7,
  //           width: screenWidth!/ 7,
  //         ),
  //         SizedBox(height: 10,),
  //         Text(msg,style: TextStyle(fontSize: screenWidth/20),),
  //       ],
  //     ),
  //   );
  // }
  static Widget showLinearProgressLoading(String msg, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 15, bottom: 15),
      width: screenWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            child: LinearProgressIndicator(
              backgroundColor: Colors.white,
              valueColor:
              AlwaysStoppedAnimation<Color>(CompanyStyle.primaryColor[900]!),
            ),
            height: 1,
            width: screenWidth! / 2,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            msg != null ? msg : 'Loading...',
            style: TextStyle(fontSize: screenWidth! / 20),
          ),
        ],
      ),
    );
  }

  static bool isBlank(String str) {
    debugPrint("str=$str");
    if (str == null || str == "" || str.isEmpty) {
      return true;
    }
    return false;
  }

  static bool isAlphaNumericOnly(String text) {
    debugPrint("text=$text");
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(text);
  }

  // static Future<bool> createFolderInAppDocDir(String fileName,String base64ImgFile,String path,String accountId,String extension) async {
  //   //Get this App Document Directory
  //   bool saveStatus=true;
  //   String finalPath="letstalk";
  //   if(!isBlank(path)){
  //     finalPath=finalPath+'/$path';
  //   }
  //   if(isBlank(extension)){
  //     extension=".jpg";
  //   }
  //   if(!isBlank(accountId)){
  //     finalPath=finalPath+'/$accountId';
  //   }
  //   debugPrint('createFolderInAppDocDir called='+finalPath);
  //   final List<Directory> result = await getExternalStorageDirectories();
  //
  //   debugPrint('result length='+result.length.toString());
  //   debugPrint('final path='+result[0].path);
  //
  //   Directory _appDocDirFolder =  Directory('${result[0].path}/$finalPath/');
  //   Uint8List bytes = base64.decode(base64ImgFile.split(",")[1]);
  //   if(await _appDocDirFolder.exists()){
  //     File file = File("${_appDocDirFolder.path}/${fileName+extension}");
  //     await file.writeAsBytes(bytes);
  //   }else{
  //     Directory _appDocDirNewFolder=await _appDocDirFolder.create(recursive: true);
  //     File file = File("${_appDocDirNewFolder.path}/${fileName+extension}");
  //     await file.writeAsBytes(bytes);
  //   }
  //
  //   return saveStatus;
  // }

  // static Future<String> createFolderInAppDocDirStr(String fileName,String base64ImgFile,String path,String accountId,String extension) async {
  //   //Get this App Document Directory
  //   // bool saveStatus=true;
  //   String finalPath=Constant.BASE_FOLDER;
  //   if(!isBlank(path)){
  //     finalPath=finalPath+'/$path';
  //   }
  //   if(isBlank(extension)){
  //     extension=".jpg";
  //   }
  //   if(!isBlank(accountId)){
  //     finalPath=finalPath+'/$accountId';
  //   }
  //   debugPrint('createFolderInAppDocDir called='+finalPath);
  //   final List<Directory> result = await getExternalStorageDirectories();
  //
  //   debugPrint('result length='+result.length.toString());
  //   debugPrint('final path='+result[0].path);
  //
  //   Directory _appDocDirFolder =  Directory('${result[0].path}/$finalPath');
  //   Uint8List bytes = base64.decode(base64ImgFile.split(",")[1]);
  //
  //   if(await _appDocDirFolder.exists()){
  //     File file = File("${_appDocDirFolder.path}/${fileName+extension}");
  //     await file.writeAsBytes(bytes);
  //     debugPrint('_appDocDirFolder path='+_appDocDirFolder.path);
  //     debugPrint('_appDocDirFolder path='+file.path);
  //     return file.path;
  //   }else{
  //     Directory _appDocDirNewFolder=await _appDocDirFolder.create(recursive: true);
  //     File file = File("${_appDocDirNewFolder.path}/${fileName+extension}");
  //     await file.writeAsBytes(bytes);
  //     debugPrint('_appDocDirNewFolder path='+_appDocDirNewFolder.path);
  //     return file.path;
  //   }
  // }
  // Future<String> getLoggedDetail() async {
  //   // final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  //   // final SharedPreferences prefs = await _prefs;
  //   return prefs.getString("accountNo")!;
  // }

  static String convertToIndianCurrency(double amount) {
    debugPrint("amount=${amount}");
    if (amount == null) {
      amount = 0;
    }
    NumberFormat format = NumberFormat.currency(locale: 'HI', symbol: '₹ ');
    return format.format(amount);
  }

  // static Future<File?> compressImage1(XFile xfile) async {
  //   // final dir = await getTemporaryDirectory();
  //   final targetPath = '${xfile.path}/temp_compressed.jpg';
  //   File file=File(xfile.path);
  //   Logger.log("file.absolute.path="+file.absolute.path);
  //   var result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     targetPath,
  //     quality: 70, // adjust quality
  //     minWidth: 800,
  //     minHeight: 600,
  //   );
  //   print('Compressed result: ${await result}');
  //   print('Original Size: ${await xfile.length()} bytes');
  //   print('Compressed Size: ${await result?.length()} bytes');
  //
  //   return File(await result!.path);
  // }

  static Future<File> compressImage(File file) async {
    // Decode image
    img.Image? image = img.decodeImage(await file.readAsBytes());
    if (image == null) throw Exception("Cannot decode image");
    img.Image resized = img.copyResize(image, width: 200);

    // Compress & Save
    final compressedBytes = img.encodeJpg(resized, quality: 20);
    final dir = await getTemporaryDirectory();
    // Logger.log("dir="+dir.path);
    final compressedFile = File('${dir.path}/compressed.jpg')
      ..writeAsBytesSync(compressedBytes);

    return compressedFile;
  }
  static bool isBase64(String str) {
    // A simple regex to check for Base64 pattern. It's not foolproof but covers most cases.
    // It looks for valid Base64 characters and padding.
  bool isImage=str.startsWith("data:image/jpeg;base64");
    debugPrint("isImage=$isImage");
    debugPrint("str="+str);
    if (!str.startsWith("data:image/jpeg;base64")) return false;
    return true;
  }
Widget getTextField(TextEditingController _contactController,Color color,String hintText){
  return TextField(
    controller: _contactController,
    keyboardType: TextInputType.phone,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      prefixIcon: Icon(Icons.phone_android_rounded, color: color),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    ),
  );
}
}

