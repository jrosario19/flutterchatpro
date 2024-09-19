import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/models/user_model.dart';
import 'package:flutter_chat_pro/utilities/assets_manager.dart';
import 'package:flutter_chat_pro/widgets/display_user_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

import '../constants.dart';
import '../providers/authentication_provider.dart';
import '../utilities/global_methods.dart';
import '../widgets/app_bar_back_button.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  final TextEditingController nameController = TextEditingController();

  String userImage = '';
  File? finalFileImage;
  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (error) {
          showSnackBar(context, error);
        });
    //crop image
    if (finalFileImage != null) {
      cropImage(finalFileImage!.path);
    }
  }

  void cropImage(String filePath) async {
    if (filePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: filePath,
          maxHeight: 800,
          maxWidth: 800,
          compressQuality: 90);
      //popTheDialog();
      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      } else {
        //popTheDialog();
      }
    }
  }

  popTheDialog() {
    Navigator.of(context).pop();
  }

  void showDialogForCameraSelection() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Image'),
            content: Text('Select image from gallery or camera'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    selectImage(false);
                  },
                  child: Text('Gallery')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    selectImage(true);
                  },
                  child: Text('Camera'))
            ],
          );
        });
  }

  @override
  void dispose() {
    btnController.stop();
    nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text('User Information'),
          leading: AppBarBackButton(
            onPressed: () => Navigator.pop(context),
          )),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(children: [
              DisplayUserImage(
                  finalFileImage: finalFileImage,
                  radius: 60,
                  onPressed: () {
                    showDialogForCameraSelection();
                  }),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    labelText: 'Enter your name'),
              ),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                child: RoundedLoadingButton(
                  controller: btnController,
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        nameController.text.length < 3) {
                      showSnackBar(context, 'Plase enter your name');
                      btnController.reset();
                      return;
                    }
                    //save user data to firestore
                    saveUserDataToFireStore();
                  },
                  successIcon: Icons.check,
                  successColor: Colors.green,
                  errorColor: Colors.red,
                  color: Theme.of(context).primaryColor,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }

  void saveUserDataToFireStore() async {
    final authProvider = context.read<AuthenticationProvider>();
    UserModel userModel = UserModel(
        uid: authProvider.uid!,
        name: nameController.text.trim(),
        phoneNumber: authProvider.phoneNumber!,
        image: '',
        token: '',
        aboutMe: 'Hey there, I\'m using Flutter Chat Pro',
        lastSeen: '',
        createdAt: '',
        isOnline: true,
        friendRequestsUIDs: [],
        sentFriendRequestsUIDs: [],
        friendsUIDs: []);
    authProvider.saveUserDataToFireStore(
        userModel: userModel,
        fileImage: finalFileImage,
        onSucess: () async {
          btnController.success();
          await authProvider.saveUserDataToShredPreferences();

          navigateToHomeScreen();
        },
        onFail: () async {
          btnController.error();
          showSnackBar(context, 'Failed to save user data');
          await Future.delayed(Duration(seconds: 1));
          btnController.reset();
        });
  }

  void navigateToHomeScreen() {
    Navigator.of(context).pushReplacementNamed(Constants.homeScreen);
  }
}
