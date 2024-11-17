import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/utilities/assets_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget userImageWidget(
    {required String imageUrl,
    required double radiis,
    required Function() onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: CircleAvatar(
        radius: radiis,
        backgroundColor: Colors.grey[300],
        backgroundImage: imageUrl.isNotEmpty
            ? CachedNetworkImageProvider(imageUrl)
            : AssetImage(AssetsManager.userImage) as ImageProvider),
  );
}

//pick image from gallery or camera
Future<File?> pickImage(
    {required bool fromCamera, required Function(String) onFail}) async {
  File? image;
  if (fromCamera) {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        image = File(pickedFile.path);
      } else {
        onFail('No image selected');
      }
    } catch (error) {
      onFail(error.toString());
    }
  } else {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        image = File(pickedFile.path);
      } else {
        onFail('No image selected');
      }
    } catch (error) {
      onFail(error.toString());
    }
  }
  return image;
}

Center buildDateTime(groupedByValue) {
  return Center(
    child: Card(
      elevation: 2,
      child: Padding(
          padding: EdgeInsets.all(8.0),
          child:
              Text(formatDate(groupedByValue.timeSent, [M, ' ', dd, ',', yyyy]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                  ))),
    ),
  );
}
