import 'dart:convert';
import 'dart:typed_data';
import 'package:flowchat/config/Constant.dart';
import 'package:flowchat/config/Logger.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CommonUtil {

  // --- Validation Utilities ---
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty || text == "null";
  }

  static bool isBase64(String text) {
    return text.startsWith(Constant.IMAGE_PREFIX) || text.length > 100;
  }

  // --- Date & Time Utilities ---
  static String formatTimestamp(int timestamp) {
    if (timestamp == 0) return "";
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  static String getDDMMMYYYY(String dateStr) {
    if (isBlank(dateStr)) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // --- String Utilities ---
  static String toTitleCase(String? text) {
    if (isBlank(text)) return "-";
    return text!.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // --- Image Processing & UI ---

  /// Optimized Base64 Image Widget
  static Widget getImage(String base64String, BuildContext context, {double? size, BoxFit fit = BoxFit.cover}) {
    if (isBlank(base64String)) {
      return Image.asset('assets/images/no_image.jpg', width: size, height: size, fit: fit);
    }

    try {
      // Remove data:image/... base64, prefix if present
      final String cleanBase64 = base64String.contains(",")
          ? base64String.split(",")[1]
          : base64String.replaceAll(Constant.IMAGE_PREFIX, "");

      Uint8List bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/no_image.jpg', width: size, height: size),
      );
    } catch (e) {
      Logger.log("CommonUtil", "Error decoding image: $e");
      return Image.asset('assets/images/no_image.jpg', width: size, height: size);
    }
  }

  /// High-Res Image for Dialogues
  static Widget getImageInDialogue(String base64String, BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return getImage(base64String, context, size: width - 40, fit: BoxFit.contain);
  }

  /// Compresses image for network efficiency
  static Future<File> compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    Uint8List bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    // Resize the image to a maximum width of 800px while maintaining aspect ratio
    img.Image resized = img.copyResize(image, width: 200);

    File compressedFile = File('$path/img_${DateTime.now().millisecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(img.encodeJpg(resized, quality: 20));

    return compressedFile;
  }

  // --- Storage Utilities ---
  static Future<String> saveBase64ToFile(String base64String, String fileName) async {
    if (isBlank(base64String)) return "";
    try {
      final String cleanBase64 = base64String.contains(",") ? base64String.split(",")[1] : base64String;
      Uint8List bytes = base64Decode(cleanBase64);

      Directory dir = await getApplicationDocumentsDirectory();
      File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      Logger.log("CommonUtil", "Error saving file: $e");
      return "";
    }
  }

  // --- Feedback Utilities ---
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Widget loadingIndicator({String? msg}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          if (!isBlank(msg)) ...[
            const SizedBox(height: 12),
            Text(msg!, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ]
        ],
      ),
    );
  }
}
