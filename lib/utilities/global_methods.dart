import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showSnackBar(BuildContext context, String message){
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message))
  );
}

//pick image from gallery or camera
Future<File?> pickImage({required bool fromCamera, required Function(String) onFail}) async {
  File? image;
  if(fromCamera){
    try{
     final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
     if(pickedFile != null){
       image = File(pickedFile.path);
     }else{
      onFail('No image selected');
     }
    }catch(error){

      onFail(error.toString());
    }
  }else{
    try{
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
          if(pickedFile != null){
              image = File(pickedFile.path);
          }else{
            onFail('No image selected');
          }
        }catch(error){
          onFail(error.toString());
        }
  }
  return image;
}